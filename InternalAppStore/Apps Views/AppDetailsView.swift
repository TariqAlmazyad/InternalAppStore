//
//  AppDetailsView.swift
//  InternalAppStore
//
//  Created by Tariq AlMazyad on 18/09/2025.
//

import SwiftUI

struct AppDetailsView: View {
    @Environment(\.openURL) private var openURL

    let appData: AppData

    // Compute inside the view
    private var sortedVersions: [AppDataVersion] {
        appData.versions.sorted {
            semanticCompareVersions($0.version, $1.version) == .orderedDescending
        }
    }
    private var latestVersion: AppDataVersion? { sortedVersions.first }
    private var previousVersions: [AppDataVersion] {
        Array(sortedVersions.dropFirst())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                if let latestVersion {
                    // Latest version card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            AsyncImage(url: latestVersion.displayImageURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                case .empty:
                                    Color.secondary.opacity(0.1).overlay(ProgressView())
                                case .failure:
                                    Color.secondary.opacity(0.1).overlay(Image(systemName: "app.fill").foregroundStyle(.secondary))
                                @unknown default:
                                    Color.clear
                                }
                            }
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(latestVersion.titleFromManifest ?? appData.name)
                                    .font(.title3.weight(.semibold))
                                    .lineLimit(1)
                                Text(latestVersion.bundleIdentifier ?? "—")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 6) {
                            infoRow(title: "Version", value: latestVersion.version)
                            infoRow(title: "Bundle Version", value: latestVersion.bundleVersion ?? "—")
                            if let updatedDate = latestVersion.timestamp {
                                infoRow(title: "Updated", value: updatedDate.formatted(date: .abbreviated, time: .shortened))
                            }
                            if let description = latestVersion.description, !description.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Description").font(.footnote.weight(.semibold))
                                    Text(description).font(.footnote).foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        if let manifestURL = latestVersion.manifestURL,
                           let installURL = buildITMSServicesURL(from: manifestURL) {
                            
                            Button {
                                openURL(installURL)
                                DispatchQueue.main.async {
                                    UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        exit(0)
                                    }
                                }
                            } label: {
                                Text("Install Latest")
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                            
                        } else {
                            Text("No manifest available for install.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemBackground)))
                }
                
                // Previous versions
                if !previousVersions.isEmpty {
                    Text("Previous Versions")
                        .font(.headline)
                        .padding(.top, 4)

                    VStack(spacing: 12) {
                        ForEach(previousVersions) { version in
                            VStack(alignment: .leading, spacing: 10) {

                                HStack(spacing: 12) {
                                    // 🔹 Per-version image
                                    AsyncImage(url: version.displayImageURL) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image.resizable().scaledToFill()
                                        case .empty:
                                            Color.secondary.opacity(0.1).overlay(ProgressView())
                                        case .failure:
                                            Color.secondary.opacity(0.1).overlay(
                                                Image(systemName: "app.fill").foregroundStyle(.secondary)
                                            )
                                        @unknown default:
                                            Color.clear
                                        }
                                    }
                                    .frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(version.titleFromManifest ?? version.appName)
                                            .font(.subheadline.weight(.semibold))
                                            .lineLimit(1)
                                        HStack {
                                            Text("Version").font(.footnote.weight(.semibold))
                                            Text(version.version)
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    if let manifestURL = version.manifestURL,
                                       let installURL = buildITMSServicesURL(from: manifestURL) {
                                        Button {
                                            openURL(installURL)
                                        } label: {
                                            Text("Install")
                                        }
                                        .buttonStyle(.bordered)
                                    } else {
                                        Text("No manifest")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Bundle Version").font(.footnote.weight(.semibold))
                                        Spacer()
                                        Text(version.bundleVersion ?? "—")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let updatedDate = version.timestamp {
                                        HStack {
                                            Text("Updated").font(.footnote.weight(.semibold))
                                            Spacer()
                                            Text(updatedDate.formatted(date: .abbreviated, time: .shortened))
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                    }
                } else {
                    Text("No previous versions available.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

            }
            .padding(16)
        }
        .navigationTitle(appData.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Small helpers (kept local to this view)

    @ViewBuilder
    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.footnote.weight(.semibold))
            Spacer(minLength: 8)
            Text(value).font(.footnote).foregroundStyle(.secondary)
        }
    }

    private func buildITMSServicesURL(from manifestDownloadURL: URL) -> URL? {
        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "&=+")
        guard let encoded = manifestDownloadURL.absoluteString.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) else { return nil }
        let itmsString = "itms-services://?action=download-manifest&url=\(encoded)"
        return URL(string: itmsString)
    }

    private func semanticCompareVersions(_ firstVersion: String, _ secondVersion: String) -> ComparisonResult {
        let normalizedFirst = firstVersion.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "v", with: "")
        let normalizedSecond = secondVersion.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "v", with: "")
        let a = normalizedFirst.split(separator: ".").compactMap { Int($0) }
        let b = normalizedSecond.split(separator: ".").compactMap { Int($0) }
        let n = max(a.count, b.count)
        for i in 0..<n {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x < y { return .orderedAscending }
            if x > y { return .orderedDescending }
        }
        return normalizedFirst.localizedCaseInsensitiveCompare(normalizedSecond)
    }
}






#Preview {
    AppDetailsView(appData: MockData.mockAppData)
        .preferredColorScheme(.dark)
}
