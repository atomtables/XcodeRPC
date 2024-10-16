//
//  WelcomeScreen.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 5/10/2024.
//

import SwiftUI

class WelcomeWindowController: NSWindowController {
    func displayWindow() {
        app.setActivationPolicy(.regular)

        self.window?.makeKeyAndOrderFront(nil)
        self.window?.level = .floating
    }

    func hideWindow() {
        app.setActivationPolicy(.accessory)

        self.window?.close()
        self.window = nil
        delegate.finishSetup()
    }

    override func windowDidLoad() {
        window?.contentView = NSHostingView(
            rootView: WelcomeScreenCompleteView()
        )
    }
}

struct WelcomeScreenCompleteView: View {
    @State var count = 1
    @State var firstLaunch = true
    @State var disableNext = false

    @State var xcodePermissionsReceived = false
    @State var eventsPermissionsReceived = false

    var body: some View {
        WelcomeScreen(
            count: $count,
            firstLaunch: $firstLaunch,
            disableNext: $disableNext,
            xcodePermissionsReceived: $xcodePermissionsReceived,
            eventsPermissionsReceived: $eventsPermissionsReceived
        )
        .toolbar {
            Group {
                Spacer()
                WelcomeTabBar(count: $count)
            }
        }
        .environmentObject(Properties.shared)
    }
}

struct WelcomeTabBar: View {
    @Binding var count: Int
    var body: some View {
        HStack {
            Image(systemName: count == 1 ? "circlebadge.fill" : "circlebadge")
                .foregroundColor(Color.accentColor)
            Image(systemName: count == 2 ? "circlebadge.fill" : "circlebadge")
                .foregroundColor(Color.accentColor)
            Image(systemName: count == 3 ? "circlebadge.fill" : "circlebadge")
                .foregroundColor(Color.accentColor)
            Image(systemName: count == 4 ? "circlebadge.fill" : "circlebadge")
                .foregroundColor(Color.accentColor)
        }
        .offset(x: -35)
    }
}

struct WelcomeScreen: View {
    var info: Properties = Properties.shared
    @Binding var count: Int
    @Binding var firstLaunch: Bool
    @Binding var disableNext: Bool

    @Binding var xcodePermissionsReceived: Bool
    @Binding var eventsPermissionsReceived: Bool

    @State private var leftIsHovering: Bool = false
    @State private var rightIsHovering: Bool = false

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
                    .foregroundColor(count == 1 ? Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.1950796772)) : Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.4964300497)))
                    .background(
                        leftHover ? Color.gray.opacity(0.25) : Color.clear
                    )
                    .cornerRadius(10)
                    .onHover { active in
                        withAnimation {
                            leftIsHovering = active
                            leftHover = active && count != 1
                        }
                    }
                    .onTapGesture {
                        if count != 1 {
                            withAnimation {
                                count -= 1
                                leftHover = leftIsHovering && count != 1
                            }
                        }
                    }

                Spacer()

                WelcomeTabView(
                    count: $count,
                    firstLaunch: $firstLaunch,
                    geometry: geometry,
                    disableNext: $disableNext
                )

                Spacer()

                // Right arrow
                Image(systemName: "chevron.compact.right")
                    .scaleEffect(2)
                    .padding()
                    .foregroundColor(count == 4 || disableNext ? Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.1950796772)) : Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.4964300497)))
                    .background(
                        rightHover ? Color.gray.opacity(0.25) : Color.clear
                    )
                    .cornerRadius(10)
                    .onHover { active in
                        withAnimation {
                            rightIsHovering = active
                            rightHover = active && count != 4 && !disableNext
                        }
                    }
                    .onTapGesture {
                        if count != 4 && !disableNext {
                            withAnimation {
                                count += 1
                                rightHover = count != 4 && !disableNext
                            }
                        }
                    }
                    .onChange(of: disableNext) { _ in
                        withAnimation {
                            rightHover = rightIsHovering && count != 4 && !disableNext
                        }
                    }

                HStack {}
                    .padding(2.5)
            }
        }
    }
}

