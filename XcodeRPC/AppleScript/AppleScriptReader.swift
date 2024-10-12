//
//  AppleScriptReader.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 11/10/2024.
//

import Cocoa
import Foundation

func runAppleScript(script: String) -> String? {
    // Create an NSAppleScript instance with the provided script
    let appleScript = NSAppleScript.init(source: script)

    // Execute the AppleScript and get the result
    var error: NSDictionary?
    if let result = appleScript?.executeAndReturnError(&error) {
        return result.stringValue
    } else if let error = error {
        NSLog("AppleScript execution error: \(error["NSAppleScriptErrorMessage"] ?? "some error")")
    }

    return nil
}

func readAppleScriptStringList(_ event: NSAppleEventDescriptor?) -> [String]? {
    if let event, event.numberOfItems > 0 {
        var retval: [String] = []
        for index in 1...event.numberOfItems {
            retval.append(event.atIndex(index)!.stringValue!)
        }
        return retval
    }
    return nil
}

func runCombinedMainAppleScript() throws(XRPCError)
            -> (String?, String?, String?, [String]?) {
    let appleScript = NSAppleScript.init(source: getAllAppleScript)
    var error: NSDictionary?
    let result = appleScript?.executeAndReturnError(&error)
    if let result {
        let target = result.atIndex(1)?.stringValue
        let workspace = result.atIndex(2)?.stringValue
        let file = result.atIndex(3)?.stringValue
        let sources = readAppleScriptStringList(result.atIndex(4))
        return (target, workspace, file, sources)
    } else {
        NSLog("AppleScript execution error: \(error?["NSAppleScriptErrorMessage"] ?? "(an unknown error occured)")")
        throw XRPCError.error(
            "AppleScript execution error: \(error?["NSAppleScriptErrorMessage"] ?? "(an unknown error occured)")"
        )
    }
}
