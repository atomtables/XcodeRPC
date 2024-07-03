//
//  AppleScripts.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 30/06/2024.
//

let quitXcodeScript = """
ignoring application responses
    tell application "Xcode" to quit
end ignoring
"""

let getTargetScript = """
tell application "System Events"
    set isRunning to (name of processes) contains "Xcode"
end tell

if isRunning
    tell application "Xcode"
        tell active workspace document
            get name of (get first target of (get first project))
        end tell
    end tell
end if
"""

let getWorkspaceScript = """
tell application "System Events"
    set isRunning to (name of processes) contains "Xcode"
end tell

if isRunning
    tell application "Xcode"
        tell active workspace document
            path
        end tell
    end tell
end if
"""

let getFileScript = """
tell application "System Events"
    set isRunning to (name of processes) contains "Xcode"
end tell

if isRunning
    tell application "Xcode"
        set last_word to (word -1 of (get name of window 1))
        if (last_word = "Edited") then
            name of document 1 whose name ends with (word -2 of (get name of window 1))
        else
            name of document 1 whose name ends with (word -1 of (get name of window 1))
        end if
    end tell
end if
"""

/// Only returns the first document, since more than
/// one document seems to make it mad. If one source
/// document is open, we are probably good.
let getSourcesScript = """
tell application "System Events"
    set isRunning to (name of processes) contains "Xcode"
end tell

if isRunning
    tell application "Xcode"
        return name of first source document
    end tell
end if
"""
