//
//  InterViewState.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 30/06/2024.
//
import Foundation
import SwordRPC
import Cocoa

var doingSetup: Bool = false

var rpc: SwordRPC!
var timer: Timer!

var discordRunning: Bool = false
var xcodeRunning: Bool = false

var oldWorkspace: String?
var oldTarget: String?
var oldCurrentFile: String?

var time: Int = 0

var presence = RichPresence(start: Date())

private func initialiseRPC() {
    NSLog("initialised RPC")
    rpc = SwordRPC(appId: "1257064229203214426")
    rpc.delegate = delegate
}

func connectRPC() {
    guard !doingSetup else { return }

    initialiseRPC()
    Properties.shared.connecting = true
    let connected = rpc.connect()

    if connected {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if Properties.shared.connected {
                if time % 2 == 0 {
                    NSLog("running \(time / 2)")
                }
                time += 1
                RPCUpdate()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        timer.fire()
    } else {
        Properties.shared.connected = false
        Properties.shared.connecting = false
        disconnectRPC()

        let alert = NSAlert()
        alert.messageText = "An error occured"
        alert.informativeText = "XcodeRPC was unable to connect to Discord. Try again later."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

func disconnectRPC() {
    timer?.invalidate()
    Properties.shared.connected = false
    Properties.shared.connecting = false

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
    guard let rpc else {return}

    /// This is a more stable method of extracting data from
    /// Xcode that uses a single AppleScript, which also cuts down on processing time.
    /// It also has built in error handling instead of whatever it was before.
    /// It also hopefully shouldn't bring back Xcode when Xcode is closed.
    let workspace: String?, target: String?, currentFile: String?, sources: [String]?
    do {
        (workspace, target, currentFile, sources) = try runCombinedMainAppleScript()
    } catch XRPCError.error(let err) {
        rpc.disconnect()
        let alert = NSAlert()
        alert.messageText = "An error has occured."
        alert.informativeText = "\(err).\n\nPlease reconnect to the RPC from the menu bar."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
        return
    } catch { return }

    /// If all values are still the same, Discord does not need to be updated.
    guard workspace != oldWorkspace ||
            target != oldTarget ||
            currentFile != oldCurrentFile else {
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
        print("idling")
        presence.assets.largeImage = "xcode"; presence.assets.largeText = "Xcode"
        presence.details = "Idling..."
        presence.state = nil

        rpc.setPresence(presence)
        return
    }

    /// Set state and details, as every endpoint usually uses it.
    presence.state = target
    presence.details = currentFile

    /// If there is no current target, and the currentFile pathExtension is .playground
    /// you are in a playground workspace
    if URL(fileURLWithPath: "file:///\(currentFile ?? "")").pathExtension == "playground"
        && target == nil {
        print("in a playground")

        presence.assets.largeImage = "xcode"; presence.assets.largeText = "Xcode"
        presence.assets.smallImage = "playground"; presence.assets.smallText = "In a playground..."

        rpc.setPresence(presence)
        return
    }

    /// If there is no workspace, we are usually in the QuickEditor
    /// ignore the workspace portion and only show the current file.
    guard let workspace else {
        print("no workspace")
        presence.assets.largeImage = "xcode"; presence.assets.largeText = "Xcode"
        if let currentFile {
            let url = URL(file: "file:///\(currentFile)")
            let smallImage = getFileExtension(file: url)
            presence.assets.smallImage = smallImage
            presence.assets.smallText = "Editing a `\(url.pathExtension)` file"
        }

        rpc.setPresence(presence)
        return
    }

/* legacy code */
    // If no source file has been opened, or the current file's path extension is
    // non-existent, then it means no file is open. Only show the current workspace
    // we are in. Usually when no other file is open, currentFile is the name of the xcodeproj.
//    if sources == nil || URL(file: "file:///\(currentFile ?? "")").pathExtension == "" {
//        presence.details = nil
//
//        let workspaceURL = URL(file: workspace)
//        var image: String = "default_app_icon"
//        uploadIcon(path: findIcon(workspace: workspaceURL), workspace: workspaceURL) { result in
//            image = result
//        }
//        presence.assets.largeImage = image; presence.assets.largeText = target
//
//        rpc?.setPresence(presence)
//        return
//    }
/* end legacy code */

    /// If the currently opened file cannot be found in sources, it usually indicates that
    /// there is no open file. Only show the current workspace we are in. Sources intentionally blocks
    /// out the current workspace, so if the currently opened file shows as the workspace without the
    /// workspace being opened as a tab, there are no tabs open.
    if let sources, !(sources.contains(where: {URL(file: "file:///\($0)").lastPathComponent == currentFile})) {
        print("no current file")
        presence.details = nil

        let workspaceURL = URL(file: workspace)
        var image: String = "default_app_icon"
        uploadIcon(path: findIcon(workspace: workspaceURL), workspace: workspaceURL) { image = $0 }
        presence.assets.largeImage = image; presence.assets.largeText = target

        rpc.setPresence(presence)
        return
    }

    print("workspace and current file")
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

    rpc.setPresence(presence)
}
