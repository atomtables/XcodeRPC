//
//  XcodeRPCApp.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 29/06/2024.
//

import SwiftUI

@main
struct XcodeRPCApp: App {
    @StateObject var info = Properties.shared

    init() {
        RPCEventHandlers()
        DispatchQueue.main.async {
            Properties.shared.tick = !Properties.shared.tick
            Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
                Properties.shared.tick.toggle()
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

