//
//  XcodeRPCApp.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 29/06/2024.
//

import SwiftUI

final class Properties: ObservableObject {
    static var shared: Properties = Properties()

    private init() {}

    @Published var workspace: String? {
        didSet {
            delegate.menu.updateWorkspace()
        }
    }
    @Published var target: String? {
        didSet {
            delegate.menu.updateTarget()
        }
    }
    @Published var currentFile: String? {
        didSet {
            delegate.menu.updateCurrentFile()
        }
    }

    @Published var tick = false {
        didSet {
            if connecting {
                if tick {
                    delegate.statusBarItem.button?.image = NSImage(systemSymbolName: "hammer.fill", accessibilityDescription: nil)
                } else {
                    delegate.statusBarItem.button?.image = NSImage(systemSymbolName: "hammer", accessibilityDescription: nil)
                }
            } else if connected {
                delegate.statusBarItem.button?.image = NSImage(systemSymbolName: "hammer.fill", accessibilityDescription: nil)
            } else {
                delegate.statusBarItem.button?.image = NSImage(systemSymbolName: "hammer", accessibilityDescription: nil)
            }
        }
    }

    @Published var connecting: Bool = false {
        didSet {
            delegate.menu.updateStatus()
            delegate.menu.updateConnectDisconnect()
        }
    }
    @Published var connected: Bool = false {
        didSet {
            delegate.menu.updateStatus()
            delegate.menu.updateConnectDisconnect()
        }
    }

    @Published var beginningScrollView: ScrollViewProxy!
}

//struct XcodeRPCApp {
//    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//    @StateObject var info = Properties.shared
//    @Environment(\.dismissWindow) var dismiss
//    @Environment(\.openWindow) var openWindow
//
//    @State var firstLaunch: Bool
//    @State var count = 1
//    @State var disableNext = false
//
//    init() {
//        firstLaunch = !UserDefaults.standard.bool(forKey: "FirstLaunchFinished")
//
//        DispatchQueue.main.async {
//            Properties.shared.tick = !Properties.shared.tick
//            Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
//                Properties.shared.tick.toggle()
//            }
//        }
//    }
//
//    var body: some Scene {
//        WindowGroup(id: "firstLaunchWindow") {
//            if firstLaunch {
//                WelcomeScreen(count: $count, firstLaunch: $firstLaunch, disableNext: $disableNext)
//                    .toolbar {
//                        Group {
//                            Spacer()
//                            WelcomeTabBar(count: $count)
//                            Spacer()
//                        }
//                    }
//                    .onReceive(
//                        NotificationCenter.default.publisher(
//                            for: NSApplication.didBecomeActiveNotification
//                        ),
//                        perform: { _ in
//                            NSApp.mainWindow?.standardWindowButton(.zoomButton)?.isHidden = true
//                            NSApp.mainWindow?.standardWindowButton(.closeButton)?.isHidden = true
//                            NSApp.mainWindow?.standardWindowButton(.miniaturizeButton)?.isHidden = true
//                        }
//                    )
//                    .task {
////                        for window in NSApplication.shared.windows {
////                            window.level = .floating
////                        }
//                    }
//                    .environmentObject(info)
//            } else {
//                HStack {}
//                    .onAppear {
//                        dismiss(id: "firstLaunchWindow")
//                    }
//            }
//        }
//        .windowStyle(HiddenTitleBarWindowStyle())
//
//        MenuBarExtra("XcodeRPC", systemImage: info.image) {
//            if firstLaunch {
//                Text("Please continue setup.")
//                Button("Quit") {
//                    disconnectRPC()
//                    NSApp.terminate(nil)
//                }
//            } else {
//                ContentView()
//                    .environmentObject(info)
//            }
//        }
//    }
//}
