//
//  AppleScripts.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 30/06/2024.
//

let getTargetScript = """
tell application "Xcode"
    tell active workspace document
        get name of (get first target of (get first project))
    end tell
end tell
"""

let getWorkspaceScript = """
tell application "Xcode"
    tell active workspace document
        path
    end tell
end tell
"""

let getFileScript = """
tell application "Xcode-beta"
    set last_word to (word -1 of (get name of window 1))
    if (last_word = "Edited") then
        name of document 1 whose name ends with (word -2 of (get name of window 1))
    else
        name of document 1 whose name ends with (word -1 of (get name of window 1))
    end if
end tell
"""
