//
//  CachingSettingsView.swift
//  LLMBuddy-iOS
//
//  Created on 3/25/2025.
//

import SwiftUI

/// View for managing caching settings
struct CachingSettingsView: View {
    // MARK: - Properties
    
    /// The caching manager
    private let cachingManager = CachingManager.shared
    
    /// Whether caching is enabled
    @State private var cachingEnabled: Bool
    
    /// Whether to show the clear cache confirmation
    @State private var showingClearCacheConfirmation = false
    
    /// Whether to show the success message
    @State private var showingSuccessMessage = false
    
    /// The success message
    @State private var successMessage = ""
    
    /// The current cache size
    @State private var cacheSize: String
    
    // MARK: - Initialization
    
    init() {
        // Initialize state variables
        _cachingEnabled = State(initialValue: CachingManager.shared.getCachingStatus())
        _cacheSize = State(initialValue: CachingManager.shared.formattedDiskCacheSize())
    }
    
    // MARK: - Body
    
    var body: some View {
        Form {
            Section(header: Text("Caching Settings")) {
                Toggle("Enable Caching", isOn: $cachingEnabled)
                    .onChange(of: cachingEnabled) { newValue in
                        cachingManager.setCachingEnabled(newValue)
                    }
                
                HStack {
                    Text("Cache Size")
                    Spacer()
                    Text(cacheSize)
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    showingClearCacheConfirmation = true
                }) {
                    Text("Clear All Caches")
                        .foregroundColor(.red)
                }
                .alert(isPresented: $showingClearCacheConfirmation) {
                    Alert(
                        title: Text("Clear All Caches"),
                        message: Text("Are you sure you want to clear all caches? This will remove all cached responses, images, and documents."),
                        primaryButton: .destructive(Text("Clear")) {
                            clearAllCaches()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
            
            Section(header: Text("Clear Specific Caches")) {
                Button(action: {
                    clearCache(type: .api)
                }) {
                    Text("Clear API Response Cache")
                }
                
                Button(action: {
                    clearCache(type: .image)
                }) {
                    Text("Clear Image Cache")
                }
                
                Button(action: {
                    clearCache(type: .documents)
                }) {
                    Text("Clear Document Cache")
                }
                
                Button(action: {
                    clearCache(type: .network)
                }) {
                    Text("Clear Network Cache")
                }
            }
            
            Section(header: Text("About Caching")) {
                Text("Caching improves app performance by storing frequently used data locally. This reduces API calls, speeds up image loading, and improves PDF processing.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Caching")
        .overlay(
            successOverlay
        )
        .onAppear {
            // Update cache size when the view appears
            updateCacheSize()
        }
    }
    
    // MARK: - Success Overlay
    
    private var successOverlay: some View {
        Group {
            if showingSuccessMessage {
                VStack {
                    Spacer()
                    
                    Text(successMessage)
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                    
                    Spacer()
                        .frame(height: 100)
                }
                .transition(.move(edge: .bottom))
                .animation(.easeInOut, value: showingSuccessMessage)
                .onAppear {
                    // Hide the success message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showingSuccessMessage = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    
    /// Clear all caches
    private func clearAllCaches() {
        cachingManager.clearAllCaches()
        showSuccess(message: "All caches cleared")
        updateCacheSize()
    }
    
    /// Clear a specific type of cache
    /// - Parameter type: The type of cache to clear
    private func clearCache(type: CacheType) {
        cachingManager.clearCache(type: type)
        
        let typeName: String
        switch type {
        case .api:
            typeName = "API response"
        case .image:
            typeName = "image"
        case .documents:
            typeName = "document"
        case .network:
            typeName = "network"
        }
        
        showSuccess(message: "\(typeName) cache cleared")
        updateCacheSize()
    }
    
    /// Show a success message
    /// - Parameter message: The message to show
    private func showSuccess(message: String) {
        successMessage = message
        withAnimation {
            showingSuccessMessage = true
        }
    }
    
    /// Update the cache size display
    private func updateCacheSize() {
        cacheSize = cachingManager.formattedDiskCacheSize()
    }
}

// MARK: - Preview

struct CachingSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CachingSettingsView()
        }
    }
}
