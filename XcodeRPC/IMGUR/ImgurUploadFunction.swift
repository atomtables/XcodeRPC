//
//  ImageUpload.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 11/10/2024.
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
                NSLog("The current cached AppIcon does not exist.")
                valid = false
            }
        }
        NSLog("Collected the AppIcon from cache")
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
                        NSLog("Uploaded AppIcon to IMGur")
                        completion(link)
                        return
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
        NSLog("There was an error uploading to IMGur: \(error).")
        completion("default_app_icon")
    }
}
