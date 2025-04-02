/**
 * @fileoverview Main content view for LLMBuddy
 * @module MainContentView
 * 
 * Created: 2025-03-30
 * Last Modified: 2025-03-30
 * 
 * Dependencies:
 * - SwiftUI
 * 
 * Exports:
 * - MainContentView struct
 */

import SwiftUI

/**
 * MainContentView
 * 
 * Primary container view that manages content and navigation for the LLMBuddy app.
 * Implements a responsive design pattern with adaptive layouts based on device size.
 */
struct MainContentView: View {
    // MARK: - State Properties
    @State private var selectedTab: AppTab = .home
    @State private var isShowingSidebar: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    // Environment access
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var navCoordinator: NavigationCoordinator
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    // Computed properties for responsive design
    private var isMobile: Bool {
        horizontalSizeClass == .compact
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Group {
                if isMobile {
                    mobileLayout
                } else {
                    desktopLayout
                }
            }
            .navigationTitle(selectedTab.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    navigationControls
                }
            }
            .overlay(loadingOverlay)
            .overlay(errorOverlay)
            .animation(.easeInOut, value: selectedTab)
            .animation(.spring(), value: isShowingSidebar)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(DesignSystem.Colors.primary)
        .onAppear {
            setupInitialState()
        }
    }
    
    // MARK: - Layout Components
    
    /// Mobile-optimized layout using tab-based navigation
    private var mobileLayout: some View {
        TabView(selection: $selectedTab) {
            HomeTabView()
                .tabItem {
                    Label(AppTab.home.title, systemImage: AppTab.home.iconName)
                }
                .tag(AppTab.home)
            
            ChatTabView()
                .tabItem {
                    Label(AppTab.chat.title, systemImage: AppTab.chat.iconName)
                }
                .tag(AppTab.chat)
            
            ToolsTabView()
                .tabItem {
                    Label(AppTab.tools.title, systemImage: AppTab.tools.iconName)
                }
                .tag(AppTab.tools)
            
            AnalysisTabView()
                .tabItem {
                    Label(AppTab.analysis.title, systemImage: AppTab.analysis.iconName)
                }
                .tag(AppTab.analysis)
            
            SettingsTabView()
                .tabItem {
                    Label(AppTab.settings.title, systemImage: AppTab.settings.iconName)
                }
                .tag(AppTab.settings)
        }
        .onChange(of: selectedTab) { newTab in
            DesignSystem.hapticFeedback(.light)
            appState.selectedTab = newTab
        }
    }
    
    /// Desktop-optimized layout with sidebar navigation
    private var desktopLayout: some View {
        HStack(spacing: 0) {
            // Sidebar navigation
            sidebarView
                .frame(width: isShowingSidebar ? 250 : 0)
                .clipped()
            
            // Main content area
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    /// Sidebar navigation component
    private var sidebarView: some View {
        VStack(spacing: 0) {
            // App logo and branding
            VStack(spacing: 8) {
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: 36))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text("LLM Buddy")
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Colors.background)
            
            // Navigation items
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(AppTab.allCases, id: \.self) { tab in
                        navigationButton(for: tab)
                    }
                }
                .padding(.vertical)
            }
            
            Spacer()
            
            // User profile section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(String(appState.userName.prefix(1).uppercased()))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading) {
                        Text(appState.userName)
                            .font(DesignSystem.Typography.headline)
                        
                        Text(appState.userRole)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .background(DesignSystem.Colors.background)
            .cornerRadius(DesignSystem.Borders.radius)
            .padding()
        }
        .background(DesignSystem.Colors.secondaryBackground)
        .frame(maxHeight: .infinity)
    }
    
    /// Main content view based on selected tab
    private var contentView: some View {
        VStack(spacing: 0) {
            switch selectedTab {
            case .home:
                HomeTabView()
            case .chat:
                ChatTabView()
            case .tools:
                ToolsTabView()
            case .analysis:
                AnalysisTabView()
            case .settings:
                SettingsTabView()
            }
        }
        .transition(.opacity)
    }
    
    /// Navigation button for sidebar
    private func navigationButton(for tab: AppTab) -> some View {
        Button(action: {
            selectedTab = tab
            if isMobile {
                isShowingSidebar = false
            }
            DesignSystem.hapticFeedback(.light)
        }) {
            HStack(spacing: 12) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(selectedTab == tab ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText)
                
                Text(tab.title)
                    .font(selectedTab == tab ? DesignSystem.Typography.headline : DesignSystem.Typography.body)
                
                Spacer()
                
                if selectedTab == tab {
                    Rectangle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: 4, height: 24)
                        .cornerRadius(DesignSystem.Borders.radiusSmall)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                selectedTab == tab ?
                DesignSystem.Colors.primary.opacity(0.1) :
                Color.clear
            )
            .cornerRadius(DesignSystem.Borders.radius)
            .padding(.horizontal, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// Navigation controls for toolbar
    private var navigationControls: some View {
        HStack {
            if isMobile {
                Button(action: {
                    isShowingSidebar.toggle()
                    DesignSystem.hapticFeedback(.medium)
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            
            Spacer()
            
            // Additional toolbar controls
            Button(action: {
                // Add user action here
                DesignSystem.notificationHaptic(.success)
            }) {
                Image(systemName: "bell")
                    .font(.system(size: 18))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .padding(.horizontal, 8)
            
            Button(action: {
                // Add user action here
                DesignSystem.hapticFeedback(.light)
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
    }
    
    /// Loading overlay to display during async operations
    private var loadingOverlay: some View {
        Group {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text("Loading...")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Borders.radiusLarge)
                            .fill(Color.black.opacity(0.7))
                    )
                }
                .transition(.opacity)
            }
        }
    }
    
    /// Error overlay for displaying error messages
    private var errorOverlay: some View {
        Group {
            if let errorMessage = errorMessage {
                VStack {
                    Spacer()
                    
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Error")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(.white)
                            
                            Text(errorMessage)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                self.errorMessage = nil
                            }
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .padding(4)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Borders.radius)
                            .fill(Color.red)
                    )
                    .padding()
                }
                .transition(.move(edge: .bottom))
                .animation(.spring(), value: errorMessage)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Set up initial app state
    private func setupInitialState() {
        // Restore selected tab from app state if available
        if let savedTab = appState.selectedTab {
            selectedTab = savedTab
        }
        
        // Set default sidebar visibility based on device form factor
        isShowingSidebar = !isMobile
        
        // Additional initialization if needed
        checkForUpdates()
    }
    
    /// Check for app updates
    private func checkForUpdates() {
        // Simulated update check
        // In a real app, this would be an API call
        // with proper async/await handling
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            
            // Uncomment to test error display
            // errorMessage = "Unable to check for updates. Please try again later."
        }
    }
}

// MARK: - Extensions

// Extension to add required properties to AppState
extension AppState {
    /// User name property
    var userName: String {
        return "User" // This would normally come from the actual AppState
    }
    
    /// User role property
    var userRole: String {
        return "Free Account" // This would normally come from the actual AppState
    }
}

// Helper for haptic feedback
extension DesignSystem {
    /// Standard haptic feedback
    static func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    /// Notification haptic feedback
    static func notificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    /// Selection feedback (used for UI element selection)
    static func selectionHaptic() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
