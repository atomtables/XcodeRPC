//
//  ImgurUploadExtras.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 11/10/2024.
//

import Foundation

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
