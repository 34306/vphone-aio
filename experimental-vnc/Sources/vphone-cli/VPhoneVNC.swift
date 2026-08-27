import AppKit
import Foundation
import VPhoneObjC
import Virtualization

class VPhoneVNC {
    private let vncServer: AnyObject
    let password: String
    let port: UInt16

    init(virtualMachine: VZVirtualMachine) throws {
        let env = ProcessInfo.processInfo.environment
        password = env["VPHONE_VNC_PASSWORD"] ?? "alpine"
        port = UInt16(env["VPHONE_VNC_PORT"] ?? "") ?? 5901

        guard let server = VPhoneCreateVNCServer(virtualMachine, password, port) as AnyObject? else {
            throw VPhoneVNCError.serverCreationFailed
        }
        vncServer = server
    }

    func waitForURL() async throws -> URL {
        while true {
            let port = VPhoneGetVNCPort(vncServer)
            if port != 0 {
                return URL(string: "vnc://:\(password)@127.0.0.1:\(port)")!
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
    }

    func stop() {
        VPhoneStopVNCServer(vncServer)
    }

    deinit {
        stop()
    }
}

enum VPhoneVNCError: Error, CustomStringConvertible {
    case serverCreationFailed

    var description: String {
        "Failed to create _VZVNCServer"
    }
}
