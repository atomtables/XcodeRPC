//
//  Properties.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 11/10/2024.
//

import Cocoa
import Foundation
import SwiftUI

public final class Properties: ObservableObject {
    static var shared: Properties = Properties()

    private init() {}

    @Published var workspace: String? {
        didSet {
            delegate.menu.updateWorkspace()
        }
    }
    @Published var target: String? {
        didSet {
            delegate.menu.updateTarget()
        }
    }
    @Published var currentFile: String? {
        didSet {
            delegate.menu.updateCurrentFile()
        }
    }

    @Published var tick = false {
        didSet {
            if connecting {
                if tick {
                    delegate.statusBarItem.button?
                        .image = NSImage(systemSymbolName: "hammer.fill", accessibilityDescription: nil)
                } else {
                    delegate.statusBarItem.button?
                        .image = NSImage(systemSymbolName: "hammer", accessibilityDescription: nil)
                }
            } else if connected {
                delegate.statusBarItem.button?
                    .image = NSImage(systemSymbolName: "hammer.fill", accessibilityDescription: nil)
            } else {
                delegate.statusBarItem.button?
                    .image = NSImage(systemSymbolName: "hammer", accessibilityDescription: nil)
            }
        }
    }

    @Published var connecting: Bool = false {
        didSet {
            delegate.menu.updateStatus()
            delegate.menu.updateConnectDisconnect()
        }
    }
    @Published var connected: Bool = false {
        didSet {
            delegate.menu.updateStatus()
            delegate.menu.updateConnectDisconnect()
        }
    }

    @Published var beginningScrollView: ScrollViewProxy!
}
