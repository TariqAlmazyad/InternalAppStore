//
//  MockData.swift
//  InternalAppStore
//
//  Created by Tariq AlMazyad on 18/09/2025.
//

import Foundation

enum MockData {
    static let mockAppName: String = "EduConnect"
    static let mockBundleIdentifier: String = "com.educonnect.app"
    static let mockDisplayImageURLString: String = "https://via.placeholder.com/128.png"
    static let mockIpaURLStringBase: String = "https://example.com/downloads"

    // 6 versions total: v1.0.5 (latest) down to v1.0.0 (previous x5)
    static let mockAppData: AppData = {
        let versions: [AppDataVersion] = [
            makeMockVersion(versionString: "v1.0.5", daysAgo: 0,  description: "Latest build with performance improvements and bug fixes."),
            makeMockVersion(versionString: "v1.0.4", daysAgo: 3,  description: "Minor fixes and UI polish."),
            makeMockVersion(versionString: "v1.0.3", daysAgo: 7,  description: "Stability improvements."),
            makeMockVersion(versionString: "v1.0.2", daysAgo: 14, description: "Feature tweaks and minor bug fixes."),
            makeMockVersion(versionString: "v1.0.1", daysAgo: 21, description: "Hotfix for install prompt."),
            makeMockVersion(versionString: "v1.0.0", daysAgo: 30, description: "Initial public build.")
        ]
        return AppData(id: mockAppName, name: mockAppName, versions: versions)
    }()

    static func makeMockVersion(versionString: String, daysAgo: Int, description: String) -> AppDataVersion {
        // Assets
        let displayImageAsset = ManifestAsset(
            kind: "display-image",
            url: mockDisplayImageURLString,
            needsShine: true
        )
        let fullSizeImageAsset = ManifestAsset(
            kind: "full-size-image",
            url: mockDisplayImageURLString,
            needsShine: true
        )
        let softwarePackageAsset = ManifestAsset(
            kind: "software-package",
            url: "\(mockIpaURLStringBase)/EduConnect-\(versionString).ipa",
            needsShine: nil
        )

        // Metadata
        let manifestMetadata = ManifestMetadata(
            bundleIdentifier: mockBundleIdentifier,
            bundleVersion: String(versionString.dropFirst()), // e.g., "1.0.5"
            kind: "software",
            platformIdentifier: "com.apple.platform.iphoneos",
            title: mockAppName,
            description: ""
        )

        // Item and Manifest
        let manifestItem = ManifestItem(
            assets: [softwarePackageAsset, displayImageAsset, fullSizeImageAsset],
            metadata: manifestMetadata
        )
        let manifest = Manifest(items: [manifestItem])

        // A plausible manifest download URL (used to build itms-services in UI)
        let manifestURL = URL(string: "https://example.com/manifests/\(versionString)/manifest.plist")

        // Timestamp relative to “now”
        let timestamp = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)

        return AppDataVersion(
            manifestURL: manifestURL,
            imageName: "icon.png",
            appName: mockAppName,
            version: versionString,
            build: nil,
            description: description,
            timestamp: timestamp,
            manifest: manifest
        )
    }
}
