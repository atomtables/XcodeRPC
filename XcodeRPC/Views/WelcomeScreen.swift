//
//  WelcomeScreen.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 5/10/2024.
//

import SwiftUI

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
        .offset(x: -35)
    }
}

struct WelcomeScreen: View {
    @EnvironmentObject var info: Properties
    @Binding var count: Int
    @Binding var firstLaunch: Bool
    @Binding var disableNext: Bool

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
                    .foregroundStyle(count == 4 || disableNext ? .quinary : .tertiary)
                    .background(
                        rightHover ? Color.gray.opacity(0.25) : Color.clear
                    )
                    .cornerRadius(10)
                    .onHover { active in
                        withAnimation {
                            rightHover = active && count != 4 && !disableNext
                        }
                    }
                    .onTapGesture {
                        if count != 4 && !disableNext {
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
                                .font(.largeTitle)
                                .padding([.top, .horizontal])
                                .padding(.bottom, 10)
                            Text("Save and display your activity in Xcode to all of your friends on Discord!")
                                .frame(width: 180)
                                .multilineTextAlignment(.center)
                        }
                        VStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.largeTitle)
                                .padding([.top, .horizontal])
                                .padding(.bottom, 10)
                            Text("Show off your icons, current open file, and workspace using Rich Presence!")
                                .frame(width: 180)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .transition(.move(edge: firstTabTransition))
            } else if normalCount == 2 {
                WelcomeRequestPermissionsView(
                    disableNext: $disableNext,
                    count: $count
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
                        firstLaunch = false
                        UserDefaults.standard.setValue(true, forKey: "FirstLaunchFinished")
                    }
                }
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
        }
    }
}

struct WelcomeRequestPermissionsView: View {
    @State var xcodePermissionsReceived: Bool = false
    @State var eventsPermissionsReceived: Bool = false
    @Binding var disableNext: Bool
    @Binding var count: Int

    var body: some View {
        return VStack {
            Text("Permissions").font(.largeTitle)
                .onChange(of: xcodePermissionsReceived) { _, new in
                    disableNext = !(new && eventsPermissionsReceived)
                }
                .onChange(of: eventsPermissionsReceived) { _, new in
                    disableNext = !(new && xcodePermissionsReceived)
                }
                .onChange(of: count) { _, _ in
                    print("its changing :skull:")
                    disableNext = !(xcodePermissionsReceived && eventsPermissionsReceived)
                }
                .onAppear {
                    disableNext = !(xcodePermissionsReceived && eventsPermissionsReceived)
                }
            Text("We need your permission to access your Xcode activity.")
                .font(.headline)
            Divider()
            HStack {
                Image(systemName: "hammer.circle.fill")
                    .font(.largeTitle)
                    .padding([.top, .horizontal])
                    .padding(.bottom, 10)
                VStack(alignment: .leading) {
                    Text("Xcode")
                        .bold()
                        .font(.title2)
                    Text(
                        "Grant permission for XcodeRPC to " +
                        "use AppleEvents to see your activity in Xcode. " +
                        "Xcode may open during this process."
                    )
                    .frame(width: 300, height: nil, alignment: .leading)
                    .multilineTextAlignment(.leading)
                }
                Spacer()
                Button {
                    let permission = runAppleScript(
                        script: testXcodeScript
                    )
                    if permission != nil {
                        xcodePermissionsReceived = true
                    }
                } label: {
                    Text(xcodePermissionsReceived ? "Permission Granted" : "Request Permission")
                        .font(.headline)
                        .foregroundColor(xcodePermissionsReceived ? .gray : .white)
                        .padding()
                        .frame(width: 200, height: 50)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                }
                .disabled(xcodePermissionsReceived)
            }
            Divider()
            HStack {
                Image(systemName: "eye.circle.fill")
                    .font(.largeTitle)
                    .padding([.top, .horizontal])
                    .padding(.bottom, 10)
                VStack(alignment: .leading) {
                    Text("System Events")
                        .bold()
                        .font(.title2)
                    Text("Grant permission for XcodeRPC to access " +
                         "System Events to see when Xcode is running. " +
                         "This will be used to only make sure Xcode is active."
                    )
                    .frame(width: 300, height: nil, alignment: .leading)
                    .multilineTextAlignment(.leading)
                }
                Spacer()
                Button {
                    let permission = runAppleScript(
                        script: testEventsScript
                    )
                    if permission != nil {
                        eventsPermissionsReceived = true
                    }
                } label: {
                    Text(eventsPermissionsReceived ? "Permission Granted" : "Request Permission")
                        .font(.headline)
                        .foregroundColor(eventsPermissionsReceived ? .gray : .white)
                        .padding()
                        .frame(width: 200, height: 50)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                }
                .disabled(eventsPermissionsReceived)
            }
            Divider()
            HStack {
                VStack {
                    Image(systemName: "folder.circle.fill")
                        .font(.largeTitle)
                        .padding([.top, .horizontal])
                        .padding(.bottom, 10)
                    VStack {
                        Text("Access to Files")
                            .bold()
                            .font(.title2)
                        Text("When you have a project open, XcodeRPC may request " +
                             "access to your folders. This is to use your app icons in " +
                             "Discord and is optional."
                        )
                        .frame(width: 300, height: nil, alignment: .leading)
                        .multilineTextAlignment(.center)
                    }
                }
                VStack {
                    Image(systemName: "folder.circle.fill")
                        .font(.largeTitle)
                        .padding([.top, .horizontal])
                        .padding(.bottom, 10)
                    VStack {
                        Text("Access to Discord")
                            .bold()
                            .font(.title2)
                        Text("XcodeRPC will connect to your Discord Client to set your " +
                             "activity while you are using Xcode. It can also optionally " +
                             "save your data locally."
                        )
                        .frame(width: 300, height: nil, alignment: .leading)
                        .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
}
