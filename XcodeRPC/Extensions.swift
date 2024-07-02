//
//  Data+MultipartRequest.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 29/06/2024.
//

import Foundation
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
