//
//  XcodeRPCApp.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 29/06/2024.
//

import SwiftUI

var DONOTCONNECT = false

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

@main
struct XcodeRPCApp: App {
    @StateObject var info = Properties.shared

    init() {
        DispatchQueue.main.async {
            Properties.shared.tick = !Properties.shared.tick
            Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
                Properties.shared.tick.toggle()
            }
        }
        NSWorkspace.shared.notificationCenter
            .addObserver(
                forName: NSWorkspace.didLaunchApplicationNotification,
                object: nil,
                queue: nil
            ) { notif in
                    if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                        if app.bundleIdentifier == "com.apple.dt.Xcode" {
                            NSLog("xcode launched, connecting...")
                            DONOTCONNECT = false
                            connectRPC()
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
                            NSLog("xcode closed, disconnecting...")
                            DONOTCONNECT = true
                            Properties.shared.connected = false
                            disconnectRPC()
                            _ = runAppleScript(script: quitXcodeScript)
                        }
                    }
                }
    }

    var body: some Scene {
        MenuBarExtra("XcodeRPC", systemImage: info.image) {
            ContentView()
                .environmentObject(info)
        }
    }
}
