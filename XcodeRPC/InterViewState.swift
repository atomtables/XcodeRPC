//
//  InterViewState.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 30/06/2024.
//
import Foundation
import SwordRPC

var rpc = SwordRPC(appId: "1257064229203214426")
var concurrentExecution: Timer!

var oldWorkspace: String?
var oldTarget: String?
var oldCurrentFile: String?

var presence = RichPresence(start: Date())

func RPCEventHandlers() {
    rpc.onConnect { _ in
        DispatchQueue.main.async {
            NSLog("Connected")
            Properties.shared.connected = true
            Properties.shared.connecting = false
            concurrentExecution = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
                if Properties.shared.connected {
                    runRPCUpdate()
                }
            }
        }
    }

    rpc.onDisconnect { _, code, msg in
        concurrentExecution.invalidate()
        DispatchQueue.main.async {
            NSLog("Disconnected: \(code ?? 0) \(msg ?? "no message")")
            Properties.shared.connected = false
        }
    }

    rpc.onError { _, code, msg in
        NSLog("Discord returned an error: \(code) \(msg)")
    }
}

// swiftlint:disable:next function_body_length
func runRPCUpdate() {
    Task {
        let workspace = runAppleScript(script: getWorkspaceScript)
        let target = runAppleScript(script: getTargetScript)
        let currentFile = runAppleScript(script: getFileScript)
        let sources = runAppleScript(script: getSourcesScript)

        guard workspace != oldWorkspace || target != oldTarget || currentFile != oldCurrentFile else {
            return
        }
        oldWorkspace = workspace; oldTarget = target; oldCurrentFile = currentFile

        if workspace == nil && target == nil && currentFile == nil {
            presence.assets.largeImage = "xcode"; presence.assets.largeText = "Xcode"
            presence.state = "Idling..."
            rpc.setPresence(presence)
        }

        if URL(fileURLWithPath: "file:///\(currentFile ?? "")").pathExtension == "playground"
            && target == nil {

            presence.state = target
            presence.details = currentFile
            presence.assets.largeImage = "xcode"; presence.assets.largeText = "Xcode"
            presence.assets.smallImage = "playground"; presence.assets.smallText = "In a playground..."

            rpc.setPresence(presence)
            return
        }

        guard let workspace else {
            presence.state = target
            presence.details = currentFile

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

        if sources == nil || URL(file: "file:///\(currentFile ?? "")").pathExtension == "" {
            presence.state = target

            let workspaceURL = URL(file: workspace)
            let image = await uploadIcon(path: findIcon(workspace: workspaceURL), workspace: workspaceURL)
            presence.assets.largeImage = image; presence.assets.largeText = target

            rpc.setPresence(presence)
            return
        }

        presence.state = target
        presence.details = currentFile

        let workspaceURL = URL(file: workspace)
        let image = await uploadIcon(path: findIcon(workspace: workspaceURL), workspace: workspaceURL)
        presence.assets.largeImage = image; presence.assets.largeText = target

        if let currentFile {
            let url = URL(file: "file:///\(currentFile)")
            let smallImage = getFileExtension(file: url)
            presence.assets.smallImage = smallImage
            presence.assets.smallText = "Editing a `\(url.pathExtension)` file"
        }

        rpc.setPresence(presence)

        DispatchQueue.main.async {
            Properties.shared.workspace = workspace
            Properties.shared.target = target
            Properties.shared.currentFile = currentFile
        }
    }
}
