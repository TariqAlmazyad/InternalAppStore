//
//  FirebaseManager.swift
//  InternalAppStore
//
//  Created by Tariq AlMazyad on 18/09/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@Observable
final class FirebaseManager: NSObject {
    // Singleton
    static let shared = FirebaseManager()

    // Firebase services
    var firestore: Firestore
    var auth: Auth
    var storage: Storage

    // Public state for UI
    private(set) var appDataList: [AppData] = []

    // Configuration
    private let appsRootPath = "Apps"
    private let storageBucketURLString = "gs://internalappstore-4cd4d.firebasestorage.app"

    // MARK: - Init
    private override init() {
        print("🧩 FirebaseManager init")
        self.firestore = Firestore.firestore()
        self.auth = Auth.auth()
        self.storage = Storage.storage(url: storageBucketURLString) // explicit bucket
        super.init()

        Task {
            do {
                try await signInAnonymously()
                try await fetchAllApps()
            } catch {
                print("❌ Startup flow failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Auth

    func signInAnonymously() async throws {
        print("🔐 Signing in anonymously…")
        let result = try await auth.signInAnonymously()
        print("✅ Signed in. uid=\(result.user.uid)")
    }

    // MARK: - Public API

    /// Lists Apps/ -> builds all apps -> sorts -> publishes into appDataList.
    func fetchAllApps() async throws {
        print("📦 Using bucket: \(storageBucketURLString)")
        print("📁 Listing root path: \(appsRootPath)")

        let appsRootReference = storage.reference(withPath: appsRootPath)
        let appsRootListingResult = try await appsRootReference.listAll()

        print("🔎 Apps level: folders(prefixes)=\(appsRootListingResult.prefixes.count), files(items)=\(appsRootListingResult.items.count)")
        if !appsRootListingResult.items.isEmpty {
            for item in appsRootListingResult.items {
                print("   • Unexpected file at Apps level: \(item.fullPath)")
            }
        }
        if appsRootListingResult.prefixes.isEmpty {
            print("⚠️ No app folders found under '\(appsRootPath)'. Check path casing and Storage Rules.")
        } else {
            print("📚 App folders under \(appsRootPath):")
            for folder in appsRootListingResult.prefixes { print("   • \(folder.fullPath)") }
        }

        let appFolderReferences = appsRootListingResult.prefixes
        var localAppDataList: [AppData] = []

        // Sequential and simple for readability
        for appFolderReference in appFolderReferences {
            let appData = try await buildAppData(appFolderReference: appFolderReference)
            localAppDataList.append(appData)
        }

        // Sort versions (newest first) and apps (A→Z)
        for index in localAppDataList.indices {
            localAppDataList[index].versions.sort {
                semanticCompareVersions($0.version, $1.version) == .orderedDescending
            }
        }
        localAppDataList.sort {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        
        self.appDataList = localAppDataList
        
        print("✅ fetchAllApps completed. apps=\(localAppDataList.count)")
        for app in localAppDataList {
            print("   • \(app.name) — versions=\(app.versions.count)")
        }
    }

    // MARK: - Builders

    /// Builds a single AppData by listing version folders and building each version.
    func buildAppData(appFolderReference: StorageReference) async throws -> AppData {
        let appName = appFolderReference.name
        print("📁 Building AppData for folder: \(appFolderReference.fullPath) (name='\(appName)')")

        let versionLevelListingResult = try await appFolderReference.listAll()
        print("   ↳ versions: folders(prefixes)=\(versionLevelListingResult.prefixes.count), files(items)=\(versionLevelListingResult.items.count)")

        let versionFolderReferences = versionLevelListingResult.prefixes
        if versionFolderReferences.isEmpty {
            print("   ⚠️ No version folders found for \(appFolderReference.fullPath)")
        } else {
            for v in versionFolderReferences { print("     • Version folder: \(v.fullPath)") }
        }

        var appDataVersionList: [AppDataVersion] = []
        for versionFolderReference in versionFolderReferences {
            let version = try await buildAppDataVersion(appName: appName, versionFolderReference: versionFolderReference)
            appDataVersionList.append(version)
        }

        print("✅ Built AppData '\(appName)' with versions.count=\(appDataVersionList.count)")
        return AppData(id: appName, name: appName, versions: appDataVersionList)
    }

    /// Builds a single AppDataVersion by inspecting files inside a version folder.
    func buildAppDataVersion(appName: String, versionFolderReference: StorageReference) async throws -> AppDataVersion {
        let versionName = versionFolderReference.name
        print("   🔹 Building version at: \(versionFolderReference.fullPath) (version='\(versionName)')")

        let versionFolderListingResult = try await versionFolderReference.listAll()
        print("      ↳ files(items)=\(versionFolderListingResult.items.count)")
        if versionFolderListingResult.items.isEmpty {
            print("      ⚠️ No files inside version folder \(versionFolderReference.fullPath)")
        } else {
            for item in versionFolderListingResult.items {
                print("        • \(item.fullPath)")
            }
        }

        // Manifest URL (optional)
        let manifestFileReference = versionFolderListingResult.items.first { $0.name.lowercased() == "manifest.plist" }
        let manifestDownloadURL = try? await manifestFileReference?.downloadURL()
        if let manifestDownloadURL {
            print("      ✅ manifest.plist URL: \(manifestDownloadURL.absoluteString)")
        } else {
            print("      ⚠️ manifest.plist not found")
        }

        // Decode manifest (optional)
        let decodedManifest = try await fetchAndDecodeManifest(forVersionFolderReference: versionFolderReference)
        var resolvedDescriptionFromManifest: String? = nil
        if let decodedManifest {
            let metadata = decodedManifest.items.first?.metadata
            let title = metadata?.title ?? "n/a"
            let bundleIdentifier = metadata?.bundleIdentifier ?? "n/a"
            let bundleVersion = metadata?.bundleVersion ?? "n/a"
            resolvedDescriptionFromManifest = metadata?.description // 👈 pull custom description
            print("      ✅ Decoded manifest → title='\(title)', bundleIdentifier='\(bundleIdentifier)', bundleVersion='\(bundleVersion)'")
            if let d = resolvedDescriptionFromManifest, !d.isEmpty {
                print("      📝 Description from manifest: \(d)")
            } else {
                print("      ℹ️ No description found in manifest metadata")
            }
        } else {
            print("      ⚠️ Could not decode manifest (missing or invalid)")
        }

        // Choose an image file name if present
        let imageFileReference = versionFolderListingResult.items.first { fileReference in
            let lowercasedName = fileReference.name.lowercased()
            return lowercasedName.hasSuffix(".png")
                || lowercasedName.hasSuffix(".jpg")
                || lowercasedName.hasSuffix(".jpeg")
                || lowercasedName.hasSuffix(".webp")
        }
        let resolvedImageName = imageFileReference?.name
        if let resolvedImageName {
            print("      🖼️ Image found: \(resolvedImageName)")
        } else {
            print("      ⚠️ No image found in this version folder")
        }

        // Latest timestamp among files
        var latestUpdatedDate: Date? = nil
        for fileReference in versionFolderListingResult.items {
            if let metadata = try? await fileReference.getMetadata(),
               let updated = metadata.updated {
                if latestUpdatedDate == nil || updated > latestUpdatedDate! {
                    latestUpdatedDate = updated
                }
            }
        }
        if let latestUpdatedDate {
            print("      🕒 Latest updated date: \(latestUpdatedDate)")
        } else {
            print("      ⚠️ Could not determine latest updated date")
        }

        // Construct the version object (description filled from manifest if present)
        let appDataVersion = AppDataVersion(
            manifestURL: manifestDownloadURL,
            imageName: resolvedImageName,
            appName: appName,
            version: versionName,
            build: nil,
            description: resolvedDescriptionFromManifest, // 👈 now populated
            timestamp: latestUpdatedDate,
            manifest: decodedManifest
        )

        print("   ✅ Built AppDataVersion '\(appName) \(versionName)'")
        return appDataVersion
    }


    // MARK: - Manifest decoding

    func decodeManifestPlistData(_ plistData: Data) throws -> Manifest {
        print("      🔧 Decoding manifest.plist data (\(plistData.count) bytes)")
        let propertyListDecoder = PropertyListDecoder()
        let manifest = try propertyListDecoder.decode(Manifest.self, from: plistData)
        print("      🔧 Decoding complete")
        return manifest
    }

    func fetchAndDecodeManifest(forVersionFolderReference versionFolderReference: StorageReference) async throws -> Manifest? {
        let listing = try await versionFolderReference.listAll()
        guard let manifestFileReference = listing.items.first(where: { $0.name.lowercased() == "manifest.plist" }) else {
            print("      ℹ️ fetchAndDecodeManifest: manifest.plist not present")
            return nil
        }
        let maximumDownloadSizeInBytes: Int64 = 2 * 1024 * 1024
        do {
            let plistData = try await manifestFileReference.data(maxSize: maximumDownloadSizeInBytes)
            return try decodeManifestPlistData(plistData)
        } catch {
            print("      ❌ fetchAndDecodeManifest failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Version comparison

    func semanticCompareVersions(_ firstVersion: String, _ secondVersion: String) -> ComparisonResult {
        // Normalize (strip leading "v", spaces, lowercase)
        let normalizedFirst = firstVersion.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "v", with: "")
        let normalizedSecond = secondVersion.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "v", with: "")

        // Split into integer components
        let firstParts = normalizedFirst.split(separator: ".").compactMap { Int($0) }
        let secondParts = normalizedSecond.split(separator: ".").compactMap { Int($0) }
        let count = max(firstParts.count, secondParts.count)

        for index in 0..<count {
            let x = index < firstParts.count ? firstParts[index] : 0
            let y = index < secondParts.count ? secondParts[index] : 0
            if x < y { return .orderedAscending }
            if x > y { return .orderedDescending }
        }
        // If equal numerically, fall back to string compare (handles pre-release tags if any)
        return normalizedFirst.localizedCaseInsensitiveCompare(normalizedSecond)
    }
}
