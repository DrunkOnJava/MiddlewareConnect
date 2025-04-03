import SwiftUI

/// Settings tab view containing various application settings
struct SettingsTabView: View {
    @EnvironmentObject var appState: AppState
    var openModelSettings: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                // API Settings section
                Section(header: Text("API Settings")) {
                    Button(action: {
                        appState.showApiModal = true
                    }) {
                        HStack {
                            Label("API Key", systemImage: "key")
                            
                            Spacer()
                            
                            Text(appState.apiSettings.isValid ? "Configured" : "Not Configured")
                                .foregroundColor(appState.apiSettings.isValid ? .green : .red)
                                .font(.caption)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(Color.gray)
                        }
                    }
                    .foregroundColor(DesignSystem.Colors.text)
                    
                    Button(action: openModelSettings) {
                        HStack {
                            Label("LLM Model", systemImage: "brain")
                            
                            Spacer()
                            
                            Text(appState.selectedModel.displayName)
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(Color.gray)
                        }
                    }
                    .foregroundColor(DesignSystem.Colors.text)
                }
                
                // Appearance section
                Section(header: Text("Appearance")) {
                    NavigationLink(
                        destination: AppThemeSettingsView()
                            .environmentObject(appState)
                    ) {
                        Label("Theme", systemImage: "paintbrush")
                    }
                    
                    NavigationLink(
                        destination: ViewFactory.shared.getCachingSettingsView()
                    ) {
                        Label("Caching", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                
                // About section
                Section(header: Text("About")) {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        
                        Spacer()
                        
                        Text("1.0.0")
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Link(destination: URL(string: "https://yourwebsite.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    
                    Link(destination: URL(string: "https://yourwebsite.com/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
        }
    }
}

/// App theme settings view
struct AppThemeSettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        List {
            ForEach(AppTheme.allCases, id: \.self) { theme in
                Button(action: {
                    withAnimation {
                        appState.theme = theme
                    }
                }) {
                    HStack {
                        Text(theme.displayName)
                            .foregroundColor(DesignSystem.Colors.text)
                        
                        Spacer()
                        
                        if appState.theme == theme {
                            Image(systemName: "checkmark")
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                }
                .listRowBackground(appState.theme == theme ? DesignSystem.Colors.secondaryBackground : DesignSystem.Colors.background)
            }
        }
        .navigationTitle("Theme")
        .navigationBarTitleDisplayMode(.inline)
    }
}