//
//  AppDelegate.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 02/07/2024.
//

import Cocoa
import Foundation
import SwordRPC

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let shouldStartRPC = UserDefaults.standard.bool(forKey: "StartRPCOnLaunchOfApp")
        if shouldStartRPC {
            connectRPC()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        disconnectRPC()
    }

}
