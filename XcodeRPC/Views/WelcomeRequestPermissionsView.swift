//
//  WelcomeRequestPermissionsView.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 16/10/2024.
//

import SwiftUI

struct WelcomeRequestPermissionsView: View {
    @Binding var disableNext: Bool
    @Binding var count: Int

    @Binding var xcodePermissionsReceived: Bool
    @Binding var eventsPermissionsReceived: Bool

    var body: some View {
        return VStack {
            Text("Permissions").font(.largeTitle)
                .onChange(of: xcodePermissionsReceived) { new in
                    disableNext = !(new && eventsPermissionsReceived)
                }
                .onChange(of: eventsPermissionsReceived) { new in
                    disableNext = !(new && xcodePermissionsReceived)
                }
                .onChange(of: count) { _ in
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
                    .font(.system(size: 40))
                    .padding(.top)
                    .padding(.horizontal, 5)
                    .padding(.bottom, 10)
                VStack(alignment: .leading) {
                    Text("Xcode")
                        .bold()
                        .font(.title2)
                    Text(
                        "Grant permission for XcodeRPC to " +
                        "use AppleScript to see your activity in Xcode. " +
                        "Xcode may open."
                    )
                    .frame(width: 350, height: nil, alignment: .leading)
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
                .padding(.leading, 10)
            }
            Divider()
            HStack {
                Image(systemName: "eye.circle.fill")
                    .font(.system(size: 40))
                    .padding(.top)
                    .padding(.horizontal, 5)
                    .padding(.bottom, 10)
                VStack(alignment: .leading) {
                    Text("System Events")
                        .bold()
                        .font(.title2)
                    Text("Grant permission for XcodeRPC to access " +
                         "System Events to see when Xcode is running. " +
                         "This will be used to only make sure Xcode is active."
                    )
                    .frame(width: 350, height: nil, alignment: .leading)
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
                .padding(.leading, 10)
            }
            Divider()
            HStack {
                VStack {
                    Image(systemName: "folder.circle.fill")
                        .font(.system(size: 40))
                        .padding([.top, .horizontal])
                        .padding(.bottom, 5)
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
                        .font(.system(size: 40))
                        .padding([.top, .horizontal])
                        .padding(.bottom, 5)
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
