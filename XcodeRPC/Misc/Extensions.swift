//
//  Data+MultipartRequest.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 29/06/2024.
//

import Cocoa
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


enum XRPCError: Error {
    case error(String)
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
        self.action = action
        self.target = target
        return self
    }

    func appendTo(_ list: inout [NSMenuItem]) {
        list.append(self)
    }
}
