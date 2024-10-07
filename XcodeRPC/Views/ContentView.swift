//
//  ContentView.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 29/06/2024.
//

import SwiftUI
import SwordRPC

/// `ContentView` is the app's main menu extra view.
struct ContentView: View {
    @EnvironmentObject var info: Properties

    @State var showAlert = false
    var disableConnectionButton: Bool { !xcodeRunning || !discordRunning }

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
        Text("Status: \(info.connected ? "Connected" : info.connecting ? "Connecting..." : "Disconnected")")
        if !info.connected {
            Button("Connect RPC") {
                connectRPC()
            }
            .onAppear {
                for app in NSWorkspace.shared.runningApplications {
                    if app.bundleIdentifier == "com.apple.dt.Xcode" {
                        xcodeRunning = true
                    } else if app.bundleIdentifier == "com.hnc.Discord" {
                        discordRunning = true
                    }
                }
            }
            .disabled(disableConnectionButton)
            if !discordRunning || !xcodeRunning {
                Text("Run Xcode/Discord to connect...")
            }
        } else {
            Button("Disconnect RPC") {
                disconnectRPC()
            }
        }
        Button("Invalidate Icon Cache") {
            let alert = NSAlert()
            alert.messageText = "Invalidate Icon Cache"
            alert.informativeText = "All icons will be removed for all applications. "
            alert.informativeText += "This action is irreversible. Are you sure?"
            alert.alertStyle = .warning

            alert.addButton(withTitle: "Yes")
            alert.addButton(withTitle: "No")

            let response = alert.runModal()

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
        Button("Launch on Startup") {}
            .disabled(true)
        Divider()
        Button("Quit") {
            disconnectRPC()
            NSApp.terminate(nil)
        }
    }
}
