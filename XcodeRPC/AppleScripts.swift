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

let testXcodeScript = """
tell application "Xcode"
    tell active workspace document
        get path
    end tell
    return version
end tell
"""

let testEventsScript = """
tell application "System Events"
    set isRunning to (name of processes) contains "Xcode"
    return isRunning
end tell
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

/// A more efficient method would be to
/// just call all 4 scripts in 1 script, as we would only need to check
/// System Events once afaik.
///
/// Also, if window name source is not in open source
let getAllAppleScript = """
tell application "System Events"
    set isRunning to (name of processes) contains "Xcode"
end tell

set xtarget to ""
set xworkspace to ""
set xfile to ""
set xsources to {}

if isRunning then
    tell application "Xcode"
        tell active workspace document
            try
                set xtarget to name of (get first target of (get first project))
            on error errorMessage number errorNumber
                set xtarget to null
            end try
        end tell
        tell active workspace document
            try
                set xworkspace to path
            on error errorMessage number errorNumber
                set xworkspace to null
            end try
        end tell
        try
            set last_word to (word -1 of (get name of window 1))
            if (last_word = "Edited") then
                set xfile to name of document 1 whose name ends with (word -2 of (get name of window 1))
            else
                set xfile to name of document 1 whose name ends with (word -1 of (get name of window 1))
            end if
        on error errorMessage number errorNumber
            set xfile to null
        end try
        try
            set xsources to the path of documents 2 thru -1
        on error errorMessage number errorNumber
            set xsources to null
        end try
        return {xworkspace, xtarget, xfile, xsources}
    end tell
end if
"""
