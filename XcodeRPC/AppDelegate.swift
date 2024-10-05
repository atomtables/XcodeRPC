//
//  AppDelegate.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 02/07/2024.
//

import Cocoa
import Foundation
import SwordRPC

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let shouldStartRPC = UserDefaults.standard.bool(forKey: "StartRPCOnLaunchOfApp")
        if shouldStartRPC {
            connectRPC()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        disconnectRPC()
    }
}

class XRPCSwordRPCDelegate: SwordRPCDelegate {
    func swordRPCDidConnect(_ rpc: SwordRPC) {
        NSLog("Connected to Discord")
        DispatchQueue.main.async {
            Properties.shared.connected = true
            Properties.shared.connecting = false
        }
    }

    func swordRPCDidDisconnect(
        _ rpc: SwordRPC,
        code: Int?,
        message msg: String?
    ) {
        NSLog("Disconnected from Discord: \(code ?? 0) \(msg ?? "no message")")
        if let code, let msg {
            let alert = NSAlert()
            alert.messageText = "An error occured"
            // swiftlint:disable:next line_length
            alert.informativeText = "XcodeRPC disconnected from Discord. Code: \(code). \"\(msg)\"\n\nYou can reconnect from the menu bar."
            alert.alertStyle = .critical

            // Add buttons
            alert.addButton(withTitle: "OK")

            // Show the alert
            alert.runModal()
        }
        DispatchQueue.main.async {
            Properties.shared.connected = false
            Properties.shared.connecting = false
        }
    }

    func swordRPCDidReceiveError(
        _ rpc: SwordRPC,
        code: Int,
        message msg: String
    ) {
        disconnectRPC()
        NSLog("Discord returned an error: \(code) \(msg)")
        let alert = NSAlert()
        alert.messageText = "An error occured."
        alert.informativeText = "XcodeRPC ran into an error (e\(code)). \"\(msg)\"\nYou can reconnect from the menu bar"
        alert.alertStyle = .critical

        // Add buttons
        alert.addButton(withTitle: "OK")
        alert.runModal()
        DispatchQueue.main.async {
            Properties.shared.connected = false
            Properties.shared.connecting = false
        }
    }
}
