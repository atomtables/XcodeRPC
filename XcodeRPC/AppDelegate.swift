//
//  AppDelegate.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 02/07/2024.
//

import AppKit
import Cocoa
import Foundation
import SwordRPC

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusBar: NSStatusBar!
    var statusBarItem: NSStatusItem!

    public var items: [NSMenuItem] = []

    let info = Properties.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        for app in NSWorkspace.shared.runningApplications {
            if app.bundleIdentifier == "com.apple.dt.Xcode" {
                xcodeRunning = true
            } else if app.bundleIdentifier == "com.hnc.Discord" {
                discordRunning = true
            }
        }

        statusBar = NSStatusBar()
        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem.button?.image = NSImage(systemSymbolName: "hammer", accessibilityDescription: nil)
        let menu = XRPCMenu()
        statusBarItem.menu = menu
        print("made a menu: \(menu)")

        if UserDefaults.standard.bool(forKey: "StartRPCOnLaunchOfApp") {
            // connectRPC()
        }

        addObservers()
    }

    func addObservers() {
        NSWorkspace.shared.notificationCenter
            .addObserver(
                forName: NSWorkspace.didLaunchApplicationNotification,
                object: nil,
                queue: nil
            ) { notif in
                if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                    if app.bundleIdentifier == "com.apple.dt.Xcode" {
                        NSLog("xcode launched")
                        xcodeRunning = true
                        if xcodeRunning && discordRunning { connectRPC() }
                    } else if app.bundleIdentifier == "com.hnc.Discord" {
                        NSLog("discord launched")
                        discordRunning = true
                    }
                }
            }
        NSWorkspace.shared.notificationCenter
            .addObserver(
                forName: NSWorkspace.didTerminateApplicationNotification,
                object: nil,
                queue: nil
            ) { notif in
                if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                    if app.bundleIdentifier == "com.apple.dt.Xcode" {
                        NSLog("xcode quit")
                        xcodeRunning = false
                        disconnectRPC()
                    } else if app.bundleIdentifier == "com.hnc.Discord" {
                        NSLog("discord quit")
                        discordRunning = false
                        disconnectRPC()
                    }
                }
            }
            }

    func applicationWillTerminate(_ notification: Notification) {
        disconnectRPC()
    }
}

extension AppDelegate: SwordRPCDelegate {
    func swordRPCDidConnect(_ rpc: SwordRPC) {
        NSLog("Connected to Discord")
        DispatchQueue.main.async {
            Properties.shared.connected = true
            Properties.shared.connecting = false
        }
    }

    func swordRPCDidDisconnect(_ rpc: SwordRPC, code: Int?, message msg: String?) {
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

    func swordRPCDidReceiveError(_ rpc: SwordRPC, code: Int, message msg: String) {
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

class XRPCMenu: NSMenu {

    let info = XcodeRPC.Properties.shared

    init() {
        super.init(title: "XRPCMenu")
        createStatusBar()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createStatusBar() {
        NSMenuItem()
            .setTitle(URL(fileURLWithPath: info.workspace ?? "").lastPathComponent)
            .setVisibility(info.workspace != nil)
            .appendTo(&items)
        NSMenuItem()
            .setTitle(info.target ?? "")
            .setVisibility(info.target != nil)
            .appendTo(&items)
        NSMenuItem()
            .setTitle(info.currentFile ?? "")
            .setVisibility(info.currentFile != nil)
            .appendTo(&items)
        NSMenuItem.separator()
            .setVisibility(info.workspace != nil && info.target != nil && info.currentFile != nil)
            .appendTo(&items)
        NSMenuItem()
            .setTitle("Status: \(info.connected ? "Connected" : info.connecting ? "Connecting..." : "Disconnected")")
            .appendTo(&items)
        NSMenuItem()
            .setTitle("Connect RPC")
            .setEnabled(xcodeRunning && discordRunning)
            .setVisibility(!info.connected)
            .setAction(#selector(connect), target: self)
            .appendTo(&items)
        NSMenuItem()
            .setTitle("Run Xcode/Discord to connect...")
            .setVisibility(!discordRunning || !xcodeRunning)
            .appendTo(&items)
        NSMenuItem()
            .setTitle("Disconnect RPC")
            .setVisibility(info.connected)
            .setAction(#selector(disconnect), target: self)
            .appendTo(&items)
        NSMenuItem()
            .setTitle("Invalidate Icon Cache")
            .setEnabled(true)
            .setAction(#selector(invalidate), target: self)
            .appendTo(&items)
        NSMenuItem.separator()
            .appendTo(&items)
        NSMenuItem()
            .setTitle("Launch on Startup")
            .appendTo(&items)
        NSMenuItem.separator()
            .appendTo(&items)
        NSMenuItem()
            .setTitle("Quit")
            .setEnabled(true)
            .setAction(#selector(terminate), target: self)
            .appendTo(&items)
    }

    @objc private func connect() { connectRPC() }
    @objc private func disconnect() { disconnectRPC() }
    @objc private func invalidate() {
        let alert = NSAlert()
        alert.messageText = "Invalidate Icon Cache"
        alert.informativeText = "All icons will be removed for all applications. "
        alert.informativeText += "This action is irreversible. Are you sure?"
        alert.alertStyle = .warning

        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")

        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn:
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
        case .alertSecondButtonReturn:
            break
        default:
            break
        }
    }
    @objc private func terminate() { NSApp.terminate(nil) }

}
