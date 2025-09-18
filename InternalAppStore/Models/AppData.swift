//
//  AppData.swift
//  InternalAppStore
//
//  Created by Tariq AlMazyad on 18/09/2025.
//



import Foundation

struct AppData: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    var versions: [AppDataVersion]
}

struct AppDataVersion: Identifiable, Codable, Hashable {
    var id: String { "\(appName)-\(version)" }

    let manifestURL: URL?
    let imageName: String?
    let appName: String
    let version: String
    let build: String?
    let description: String?
    let timestamp: Date?

    // Decoded manifest (standalone type below)
    var manifest: Manifest?

    // Convenience accessors sourced from the manifest
    var ipaDirectURL: URL? {
        guard let firstItem = manifest?.items.first,
              let packageAsset = firstItem.assets.first(where: { $0.kind == "software-package" }),
              let urlString = packageAsset.url
        else { return nil }
        return URL(string: urlString)
    }

    var displayImageURL: URL? {
        guard let firstItem = manifest?.items.first,
              let imageAsset = firstItem.assets.first(where: { $0.kind == "display-image" }),
              let urlString = imageAsset.url
        else { return nil }
        return URL(string: urlString)
    }

    var fullSizeImageURL: URL? {
        guard let firstItem = manifest?.items.first,
              let imageAsset = firstItem.assets.first(where: { $0.kind == "full-size-image" }),
              let urlString = imageAsset.url
        else { return nil }
        return URL(string: urlString)
    }

    var bundleIdentifier: String? { manifest?.items.first?.metadata.bundleIdentifier }
    var bundleVersion: String?    { manifest?.items.first?.metadata.bundleVersion }
    var titleFromManifest: String? { manifest?.items.first?.metadata.title }
}

// MARK: - Manifest (each type separate)

struct Manifest: Codable, Hashable {
    let items: [ManifestItem]
}

struct ManifestItem: Codable, Hashable {
    let assets: [ManifestAsset]
    let metadata: ManifestMetadata
}

struct ManifestAsset: Codable, Hashable {
    let kind: String
    let url: String?
    let needsShine: Bool?

    enum CodingKeys: String, CodingKey {
        case kind
        case url
        case needsShine = "needs-shine"
    }
}

struct ManifestMetadata: Codable, Hashable {
    let bundleIdentifier: String
    let bundleVersion: String
    let kind: String?
    let platformIdentifier: String?
    let title: String?
    let description: String?   

    enum CodingKeys: String, CodingKey {
        case bundleIdentifier   = "bundle-identifier"
        case bundleVersion      = "bundle-version"
        case kind
        case platformIdentifier = "platform-identifier"
        case title
        case description        = "description"  
    }
}

