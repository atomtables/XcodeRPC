//
//  Functions.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 30/06/2024.
//
import Foundation

func FindIcon(workspace: URL) -> URL? {
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

func UploadIcon(path: URL?, workspace: URL) async -> String {
    if let x = UserDefaults.standard.object(forKey: workspace.absoluteString) as? String {
        var y = true
        checkWebsite(urlString: x) { exists in
            if !exists {
                NSLog("Website does not exist.")
                y = false
            }
        }
        if y {
            return x
        }
    }

    guard let path else {
        return "default_app_icon"
    }

    do {
        var multipart = MultipartRequest()
        let file = try Data(contentsOf: path)

        multipart.add(
            key: "image",
            fileName: path.lastPathComponent,
            fileMimeType: "image/png",
            fileData: file
        )
        multipart.add(key: "type", value: "image")
        multipart.add(key: "title", value: path.lastPathComponent)
        multipart.add(key: "description", value: path.lastPathComponent)

        /// Create a regular HTTP URL request & use multipart components
        let url = URL(string: "https://api.imgur.com/3/image")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(multipart.httpContentTypeHeadeValue, forHTTPHeaderField: "Content-Type")
        request.setValue("Client-ID \(CLIENT_ID)", forHTTPHeaderField: "Authorization")
        request.httpBody = multipart.httpBody

        /// Fire the request using URL sesson or anything else...
        let (data, _) = try await URLSession.shared.data(for: request)
        let d = try JSONDecoder().decode(ImgurUploadResponse.self, from: data)
        if d.success {
            if let link = d.data?.link {
                UserDefaults.standard.set(
                    link,
                    forKey: workspace.absoluteString
                )
                UserDefaults.standard.synchronize()
                return link
            }
            return "default_app_icon"
        } else {
            return "default_app_icon"
        }
    } catch {
        NSLog("There was an error: \(error).")
        return "default_app_icon"
    }
}

func GetDataResponse(for request: URLRequest) throws -> (Data, URLResponse) {
    var error: (any Error)?
    var (d, rs): (Data, URLResponse) = (Data(), URLResponse())
    URLSession.shared.dataTask(with: request) { data, response, e in
        if let e {
            error = e
        }
        d = data!
        rs = response!
    }
    if let error {
        throw error
    }
    return (d, rs)
}

func RunAppleScript(script: String) -> String? {
    // Create an NSAppleScript instance with the provided script
    let appleScript = NSAppleScript(source: script)

    // Execute the AppleScript and get the result
    var error: NSDictionary?
    if let result = appleScript?.executeAndReturnError(&error) {
        return result.stringValue
    } else if let error = error {
        NSLog("AppleScript execution error: \(error["NSAppleScriptErrorMessage"] ?? "some error")")
    }

    return nil
}

func GetFileExtension(file: URL) -> String {
    let ex = file.pathExtension

    switch ex {
    case "c":
        return "c"
    case "xcdatamodel":
        return "coredata"
    case "xcdatamodeld":
        return "coredata"
    case "cpp":
        return "cpp"
    case "exp":
        return "exp"
    case "h":
        return "header"
    case "metal":
        return "metal"
    case "nib":
        return "nib"
    case "m":
        return "objc"
    case "plist":
        return "plist"
    case "r":
        return "rez"
    case "rb":
        return "ruby"
    case "storyboard":
        return "storyboard"
    case "swift":
        return "swift"
    case "xcodeproj":
        return "xcodeproj"
    case "xcworkspace":
        return "xcworkspace"
    case "xib":
        return "xib"
    case "y":
        return "yacc"
    case "entitlements":
        return "entitlement"
    default:
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
