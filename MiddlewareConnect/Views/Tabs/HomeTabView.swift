import SwiftUI

/// Home tab view
public struct HomeTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFeature = 0
    @State private var isAnimated = false
    
    // Feature carousel items
    private let features = [
        FeatureItem(title: "Text Processing", description: "Split, clean, and format text for optimal LLM processing", icon: "doc.text.magnifyingglass", color: .blue),
        FeatureItem(title: "PDF Tools", description: "Combine and split PDFs for easier management", icon: "doc.on.doc", color: .red),
        FeatureItem(title: "Chat Interface", description: "Interact directly with your favorite LLM models", icon: "bubble.left.and.bubble.right", color: .green),
        FeatureItem(title: "Token Analysis", description: "Calculate costs and optimize your prompts", icon: "chart.bar", color: .purple)
    ]
    
    // Timer for auto-advancing carousel
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Colorful welcome banner
                welcomeBanner
                
                // Features carousel
                featureCarousel
                
                // Quick actions section
                quickActionsSection
                
                // Getting started section
                gettingStartedSection
            }
        }
        .navigationTitle("Home")
        .onAppear {
            // Animate elements when view appears
            withAnimation(.easeOut(duration: 0.6)) {
                isAnimated = true
            }
        }
        .onReceive(timer) { _ in
            // Auto-advance carousel
            withAnimation {
                selectedFeature = (selectedFeature + 1) % features.count
            }
        }
    }
    
    // MARK: - Banner Section
    private var welcomeBanner: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [.blue, .purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 200)
            
            // Pattern overlay
            Image(systemName: "circle.hexagongrid.fill")
                .resizable(resizingMode: .tile)
                .foregroundColor(Color.white.opacity(0.1))
                .frame(height: 200)
            
            // Text content
            VStack(alignment: .leading, spacing: 12) {
                Text("Welcome to")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                
                Text("LLM Buddy")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Your AI Tools Companion")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .offset(x: isAnimated ? 0 : -20, y: 0)
            .opacity(isAnimated ? 1 : 0)
        }
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }
    
    // MARK: - Feature Carousel
    private var featureCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Features")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 20)
                .padding(.top, 24)
            
            TabView(selection: $selectedFeature) {
                ForEach(0..<features.count, id: \.self) { index in
                    featureCard(feature: features[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .frame(height: 200)
            .padding(.vertical, 8)
        }
    }
    
    // Feature card for carousel
    private func featureCard(feature: FeatureItem) -> some View {
        ZStack(alignment: .leading) {
            // Background with gradient
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [feature.color, feature.color.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            // Content
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    // Icon with circle background
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: feature.icon)
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Page indicator dots
                    HStack(spacing: 6) {
                        ForEach(0..<features.count, id: \.self) { index in
                            Circle()
                                .fill(selectedFeature == index ? Color.white : Color.white.opacity(0.4))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                
                Spacer()
                
                Text(feature.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                
                // Learn more button
                HStack {
                    Spacer()
                    
                    Text("Learn More")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .padding(20)
        }
        .frame(height: 180)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 20)
                .padding(.top, 16)
            
            HStack(spacing: 12) {
                quickActionButton(title: "Text Chunker", icon: "doc.text", color: .blue)
                quickActionButton(title: "PDF Tools", icon: "doc.on.doc", color: .red)
                quickActionButton(title: "Token Calculator", icon: "dollarsign.circle", color: .orange)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // Quick action button component
    private func quickActionButton(title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.1))
                    .frame(height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Getting Started Section
    private var gettingStartedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Getting Started")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 20)
                .padding(.top, 24)
            
            VStack(spacing: 16) {
                stepCard(
                    number: "1",
                    title: "Configure API Key",
                    description: "Add your API key in Settings to access powerful LLM features",
                    isCompleted: appState.apiSettings.isValid
                )
                
                stepCard(
                    number: "2",
                    title: "Select Your Model",
                    description: "Choose from various LLM models to suit your needs",
                    isCompleted: true
                )
                
                stepCard(
                    number: "3",
                    title: "Try the Tools",
                    description: "Explore the text processing and document tools",
                    isCompleted: false
                )
                
                stepCard(
                    number: "4",
                    title: "Analyze & Optimize",
                    description: "Use the analysis tools to optimize your prompts and costs",
                    isCompleted: false
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    // Step card component
    private func stepCard(number: String, title: String, description: String, isCompleted: Bool) -> some View {
        HStack(spacing: 16) {
            // Step number or checkmark
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : Color.gray.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text(number)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                }
            }
            
            // Title and description
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isCompleted ? .green : .primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Arrow icon
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Feature carousel item model
struct FeatureItem {
    let title: String
    let description: String
    let icon: String
    let color: Color
}