struct WelcomeTabView: View {
    @State var oldCount: Int = 1
    @Binding var count: Int
    @Binding var firstLaunch: Bool
    @Binding var disableNext: Bool
    @State var normalCount: Int
    let geometry: GeometryProxy

    @State var firstTabTransition: Edge = .leading
    @State var secondTabTransition: Edge = .trailing
    @State var thirdTabTransition: Edge = .trailing
    @State var fourthTabTransition: Edge = .leading

    @State var xcodePermissionsReceived = false
    @State var eventsPermissionsReceived = false

    init(count: Binding<Int>, firstLaunch: Binding<Bool>, geometry: GeometryProxy, disableNext: Binding<Bool>) {
        self._count = count
        self._normalCount = State(initialValue: 1)
        self._firstLaunch = firstLaunch
        self._disableNext = disableNext
        self.geometry = geometry

        self.normalCount = self.count
    }

    var body: some View {
        Group {
            if normalCount == 1 {
                VStack(alignment: .leading) {
                    HStack {
                        Image(named: "XcodeRPC")!
                            .resizable()
                            .frame(width: 80, height: 80)
                        VStack(alignment: .leading) {
                            Text("Welcome to XcodeRPC")
                                .font(.title)
                                .bold()
                            Text("made by atomtables")
                        }
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "person.2.circle.fill")
                                .font(.system(size: 48))
                                .padding(5)
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("Discord Rich Presence")
                                    .font(.title2)
                                    .bold()
                                Text("Save and display your activity in Xcode to all of your friends on Discord.")
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(width: 280)
                        }
                        HStack {
                            Image(systemName: "photo.artframe.circle.fill")
                                .font(.system(size: 48))
                                .padding(5)
                                .foregroundColor(.yellow)
                            VStack(alignment: .leading) {
                                Text("Custom App Icons")
                                    .font(.title2)
                                    .bold()
                                Text("Show off your app icons, which are uploaded and displayed on your profile.")
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(width: 280)
                        }
                        HStack {
                            Image(systemName: "hammer.circle.fill")
                                .font(.system(size: 48))
                                .padding(5)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("No Fiddling Required")
                                    .font(.title2)
                                    .bold()
                                Text("XcodeRPC works in the background, taking up " +
                                     "minimal system resources, hands-free.")
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(width: 280)
                        }
                    }
                }
                .transition(.move(edge: firstTabTransition))
            } else if normalCount == 2 {
                WelcomeRequestPermissionsView(
                    disableNext: $disableNext,
                    count: $count,
                    xcodePermissionsReceived: $xcodePermissionsReceived,
                    eventsPermissionsReceived: $eventsPermissionsReceived
                )
                .frame(width: geometry.size.width - 240)
                .transition(.move(edge: secondTabTransition))
            } else if normalCount == 3 {
                Text("To Be Implemented: Configure how you want your RPC to show up")
                    .transition(.move(edge: thirdTabTransition))
            } else if normalCount == 4 {
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
                    Text("If you like this project, give it a star on GitHub!")
                    Button("Begin...") {
                        UserDefaults.standard.set(true, forKey: "FirstLaunchFinished")
                        delegate.hideWelcomeWindow()
                    }
                }
                .transition(.move(edge: fourthTabTransition))
            }
        }
        .frame(width: geometry.size.width-120, height: geometry.size.height)
        //        .frame(width: geometry.size.width, height: geometry.size.height)
        .onChange(of: count) { new in
            let old = oldCount
            /// We are going backwards
            if old - new == 1 {
                switch old {
                case 2:
                    self.disableNext = false
                    firstTabTransition = .leading
                    secondTabTransition = .trailing
                case 3:
                    secondTabTransition = .leading
                    thirdTabTransition = .trailing
                case 4:
                    self.disableNext = false
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
                    self.disableNext = false
                    secondTabTransition = .leading
                    thirdTabTransition = .trailing
                case 3:
                    self.disableNext = false
                    thirdTabTransition = .leading
                    fourthTabTransition = .trailing
                default: break
                }
            }
            withAnimation {
                normalCount = new
            }
            oldCount = new
        }
    }
}
