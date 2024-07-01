//
//  Structures.swift
//  XcodeRPC
//
//  Created by Adithiya Venkatakrishnan on 29/06/2024.
//
import Foundation

struct ImageSetStructure: Codable {
    let images: [ImageSetNames]
}

struct ImageSetNames: Codable {
    let filename: String?
    let idiom: String
    let scale: String?
    let size: String
}

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
