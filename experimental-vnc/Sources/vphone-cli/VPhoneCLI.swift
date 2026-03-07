import AppKit
import ArgumentParser
import Foundation
import Virtualization

@main
struct VPhoneCLI: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "vphone-cli",
        abstract: "Boot a virtual iPhone (PV=3)",
        discussion: """
        Creates a Virtualization.framework VM with platform version 3 (vphone)
        and boots it into DFU mode for firmware loading via irecovery.

        Requires:
          - macOS 15+ (Sequoia or later)
          - SIP/AMFI disabled
          - Signed with vphone entitlements (done automatically by wrapper script)

        Example:
          vphone-cli --rom firmware/rom.bin --disk firmware/disk.img
        """,
    )

    @Option(help: "Path to the AVPBooter / ROM binary")
    var rom: String

    @Option(help: "Path to the disk image")
    var disk: String

    @Option(help: "Path to NVRAM storage (created/overwritten)")
    var nvram: String = "nvram.bin"

    @Option(help: "Number of CPU cores")
    var cpu: Int = 4

    @Option(help: "Memory size in MB")
    var memory: Int = 4096

    @Option(help: "Path to write serial console log file")
    var serialLog: String? = nil

    @Flag(help: "Stop VM on guest panic")
    var stopOnPanic: Bool = false

    @Flag(help: "Stop VM on fatal error")
    var stopOnFatalError: Bool = false

    @Flag(help: "Skip SEP coprocessor setup")
    var skipSep: Bool = false

    @Option(help: "Path to SEP storage file (created if missing)")
    var sepStorage: String? = nil

    @Option(help: "Path to SEP ROM binary")
    var sepRom: String? = nil

    @Flag(help: "Boot into DFU mode")
    var dfu: Bool = false

    @Flag(help: "Run without GUI (headless)")
    var noGraphics: Bool = false

    @Flag(
        help: ArgumentHelp(
            "Use Virtualization.framework built-in VNC server (experimental).",
            discussion: """
            Starts a private _VZVNCServer on a random local port and prints the URL.
            Useful when the default viewer path is slow or keyboard input is unreliable.
            """))
    var vncExperimental: Bool = false

    mutating func validate() throws {
        if vncExperimental && noGraphics {
            throw ValidationError("--vnc-experimental and --no-graphics are mutually exclusive")
        }
    }

    @MainActor
    mutating func run() async throws {
        let romURL = URL(fileURLWithPath: rom)
        guard FileManager.default.fileExists(atPath: romURL.path) else {
            throw VPhoneError.romNotFound(rom)
        }

        let diskURL = URL(fileURLWithPath: disk)
        let nvramURL = URL(fileURLWithPath: nvram)

        print("=== vphone-cli ===")
        print("ROM   : \(rom)")
        print("Disk  : \(disk)")
        print("NVRAM : \(nvram)")
        print("CPU   : \(cpu)")
        print("Memory: \(memory) MB")
        let sepStorageURL = sepStorage.map { URL(fileURLWithPath: $0) }
        let sepRomURL = sepRom.map { URL(fileURLWithPath: $0) }

        print("SEP   : \(skipSep ? "skipped" : "enabled")")
        if !skipSep {
            print("  storage: \(sepStorage ?? "(auto)")")
            if let r = sepRom { print("  rom    : \(r)") }
        }
        print("")

        let options = VPhoneVM.Options(
            romURL: romURL,
            nvramURL: nvramURL,
            diskURL: diskURL,
            cpuCount: cpu,
            memorySize: UInt64(memory) * 1024 * 1024,
            skipSEP: skipSep,
            sepStorageURL: sepStorageURL,
            sepRomURL: sepRomURL,
            serialLogPath: serialLog,
            stopOnPanic: stopOnPanic,
            stopOnFatalError: stopOnFatalError,
        )

        let vm = try VPhoneVM(options: options)

        // Handle Ctrl+C
        signal(SIGINT, SIG_IGN)
        let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT)
        sigintSrc.setEventHandler {
            print("\n[vphone] SIGINT — shutting down")
            vm.stopConsoleCapture()
            Foundation.exit(0)
        }
        sigintSrc.activate()

        // Start VM
        try await vm.start(forceDFU: dfu, stopOnPanic: stopOnPanic, stopOnFatalError: stopOnFatalError)

        if vncExperimental {
            NSApplication.shared.setActivationPolicy(.prohibited)
            let vnc = try VPhoneVNC(virtualMachine: vm.virtualMachine)
            let vncURL = try await vnc.waitForURL()
            print("[vphone] VNC password : \(vnc.password)")
            print("[vphone] VNC URL      : \(vncURL)")
            NSWorkspace.shared.open(vncURL)
            await vm.waitUntilStopped()
            vnc.stop()
        } else if noGraphics {
            // Headless: just wait
            NSApplication.shared.setActivationPolicy(.prohibited)
            await vm.waitUntilStopped()
        } else {
            // GUI: show VM window with touch support
            let windowController = VPhoneWindowController()
            windowController.showWindow(for: vm.virtualMachine)
            await vm.waitUntilStopped()
        }
    }
}
