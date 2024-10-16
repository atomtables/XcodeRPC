//
//  Data+MultipartRequest.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 29/06/2024.
//

import Cocoa
import SwiftUI
import SwordRPC

public extension Data {
    mutating func append(
        _ string: String,
        encoding: String.Encoding = .utf8
    ) {
        guard let data = string.data(using: encoding) else {
            return
        }
        append(data)
    }
}

extension RichPresence {
    init(start: Date = Date()) {
        self.init()
        self.timestamps.start = start
    }
}

extension URL {
    init(file: String) {
        self.init(fileURLWithPath: file)
    }
}

extension NSMenuItem {
    convenience init(title: String, target: NSApplicationDelegate, action: Selector) {
        self.init()
        self.title = title
        self.target = target
        self.action = action
    }
}

extension NSMenuItem {
    convenience init(_ title: String) {
        self.init()
        self.title = title
    }

    func setTitle(_ title: String) -> NSMenuItem {
        self.title = title
        return self
    }

    func setEnabled(_ enabled: Bool) -> NSMenuItem {
        self.isEnabled = enabled
        return self
    }

    func setVisibility(_ hidden: Bool) -> NSMenuItem {
        self.isHidden = !hidden
        return self
    }

    func setAction(_ action: Selector, target: AnyObject) -> NSMenuItem {
        self.isEnabled = true
        self.action = action
        self.target = target
        return self
    }

    func appendTo(_ list: inout [NSMenuItem]) {
        list.append(self)
    }
}

extension Image {
    init?(named: String) {
        if let image = NSImage(named: named) {
            self.init(nsImage: image)
        } else {
            return nil
        }
    }
}
