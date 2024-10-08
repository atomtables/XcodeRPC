//
//  Functions.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 30/06/2024.
//
import Foundation

func findIcon(workspace: URL) -> URL? {
    var name = workspace.lastPathComponent
    name = String(name.prefix(name.count - 10))
    var workspace = workspace.deletingLastPathComponent()
    workspace = workspace.appendingPathComponent(name)
    workspace = workspace.appendingPathComponent("Assets.xcassets")
    workspace = workspace.appendingPathComponent("AppIcon.appiconset")

    let appIconSet = workspace.appendingPathComponent("Contents.json")
    let appIcons: [ImageSetNames]
    do {
        appIcons = try JSONDecoder()
            .decode(
                ImageSetStructure.self,
                from: try Data(contentsOf: appIconSet)
            )
            .images
    } catch {
        NSLog("Error decoding: \(error)")
        return nil
    }
    let macmasicon = appIcons.first {
        $0.idiom == "mac" && $0.scale == "2x" && $0.size == "512x512"
    }
    if let macmasicon, let filename = macmasicon.filename {
        return workspace.appendingPathComponent(filename)
    } else {
        let icon = appIcons.first {
            $0.size == "1024x1024" || ($0.size == "512x512" && $0.scale == "2x")
        }
        if let icon, let filename = icon.filename {
            return workspace.appendingPathComponent(filename)
        } else {
            let icon = appIcons.first {
                $0.size == "512x512" || ($0.size == "256x256" && $0.scale == "2x")
            }
            if let icon, let filename = icon.filename {
                return workspace.appendingPathComponent(filename)
            } else {
                return nil // atp not worth it
            }
        }
    }
}

// swiftlint:disable:next function_body_length
func uploadIcon(path: URL?, workspace: URL, completion: @escaping (String) -> Void) {
    if let url = UserDefaults.standard.object(forKey: workspace.absoluteString) as? String {
        var valid = true
        checkWebsite(urlString: url) { exists in
            if !exists {
                NSLog("Website does not exist.")
                valid = false
            }
        }
        NSLog("collected from cache")
        if valid {completion(url)}
        return
    }

    guard let path else {
        completion("default_app_icon")
        return
    }

    do {
        var multipart = MultipartRequest()
        let file = try Data(contentsOf: path)

        multipart.add(
            key: "image", fileName: path.lastPathComponent,
            fileMimeType: "image/png", fileData: file
        )
        multipart.add(key: "type", value: "image")
        multipart.add(key: "title", value: path.lastPathComponent)
        multipart.add(key: "description", value: path.lastPathComponent)

        /// Create a regular HTTP URL request & use multipart components
        let url = URL(string: "https://api.imgur.com/3/image")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(multipart.httpContentTypeHeadeValue, forHTTPHeaderField: "Content-Type")
        request.setValue("Client-ID \(CLIENTID)", forHTTPHeaderField: "Authorization")
        request.httpBody = multipart.httpBody

        /// Fire the request using URL sesson or anything else...
        URLSession.shared.dataTask(with: request) { data, _, error in
            if error != nil {
                completion("default_app_icon")
            }
            do {
                let decoded = try JSONDecoder().decode(ImgurUploadResponse.self, from: data ?? Data())
                if decoded.success {
                    if let link = decoded.data?.link {
                        UserDefaults.standard.set(
                            link, forKey: workspace.absoluteString
                        ); UserDefaults.standard.synchronize()
                        NSLog("uploaded to imgur")
                        completion(link)
                    }
                    completion("default_app_icon")
                } else {
                    completion("default_app_icon")
                }
            } catch {
                completion("default_app_icon")
            }
        }.resume()
    } catch {
        NSLog("There was an error: \(error).")
        completion("default_app_icon")
    }
}

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

func getFileExtension(file: URL) -> String {
    let ext = file.pathExtension

    switch ext {
    case "xcdatamodel":
        return "coredata"
    case "xcdatamodeld":
        return "coredata"
    case "h":
        return "header"
    case "m":
        return "objc"
    case "r":
        return "rez"
    case "rb":
        return "ruby"
    case "y":
        return "yacc"
    case "entitlements":
        return "entitlement"
    default:
        if ["c", "cpp", "exp",
            "metal", "nib", "plist",
            "storyboard", "swift",
            "xcodeproj", "xcworkspace", "xib"]
            .contains(where: {$0 == ext}) {
            return ext
        }
        return "empty"
    }
}

func checkWebsite(urlString: String, completion: @escaping (Bool) -> Void) {
    // Ensure the URL is valid
    guard let url = URL(string: urlString) else {
        completion(false)
        return
    }

    let lastDoub = UserDefaults.standard.object(forKey: urlString) as? Double

    if let lastDoub {
        let lastCheck = Date(timeIntervalSince1970: lastDoub)

        let components = Calendar.current.dateComponents([.day], from: lastCheck, to: Date())

        if let days = components.day, days >= 1 {
            completion(true)
        }
    }

    // Create a URL session data task
    let task = URLSession.shared.dataTask(with: url) { _, response, error in
        if let error = error {
            NSLog("Error: \(error.localizedDescription)")
            completion(false)
            return
        }

        if let httpResponse = response as? HTTPURLResponse {
            // Check for a successful HTTP status code (200–299)
            if (200...299).contains(httpResponse.statusCode) {
                UserDefaults.standard.setValue(Date().timeIntervalSince1970, forKey: urlString)
                UserDefaults.standard.synchronize()
                completion(true)
            } else {
                completion(false)
            }

        } else {
            completion(false)
        }
    }

    // Start the data task
    task.resume()
}

typealias Opt = Optional

func readAppleScriptStringList(_ event: NSAppleEventDescriptor?) -> [String]? {
    if let event {
        var retval: [String] = []
        guard let count = Opt(event.numberOfItems), count > 0 else {
            return nil
        }
        for index in 1...count {
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
