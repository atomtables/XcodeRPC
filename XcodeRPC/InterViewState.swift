//
//  InterViewState.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 30/06/2024.
//
import Foundation
import SwordRPC

var rpc = SwordRPC(appId: "1257064229203214426")
var concurrentExecution: DispatchWorkItem!

final class Properties: ObservableObject {
    static var shared: Properties = Properties()

    private init() {}

    @Published var workspace: String?
    @Published var target: String?
    @Published var currentFile: String?

    @Published var tick = false

    var image: String {
        if connecting {
            if tick {
                "hammer.fill"
            } else {
                "hammer"
            }
        } else if connected {
            "hammer.fill"
        } else {
            "hammer"
        }
    }

    @Published var connecting: Bool = false
    @Published var connected: Bool = false
}

var oldWorkspace: String? = nil
var oldTarget: String? = nil
var oldCurrentFile: String? = nil

extension RichPresence {
    init(start: Date = Date()) {
        self.init()
        self.timestamps.start = start
    }
}

var presence = RichPresence(start: Date())

func RPCEventHandlers() {
    rpc.onConnect { rpc in
        DispatchQueue.main.async {
            NSLog("Connected")
            Properties.shared.connected = true
            Properties.shared.connecting = false
            RunRPCUpdate()
        }
    }

    rpc.onDisconnect { rpc, code, msg in
        concurrentExecution.cancel()
        DispatchQueue.main.async {
            NSLog("Disconnected")
            Properties.shared.connected = false
        }
    }

    rpc.onError { rpc, code, msg in
        NSLog("Discord returned an error: \(code) \(msg)")
    }
}

func RunRPCUpdate() {
    Task {
        concurrentExecution = DispatchWorkItem {
            if Properties.shared.connected {
                RunRPCUpdate()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+1, execute: concurrentExecution)

        let workspace = RunAppleScript(script: getWorkspaceScript)
        let target = RunAppleScript(script: getTargetScript)
        let currentFile = RunAppleScript(script: getFileScript)

        guard workspace != oldWorkspace || target != oldTarget || currentFile != oldCurrentFile else {
            return
        }
        oldWorkspace = workspace
        oldTarget = target
        oldCurrentFile = currentFile

        if URL(fileURLWithPath: "file:///\(currentFile ?? "")").pathExtension == "playground"
            && target == nil {

            presence.state = target
            presence.details = currentFile
            presence.assets.largeImage = "xcode"
            presence.assets.smallImage = "playground"

            rpc.setPresence(presence)
            return
        }

        guard let workspace else {
            presence.state = target
            presence.details = currentFile

            presence.assets.largeImage = "xcode"
            let smallImage = GetFileExtension(file: URL(fileURLWithPath: "file:///\(currentFile ?? "")"))
            presence.assets.smallImage = smallImage
            presence.assets.smallText = "Editing a `\(URL(fileURLWithPath: "file:///\(currentFile ?? "")").pathExtension)` file"

            rpc.setPresence(presence)
            return
        }

        presence.state = target
        presence.details = currentFile

        let workspaceURL = URL(fileURLWithPath: workspace)
        let image = await UploadIcon(path: FindIcon(workspace: workspaceURL), workspace: workspaceURL)
        presence.assets.largeImage = image

        let smallImage = GetFileExtension(file: URL(fileURLWithPath: "file:///\(currentFile ?? "")"))
        presence.assets.smallImage = smallImage
        presence.assets.smallText = "Editing a `\(URL(fileURLWithPath: "file:///\(currentFile ?? "")").pathExtension)` file"

        rpc.setPresence(presence)

        DispatchQueue.main.async {
            Properties.shared.workspace = workspace
            Properties.shared.target = target
            Properties.shared.currentFile = currentFile
        }
    }
}
