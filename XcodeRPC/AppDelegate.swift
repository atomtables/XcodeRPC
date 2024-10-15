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

class XRPCMenu: NSMenu {

    let info = XcodeRPC.Properties.shared
    var setupActive = true

    init() {
        super.init(title: "XRPCMenu")
        createStatusBar()

        workspaceMenuItem = items[0]
        targetMenuItem = items[1]
        currentFileMenuItem = items[2]
        dividerOneMenuItem = items[3]
        statusMenuItem = items[4]
        connectMenuItem = items[5]
        errorMenuItem = items[6]
        disconnectMenuItem = items[7]
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var workspaceMenuItem: NSMenuItem!
    public func updateWorkspace() {
        guard setupActive else { return }
        workspaceMenuItem.isHidden = info.workspace == nil
        workspaceMenuItem.title = URL(fileURLWithPath: info.workspace ?? "").lastPathComponent
        updateDividerOne()
    }
    public var targetMenuItem: NSMenuItem!
    public func updateTarget() {
        targetMenuItem.isHidden = info.target == nil
        targetMenuItem.title = info.target ?? ""
        updateDividerOne()
    }
    public var currentFileMenuItem: NSMenuItem!
    public func updateCurrentFile() {
        currentFileMenuItem.isHidden = info.currentFile == nil
        currentFileMenuItem.title = info.currentFile ?? ""
        updateDividerOne()
    }
    private var dividerOneMenuItem: NSMenuItem!
    private func updateDividerOne() {
        dividerOneMenuItem.isHidden = info.workspace == nil || info.target == nil || info.currentFile == nil
    }
    public var statusMenuItem: NSMenuItem!
    public func updateStatus() {
        statusMenuItem
            .title = "Status: \(info.connected ? "Connected" : info.connecting ? "Connecting..." : "Disconnected")"
    }
    public var connectMenuItem: NSMenuItem!
    public var errorMenuItem: NSMenuItem!
    public var disconnectMenuItem: NSMenuItem!
    public func updateConnectDisconnect() {
        if !info.connected {
            connectMenuItem.isHidden = false
            disconnectMenuItem.isHidden = true
            if !xcodeRunning || !discordRunning {
                connectMenuItem.isEnabled = false
                errorMenuItem.isHidden = false
            } else {
                connectMenuItem.isEnabled = true
                errorMenuItem.isHidden = true
                if info.connecting { connectMenuItem.isEnabled = false }
            }
        } else {
            connectMenuItem.isHidden = true
            disconnectMenuItem.isHidden = false
        }
    }

    public func createStatusBar() {
        items = []
        NSMenuItem(URL(fileURLWithPath: info.workspace ?? "").lastPathComponent)
            .setVisibility(info.workspace != nil)
            .appendTo(&items)
        NSMenuItem(info.target ?? "")
            .setVisibility(info.target != nil)
            .appendTo(&items)
        NSMenuItem(info.currentFile ?? "")
            .setVisibility(info.currentFile != nil)
            .appendTo(&items)
        NSMenuItem.separator()
            .setVisibility(info.workspace != nil && info.target != nil && info.currentFile != nil)
            .appendTo(&items)
        NSMenuItem("Status: \(info.connected ? "Connected" : info.connecting ? "Connecting..." : "Disconnected")")
            .appendTo(&items)
        NSMenuItem("Connect RPC")
            .setAction(#selector(connect), target: self)
            .setEnabled(xcodeRunning && discordRunning)
            .setVisibility(!info.connected)
            .appendTo(&items)
        NSMenuItem("Run Xcode/Discord to connect...")
            .setVisibility(!discordRunning || !xcodeRunning)
            .appendTo(&items)
        NSMenuItem("Disconnect RPC")
            .setVisibility(info.connected)
            .setAction(#selector(disconnect), target: self)
            .appendTo(&items)
        NSMenuItem("Invalidate Icon Cache")
            .setAction(#selector(invalidate), target: self)
            .appendTo(&items)
        NSMenuItem.separator().appendTo(&items)
        NSMenuItem("Launch on Startup")
            .appendTo(&items)
        NSMenuItem.separator()
            .appendTo(&items)
        NSMenuItem("Quit")
            .setAction(#selector(terminate), target: self)
            .appendTo(&items)
    }
    public func createSetupMenuBar() {
        items = []
        NSMenuItem()
            .setTitle("Please continue setup.")
            .appendTo(&items)
        NSMenuItem()
            .setTitle("Show Setup Window")
            .setEnabled(true)
            .setAction(#selector(openSetupWindow), target: self)
            .appendTo(&items)
        NSMenuItem.separator().appendTo(&items)
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
    @objc private func openSetupWindow() {
        if let windowController = XcodeRPC.delegate.windowController {
            if let window = windowController.window {
                windowController.displayWindow()
            }
        }

        let storyboard: NSStoryboard = NSStoryboard(name: "WelcomeWindow", bundle: nil)
        XcodeRPC.delegate.windowController = storyboard
            .instantiateController(withIdentifier: "WelcomeWindowController")
        as? WelcomeWindowController
        doingSetup = true
        XcodeRPC.delegate.windowController.displayWindow()
    }
}
