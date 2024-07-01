//
//  InterViewState.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 30/06/2024.
//
import Foundation
import SwordRPC

let rpc = SwordRPC(appId: "1257064229203214426")
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
            Properties.shared.connected = true
            Properties.shared.connecting = false
            RunRPCUpdate()
        }
    }

    rpc.onDisconnect { rpc, code, msg in
        concurrentExecution.cancel()
        Properties.shared.connected = false
    }

    rpc.onError { rpc, code, msg in
        NSLog("Discord returned an error: \(code) \(msg)")
    }
}

func RunRPCUpdate() {
    concurrentExecution = DispatchWorkItem {
        if Properties.shared.connected {
            RunRPCUpdate()
        }
    }
    DispatchQueue.main.asyncAfter(deadline: .now()+1, execute: concurrentExecution)

    Properties.shared.workspace = RunAppleScript(script: getWorkspaceScript)
    Properties.shared.target = RunAppleScript(script: getTargetScript)
    Properties.shared.currentFile = RunAppleScript(script: getFileScript)

    guard Properties.shared.workspace != oldWorkspace || Properties.shared.target != oldTarget || Properties.shared.currentFile != oldCurrentFile else {
        return
    }
    oldWorkspace = Properties.shared.workspace
    oldTarget = Properties.shared.target
    oldCurrentFile = Properties.shared.currentFile

    if URL(fileURLWithPath: "file:///\(Properties.shared.currentFile ?? "")").pathExtension == "playground" 
        && Properties.shared.target == nil {

        presence.state = Properties.shared.target
        presence.details = Properties.shared.currentFile
        presence.assets.largeImage = "xcode"
        presence.assets.smallImage = "playground"

        rpc.setPresence(presence)
        return
    }

    guard let workspace = Properties.shared.workspace else {
        presence.state = Properties.shared.target
        presence.details = Properties.shared.currentFile

        presence.assets.largeImage = "xcode"
        let smallImage = GetFileExtension(file: URL(fileURLWithPath: "file:///\(Properties.shared.currentFile ?? "")"))
        presence.assets.smallImage = smallImage
        presence.assets.smallText = "Editing a `\(URL(fileURLWithPath: "file:///\(Properties.shared.currentFile ?? "")").pathExtension)` file"

        rpc.setPresence(presence)
        return
    }

    presence.state = Properties.shared.target
    presence.details = Properties.shared.currentFile

    let workspaceURL = URL(fileURLWithPath: workspace)
    let image = UploadIcon(path: FindIcon(workspace: workspaceURL), workspace: workspaceURL)
    presence.assets.largeImage = image
 
    let smallImage = GetFileExtension(file: URL(fileURLWithPath: "file:///\(Properties.shared.currentFile ?? "")"))
    presence.assets.smallImage = smallImage
    presence.assets.smallText = "Editing a `\(URL(fileURLWithPath: "file:///\(Properties.shared.currentFile ?? "")").pathExtension)` file"

    rpc.setPresence(presence)
}
