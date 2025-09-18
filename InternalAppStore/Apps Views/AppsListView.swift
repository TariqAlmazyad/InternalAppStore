//
//  AppsListView.swift
//  InternalAppStore
//
//  Created by Tariq AlMazyad on 18/09/2025.
//

import SwiftUI

struct AppsListView: View {
    @Environment(\.openURL) private var openURL
    @State private var firebaseManager: FirebaseManager = .shared
    
    @State private var isLoading = false
    @State private var loadingMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if firebaseManager.appDataList.isEmpty && isLoading {
                    // Empty + loading state
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(loadingMessage ?? "Loading…")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if firebaseManager.appDataList.isEmpty {
                    // Empty state (not loading)
                    ContentUnavailableView(
                        "No apps yet",
                        systemImage: "apps.iphone",
                        description: Text("Pull to refresh to fetch the latest apps.")
                    )
                } else {
                    List {
                        ForEach(firebaseManager.appDataList) { appData in
                            NavigationLink {
                                AppDetailsView(appData: appData)
                            } label: {
                                HStack(spacing: 12) {
                                    AsyncImage(url: appData.versions.first?.displayImageURL) { phase in
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
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(appData.name)
                                            .font(.headline)
                                        Text("Latest: \(appData.versions.first?.version ?? "—")")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                }
            }
            .refreshable {
                await loadApps(with: "Refreshing…")
            }
            .navigationTitle("Apps")
            .overlay(alignment: .bottom) {
                if isLoading, let message = loadingMessage {
                    LoadingBanner(message: message)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.2), value: isLoading)
                        .padding(.top, 8)
                }
            }
        }
        .task {
            await loadApps(with: "Loading apps…")
        }
    }
    
    // MARK: - Helpers
    private func loadApps(with message: String) async {
        await MainActor.run {
            loadingMessage = message
            isLoading = true
        }
        defer {
            Task { @MainActor in
                isLoading = false
                loadingMessage = nil
            }
        }
        do {
            try await firebaseManager.fetchAllApps()
        } catch {
            // Optionally surface an error message instead
            // For now we just end loading state
        }
    }
}

private struct LoadingBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
            Text(message)
                .font(.footnote)
                .bold()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(radius: 2, y: 1)
    }
}

#Preview {
    AppsListView()
        .preferredColorScheme(.dark)
}
