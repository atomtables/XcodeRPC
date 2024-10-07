//
//  main.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 6/10/2024.
//

/// This file is the entrypoint of the application.
/// Conversion to AppKit, primarily.

import AppKit

print("running entrypoint of application")

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
