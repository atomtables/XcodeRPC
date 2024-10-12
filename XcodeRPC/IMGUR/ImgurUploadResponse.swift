//
//  ImgurUploadResponse.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 11/10/2024.
//

import Foundation

struct ImgurUploadResponse: Codable {
    let status: Int
    let success: Bool
    let data: ImgurUploadResponseStructure?
}

struct ImgurUploadResponseStructure: Codable {
    let id: String
    let link: String
    var linkUrl: URL {URL(string: link)!}
}
