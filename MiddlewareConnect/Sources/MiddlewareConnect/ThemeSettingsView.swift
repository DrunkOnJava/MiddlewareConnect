//
//  ThemeSettingsView.swift
//  LLMBuddy-iOS
//
//  Created on 3/25/2025.
//

import SwiftUI

/// View for managing app appearance theme settings
struct ThemeSettingsView: View {
    // MARK: - Properties
    
    /// The app state
    @EnvironmentObject var appState: AppState
    
    /// Whether to show the success message
    @State private var showingSuccessMessage = false
    
    /// The success message
    @State private var successMessage = ""
    
    // MARK: - Body
    
    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $appState.theme) {
                    ForEach(DesignSystem.Theme.allCases) { theme in
                        HStack {
                            Image(systemName: theme.iconName)
                                .foregroundColor(themeIcon(for: theme))
                            Text(theme.displayName)
                        }
                        .tag(theme)
                    }
                }
                .pickerStyle(DefaultPickerStyle())
                .onChange(of: appState.theme) { newValue in
                    saveThemeSelection(theme: newValue)
                }
                
                // Show current theme
                HStack {
                    Text("Active theme")
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: appState.theme.iconName)
                            .foregroundColor(themeIcon(for: appState.theme))
                        Text(appState.theme.displayName)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("About Themes")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("System")
                        .font(.headline)
                    Text("Follows your device's appearance settings. When your device switches between light and dark mode, the app will automatically switch too.")
                        .font(.footnote)
                    
                    Divider()
                    
                    Text("Light")
                        .font(.headline)
                    Text("Uses light appearance regardless of system settings. Light mode offers better readability in bright environments.")
                        .font(.footnote)
                    
                    Divider()
                    
                    Text("Dark")
                        .font(.headline)
                    Text("Uses dark appearance regardless of system settings. Dark mode reduces eye strain in low-light environments and can improve battery life on OLED displays.")
                        .font(.footnote)
                }
                .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Appearance")
        .overlay(
            successOverlay
        )
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
    
    /// Save the theme selection
    /// - Parameter theme: The selected theme
    private func saveThemeSelection(theme: DesignSystem.Theme) {
        // Save the theme selection to UserDefaults
        UserDefaults.standard.set(theme.rawValue, forKey: "app_theme")
        
        // Show a success message
        showSuccess(message: "Theme changed to \(theme.displayName)")
    }
    
    /// Returns the color for the theme icon
    /// - Parameter theme: The theme
    /// - Returns: The color for the theme icon
    private func themeIcon(for theme: DesignSystem.Theme) -> Color {
        switch theme {
        case .system:
            return .purple
        case .light:
            return .orange
        case .dark:
            return .blue
        }
    }
    
    /// Show a success message
    /// - Parameter message: The message to show
    private func showSuccess(message: String) {
        successMessage = message
        withAnimation {
            showingSuccessMessage = true
        }
    }
}

// MARK: - Preview

struct ThemeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ThemeSettingsView()
                .environmentObject(AppState())
        }
    }
}