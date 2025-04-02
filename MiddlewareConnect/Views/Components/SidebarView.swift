import SwiftUI

/// Sidebar view for iPad layout
struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedTab: AppTab
    var openModelSettings: () -> Void
    
    var body: some View {
        List {
            // Main sections
            Section(header: Text("Main")) {
                Button(action: {
                    selectedTab = .home
                }) {
                    Label(AppTab.home.title, systemImage: AppTab.home.icon)
                        .foregroundColor(DesignSystem.Colors.text)
                }
                .listRowBackground(selectedTab == .home ? DesignSystem.Colors.secondaryBackground : DesignSystem.Colors.background)
            }
            
            // Tool categories
            Section(header: Text("Tools")) {
                // Text Processing tools
                DisclosureGroup(
                    isExpanded: .constant(true),
                    content: {
                        Button(action: {
                            appState.activeTab = .text
                        }) {
                            Label("Text Chunker", systemImage: "doc.text.magnifyingglass")
                                .foregroundColor(DesignSystem.Colors.text)
                        }
                        .listRowBackground(appState.activeTab == .text ? DesignSystem.Colors.secondaryBackground : DesignSystem.Colors.background)
                        
                        Button(action: {
                            appState.activeTab = .textClean
                        }) {
                            Label("Text Cleaner", systemImage: "pencil.and.outline")
                                .foregroundColor(DesignSystem.Colors.text)
                        }
                        .listRowBackground(appState.activeTab == .textClean ? DesignSystem.Colors.secondaryBackground : DesignSystem.Colors.background)
                        
                        Button(action: {
                            appState.activeTab = .markdown
                        }) {
                            Label("Markdown Converter", systemImage: "doc.plaintext")
                                .foregroundColor(DesignSystem.Colors.text)
                        }
                        .listRowBackground(appState.activeTab == .markdown ? DesignSystem.Colors.secondaryBackground : DesignSystem.Colors.background)
                    },
                    label: {
                        Label("Text Processing", systemImage: "text.book.closed")
                            .foregroundColor(DesignSystem.Colors.text)
                    }
                )
                
                // PDF Tools
                DisclosureGroup(
                    isExpanded: .constant(true),
                    content: {
                        Button(action: {
                            appState.activeTab = .pdfCombine
                        }) {
                            Label("PDF Combiner", systemImage: "doc.on.doc")
                                .foregroundColor(DesignSystem.Colors.text)
                        }
                        .listRowBackground(appState.activeTab == .pdfCombine ? DesignSystem.Colors.secondaryBackground : DesignSystem.Colors.background)
                        
                        Button(action: {
                            appState.activeTab = .pdfSplit
                        }) {
                            Label("PDF Splitter", systemImage: "doc.on.doc.fill")
                                .foregroundColor(DesignSystem.Colors.text)
                        }
                        .listRowBackground(appState.activeTab == .pdfSplit ? DesignSystem.Colors.secondaryBackground : DesignSystem.Colors.background)
                    },
                    label: {
                        Label("PDF Tools", systemImage: "doc.fill")
                            .foregroundColor(DesignSystem.Colors.text)
                    }
                )
                
                // Data Formatting
                DisclosureGroup(
                    isExpanded: .constant(true),
                    content: {
                        Button(action: {
                            appState.activeTab = .csv
                        }) {
                            Label("CSV Formatter", systemImage: "tablecells")
                                .foregroundColor(DesignSystem.Colors.text)
                        }
                        .listRowBackground(appState.activeTab == .csv ? DesignSystem.Colors.secondaryBackground : DesignSystem.Colors.background)
                        
                        Button(action: {
                            appState.activeTab = .image
                        }) {
                            Label("Image Splitter", systemImage: "photo.on.rectangle")
                                .foregroundColor(DesignSystem.Colors.text)
                        }
                        .listRowBackground(appState.activeTab == .image ? DesignSystem.Colors.secondaryBackground : DesignSystem.Colors.background)
                    },
                    label: {
                        Label("Data Formatting", systemImage: "tablecells")
                            .foregroundColor(DesignSystem.Colors.text)
                    }
                )
                
                // LLM Analysis
                DisclosureGroup(
                    isExpanded: .constant(true),
                    content: {
                        Button(action: {
                            appState.activeTab = .tokenCost
                        }) {
                            Label("Token Cost Calculator", systemImage: "dollarsign.circle")
                                .foregroundColor(DesignSystem.Colors.text)
                        }
                        .listRowBackground(appState.activeTab == .tokenCost ? DesignSystem.Colors.secondaryBackground : DesignSystem.Colors.background)
                        
                        Button(action: {
                            appState.activeTab = .contextWindow
                        }) {
                            Label("Context Window", systemImage: "arrow.up.left.and.arrow.down.right")
                                .foregroundColor(DesignSystem.Colors.text)
                        }
                        .listRowBackground(appState.activeTab == .contextWindow ? DesignSystem.Colors.secondaryBackground : DesignSystem.Colors.background)
                    },
                    label: {
                        Label("LLM Analysis", systemImage: "chart.bar")
                            .foregroundColor(DesignSystem.Colors.text)
                    }
                )
            }
            
            // Settings section
            Section(header: Text("Settings")) {
                Button(action: {
                    selectedTab = .settings
                }) {
                    Label("Settings", systemImage: "gearshape")
                        .foregroundColor(DesignSystem.Colors.text)
                }
                .listRowBackground(selectedTab == .settings ? DesignSystem.Colors.secondaryBackground : DesignSystem.Colors.background)
                
                Button(action: {
                    // Show API settings
                    appState.showApiModal = true
                }) {
                    Label("API Key", systemImage: "key")
                        .foregroundColor(DesignSystem.Colors.text)
                }
                .listRowBackground(DesignSystem.Colors.background)
                
                Button(action: openModelSettings) {
                    Label("LLM Model", systemImage: "brain")
                        .foregroundColor(DesignSystem.Colors.text)
                }
                .listRowBackground(DesignSystem.Colors.background)
            }
        }
        .listStyle(SidebarListStyle())
    }
}