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
    @Environment(\.dismissWindow) var dismiss

    @State var firstLaunch = false
    @State var count = 1

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
        WindowGroup(id: "firstLaunchWindow") {
            if firstLaunch {
                WelcomeScreen(count: $count)
                    .toolbar {
                        Group {
                            Spacer()
                            WelcomeTabBar(count: $count)
                            Spacer()
                        }
                    }
                    .onReceive(
                        NotificationCenter.default.publisher(
                            for: NSApplication.didBecomeActiveNotification
                        ),
                        perform: { _ in
                            NSApp.mainWindow?.standardWindowButton(.zoomButton)?.isHidden = true
                            NSApp.mainWindow?.standardWindowButton(.closeButton)?.isHidden = true
                            NSApp.mainWindow?.standardWindowButton(.miniaturizeButton)?.isHidden = true
                        }
                    )
            } else {
                HStack {}
                    .onAppear {
                        dismiss(id: "firstLaunchWindow")
                    }
            }
        }
        .windowStyle(HiddenTitleBarWindowStyle())

        MenuBarExtra("XcodeRPC", systemImage: info.image) {
            ContentView()
                .environmentObject(info)
        }
    }
}

struct WelcomeTabBar: View {
    @Binding var count: Int
    var body: some View {
        HStack {
            Image(systemName: count == 1 ? "circlebadge.fill" : "circlebadge")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
            Image(systemName: count == 2 ? "circlebadge.fill" : "circlebadge")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
            Image(systemName: count == 3 ? "circlebadge.fill" : "circlebadge")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
            Image(systemName: count == 4 ? "circlebadge.fill" : "circlebadge")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
        }
        .offset(x: -20)
    }
}

struct WelcomeScreen: View {
    @Binding var count: Int

    var body: some View {
        HStack {
            Image(systemName: "chevron.compact.left")
            Spacer()
            if count == 1 {
                HStack {
                    Image(nsImage: NSImage(named: "XcodeRPC")!)
                        .resizable()
                        .frame(width: 80, height: 80)
                    VStack(alignment: .leading) {
                        Text("XcodeRPC")
                            .font(.title)
                            .bold()
                        Text("by atomtables")
                    }
                }
            } else if count == 2 {
                Text("Tab 2").font(.title).foregroundColor(.blue)
            } else if count == 3 {
                Text("Tab 3").font(.title).foregroundColor(.green)
            } else if count == 4 {
                Text("Tab 4").font(.title).foregroundColor(.red)
            }
            Spacer()
            Image(systemName: "chevron.compact.right")
        }
    }
}
