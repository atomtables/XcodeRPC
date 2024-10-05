//
//  InterViewState.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 30/06/2024.
//
import Foundation
import SwordRPC
import Cocoa

var rpc: SwordRPC!
var concurrentExecution: Timer!

var oldWorkspace: String?
var oldTarget: String?
var oldCurrentFile: String?

var time: Int = 0

var presence = RichPresence(start: Date())
let delegate = XRPCSwordRPCDelegate()

fileprivate func initialiseRPC() {
    NSLog("initialised RPC")
    rpc = SwordRPC(appId: "1257064229203214426")
    rpc.delegate = delegate
}

func connectRPC() {
    initialiseRPC()
    Properties.shared.connecting = true
    let connected = rpc.connect()

    if connected {
        concurrentExecution = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if Properties.shared.connected {
                NSLog("running \(time)")
                time += 1
                RPCUpdate()
            }
        }
        RunLoop.main.add(concurrentExecution, forMode: .common)
        concurrentExecution.fire()
    }
}

func disconnectRPC() {
    concurrentExecution?.invalidate()
    Properties.shared.connected = false

    Properties.shared.workspace = nil
    Properties.shared.target = nil
    Properties.shared.currentFile = nil

    oldWorkspace = nil
    oldTarget = nil
    oldCurrentFile = nil

    rpc?.setPresence(RichPresence())
    rpc?.disconnect()
    rpc = nil
}

// swiftlint:disable:next function_body_length
func RPCUpdate() {
    /// We need these 5 DONOTCONNECT checks so RPCUpdate doesn't try to
    /// reopen Xcode after Xcode sends the applicationDidTerminate signal.
    let workspace = runAppleScript(script: getWorkspaceScript)
    let target = runAppleScript(script: getTargetScript)
    let currentFile = runAppleScript(script: getFileScript)
    let sources = runAppleScript(script: getSourcesScript)

    /// All values are still the same, so Discord does not need to be updated.
    guard workspace != oldWorkspace || target != oldTarget || currentFile != oldCurrentFile else {
        return
    }
    oldWorkspace = workspace; oldTarget = target; oldCurrentFile = currentFile

    /// Set the current workspace, target, and current file in the view model.
    DispatchQueue.main.async {
        Properties.shared.workspace = workspace
        Properties.shared.target = target
        Properties.shared.currentFile = currentFile
    }

    /// If all values are nil, Xcode is idling.
    if workspace == nil && target == nil && currentFile == nil {
        presence.assets.largeImage = "xcode"; presence.assets.largeText = "Xcode"
        presence.state = "Idling..."
        rpc?.setPresence(presence)
    }

    /// Set state and details, as every endpoint usually uses it.
    presence.state = target
    presence.details = currentFile

    /// If a playground is open, use the playground icon.
    if URL(fileURLWithPath: "file:///\(currentFile ?? "")").pathExtension == "playground"
        && target == nil {

        presence.assets.largeImage = "xcode"; presence.assets.largeText = "Xcode"
        presence.assets.smallImage = "playground"; presence.assets.smallText = "In a playground..."

        rpc?.setPresence(presence)
        return
    }

    /// If there is no workspace, or we are in the QuickEditor,
    /// ignore the workspace portion and only show the current file.
    guard let workspace else {
        presence.assets.largeImage = "xcode"; presence.assets.largeText = "Xcode"
        if let currentFile {
            let url = URL(file: "file:///\(currentFile)")
            let smallImage = getFileExtension(file: url)
            presence.assets.smallImage = smallImage
            presence.assets.smallText = "Editing a `\(url.pathExtension)` file"
        }

        rpc?.setPresence(presence)
        return
    }

    /// If no source file has been opened, or the current file's path extension is
    /// non-existent, then it means no file is open. Only show the current workspace
    /// we are in. Usually when no other file is open, currentFile is the name of the xcodeproj.
    if sources == nil || URL(file: "file:///\(currentFile ?? "")").pathExtension == "" {
        presence.details = nil

        let workspaceURL = URL(file: workspace)
        var image: String = "default_app_icon"
        uploadIcon(path: findIcon(workspace: workspaceURL), workspace: workspaceURL) { result in
            image = result
        }
        presence.assets.largeImage = image; presence.assets.largeText = target

        rpc?.setPresence(presence)
        return
    }

    let workspaceURL = URL(file: workspace)
    var image: String = "default_app_icon"
    uploadIcon(path: findIcon(workspace: workspaceURL), workspace: workspaceURL) { result in
        image = result
    }
    presence.assets.largeImage = image; presence.assets.largeText = target

    if let currentFile {
        let url = URL(file: "file:///\(currentFile)")
        let smallImage = getFileExtension(file: url)
        presence.assets.smallImage = smallImage
        presence.assets.smallText = "Editing a `\(url.pathExtension)` file"
    }

    rpc?.setPresence(presence)
}
