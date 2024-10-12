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

enum XRPCError: Error {
    case error(String)
}
