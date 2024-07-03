//
//  ContentView.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 29/06/2024.
//

import SwiftUI
import SwordRPC

struct ContentView: View {
    @EnvironmentObject var info: Properties

    @State var showAlert = false
    @State var disableConnectionButton = true

    var body: some View {
        if let workspace = info.workspace {
            Text(URL(fileURLWithPath: workspace).lastPathComponent)
        }
        if let target = info.target {
            Text(target)
        }
        if let currentFile = info.currentFile {
            Text(currentFile)
        }
        Divider()
        Text("Status: \(info.connected ? "Connected" : "Disconnected")")
        if !info.connected {
            Button("Connect RPC \(disableConnectionButton ? "(Xcode is not active)" : "")") {
                DONOTCONNECT = false
                connectRPC()
                if !info.connected {
                    showAlert = true
                }
            }
            .disabled(disableConnectionButton)
            .task {
                for app in NSWorkspace.shared.runningApplications {
                    if app.bundleIdentifier == "com.apple.dt.Xcode" {
                        disableConnectionButton = false
                        break
                    }
                    disableConnectionButton = true
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Failed to connect. Check if Discord is open, or check the console for info."))
            }
        } else {
            Button("Disconnect RPC") {
                DONOTCONNECT = true
                disconnectRPC()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Failed to connect. Check if Discord is open, or check the console for info."))
            }
        }
        Button("Invalidate Icon Cache") {
            let alert = NSAlert()
            alert.messageText = "Invalidate Icon Cache"
            // swiftlint:disable:next line_length
            alert.informativeText = "All icons will be removed for all applications. This action is irreversible. Are you sure?"
            alert.alertStyle = .warning

            // Add buttons
            alert.addButton(withTitle: "Yes")
            alert.addButton(withTitle: "No")

            // Show the alert
            let response = alert.runModal()

            // Handle the response
            switch response {
            case .alertFirstButtonReturn:
                let domain = Bundle.main.bundleIdentifier!
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()
            case .alertSecondButtonReturn:
                break
            default:
                break
            }
        }
        Divider()
        Button("Quit") {
            disconnectRPC()
            NSApp.terminate(nil)
        }
    }
}
