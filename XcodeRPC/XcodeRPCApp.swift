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

    @Published var beginningScrollView: ScrollViewProxy!
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
                    .task {
                        for window in NSApplication.shared.windows {
                            window.level = .floating
                        }
                    }
                    .environmentObject(info)
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
    @EnvironmentObject var info: Properties
    @Binding var count: Int

    @State private var leftHover: Bool = false
    @State private var rightHover: Bool = false

    var body: some View {
        GeometryReader { geometry in
            HStack {
                HStack {}
                    .padding(2.5)

                // Left arrow
                Image(systemName: "chevron.compact.left")
                    .scaleEffect(2)
                    .padding()
                    .foregroundStyle(count == 1 ? .quinary : .tertiary)
                    .background(
                        leftHover ? Color.gray.opacity(0.25) : Color.clear
                    )
                    .cornerRadius(10)
                    .onHover { active in
                        withAnimation {
                            leftHover = active && count != 1
                        }
                    }
                    .onTapGesture {
                        if count != 1 {
                            withAnimation {
                                count -= 1
                            }
                        }
                    }

                Spacer()

                WelcomeTabView(count: $count, geometry: geometry)

                Spacer()

                // Right arrow
                Image(systemName: "chevron.compact.right")
                    .scaleEffect(2)
                    .padding()
                    .foregroundStyle(count == 4 ? .quinary : .tertiary)
                    .background(
                        rightHover ? Color.gray.opacity(0.25) : Color.clear
                    )
                    .cornerRadius(10)
                    .onHover { active in
                        withAnimation {
                            rightHover = active && count != 4
                        }
                    }
                    .onTapGesture {
                        if count != 4 {
                            withAnimation {
                                count += 1
                            }
                        }
                    }

                HStack {}
                    .padding(2.5)
            }
        }
    }
}

struct WelcomeTabView: View {
    @Binding var count: Int
    @State var normalCount: Int
    let geometry: GeometryProxy

    @State var firstTabTransition: Edge = .leading
    @State var secondTabTransition: Edge = .trailing
    @State var thirdTabTransition: Edge = .trailing
    @State var fourthTabTransition: Edge = .leading

    init(count: Binding<Int>, geometry: GeometryProxy) {
        self._count = count
        self._normalCount = State(initialValue: 1)
        self.geometry = geometry

        self.normalCount = self.count
    }

    var body: some View {
        Group {
            if normalCount == 1 {
                VStack {
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
                    HStack {
                        VStack {
                            Image(systemName: "person.3.fill")
                                .scaleEffect(2)
                                .padding()
                            Text("Save and display your activity in Xcode to all of your friends on Discord!")
                                .frame(width: 180)
                                .multilineTextAlignment(.center)
                        }
                        VStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .scaleEffect(2)
                                .padding()
                            Text("Show off your icons, current open file, and workspace using Rich Presence!")
                                .frame(width: 180)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .transition(.move(edge: firstTabTransition))
            } else if normalCount == 2 {
                Text("Tab 2").font(.title).foregroundColor(.blue)
                    .transition(.move(edge: secondTabTransition))
            } else if normalCount == 3 {
                Text("Tab 3").font(.title).foregroundColor(.green)
                    .transition(.move(edge: thirdTabTransition))
            } else if normalCount == 4 {
                Text("Tab 4").font(.title).foregroundColor(.red)
                    .transition(.move(edge: fourthTabTransition))
            }
        }
        .frame(width: geometry.size.width-120, height: geometry.size.height)
        .onChange(of: count) { old, new in
            print(old, new)
            /// We are going backwards
            if old - new == 1 {
                switch old {
                case 2:
                    firstTabTransition = .leading
                    secondTabTransition = .trailing
                case 3:
                    secondTabTransition = .leading
                    thirdTabTransition = .trailing
                case 4:
                    thirdTabTransition = .leading
                    fourthTabTransition = .trailing
                default: break
                }
            } 
            /// We are going forwards
            else {
                switch old {
                case 1:
                    firstTabTransition = .leading
                    secondTabTransition = .trailing
                case 2:
                    secondTabTransition = .leading
                    thirdTabTransition = .trailing
                case 3:
                    thirdTabTransition = .leading
                    fourthTabTransition = .trailing
                default: break
                }
            }
            withAnimation {
                normalCount = new
            }
        }
    }
}
