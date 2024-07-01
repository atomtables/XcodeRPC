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
            Button("Connect RPC") {
                info.connecting = true
                let _ = rpc.connect()
                if !info.connected {
                    showAlert = true
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Failed to connect. Check if Discord is open, or check the console for info."))
            }
        } else {
            Button("Disconnect RPC") {
                rpc.disconnect()
                info.workspace = nil
                info.target = nil
                info.currentFile = nil
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Failed to connect. Check if Discord is open, or check the console for info."))
            }
        }
        Divider()
        Button("Quit") {
            exit(0)
        }
    }
}
