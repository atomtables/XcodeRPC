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
    var menu: XRPCMenu!
    var windowController: WelcomeWindowController!

    let info = Properties.shared

    @objc func hideWelcomeWindow() { windowController.hideWindow() }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let storyboard: NSStoryboard = NSStoryboard(name: "WelcomeWindow", bundle: nil)
        windowController = storyboard
            .instantiateController(withIdentifier: "WelcomeWindowController")
        as? WelcomeWindowController

        for app in NSWorkspace.shared.runningApplications {
            if app.bundleIdentifier == "com.apple.dt.Xcode" {
                xcodeRunning = true
            } else if app.bundleIdentifier == "com.hnc.Discord" {
                discordRunning = true
            }
        }

        DispatchQueue.main.async {
            Properties.shared.tick = !Properties.shared.tick
            Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
                Properties.shared.tick.toggle()
            }
        }

        statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem.button?.appearance = NSAppearance.currentDrawing()
        statusBarItem.button?.image = NSImage(systemSymbolName: "hammer", accessibilityDescription: nil)
        menu = XRPCMenu()
        statusBarItem.menu = menu

        // If first launch has not occured yet...
        if !UserDefaults.standard.bool(forKey: "FirstLaunchFinished") {
            doingSetup = true
            menu.createSetupMenuBar()
            windowController.displayWindow()
            statusBarItem.menu = menu
        }

        if UserDefaults.standard.bool(forKey: "StartRPCOnLaunchOfApp") {
            // connectRPC()
        }

        addObservers()
    }
    func applicationWillTerminate(_ notification: Notification) {
        disconnectRPC()
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

    @objc func finishSetup() {
        doingSetup = false
        menu = XRPCMenu()
        statusBarItem.menu = menu
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
