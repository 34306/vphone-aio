import AppKit
import Foundation
import VPhoneObjC
import Virtualization

class VPhoneVNC {
    private let vncServer: AnyObject
    let password: String

    init(virtualMachine: VZVirtualMachine) throws {
        let words = ["apple", "swift", "phone", "vnc", "boot", "tart", "mac", "arm"]
        password = (0..<4).map { _ in words[Int.random(in: 0..<words.count)] }.joined(separator: "-")

        guard let server = VPhoneCreateVNCServer(virtualMachine, password) as AnyObject? else {
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
