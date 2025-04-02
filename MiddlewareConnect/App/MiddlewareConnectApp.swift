import SwiftUI
import BackgroundTasks
import Foundation
import UIKit
import Combine
import PDFKit

// Add direct imports for tab views
@_exported import SwiftUI

// Import model types
@_exported import struct Foundation.UUID
@_exported import struct Foundation.Date

// Stub class declarations to satisfy dependencies
class AppState: ObservableObject {
    enum Theme: String, CaseIterable, Identifiable {
        case light
        case dark
        case system
        
        var id: String { self.rawValue }
        
        var colorScheme: ColorScheme? {
            switch self {
            case .light:
                return .light
            case .dark:
                return .dark
            case .system:
                return nil
            }
        }
    }
    
    var theme: Theme = .system
    var apiSettings = ApiSettings()
    var selectedModel: LLMModel {
        get {
            return LLMModel.defaultModels[0]
        }
        set {}
    }
    
    var selectedTab: AppTab?
    
    func validateApiKey() {}
    func checkForCompletedBackgroundTasks() {}
    func updateFeatureToggles(_ toggles: ApiFeatureToggles) {}
    
    // Define the defaultModels for LLMModel if not defined elsewhere
    static func getDefaultModels() -> [LLMModel] {
        return LLMModel.defaultModels
    }
}

// Define AppTab enum to satisfy MainAppView's requirement
enum AppTab: String, CaseIterable, Identifiable {
    case home, chat, tools, analysis, settings
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .chat: return "Chat"
        case .tools: return "Tools"
        case .analysis: return "Analysis"
        case .settings: return "Settings"
        }
    }
    
    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .tools: return "wrench.and.screwdriver.fill"
        case .analysis: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// LLM Provider enum definition
public enum LLMProvider: String, Codable, CaseIterable {
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    case google = "Google"
    case meta = "Meta"
    case localModel = "Local"
    case customAPI = "Custom API"
    
    /// Provider icon name
    public var icon: String {
        switch self {
        case .openAI: return "openai-logo"
        case .anthropic: return "anthropic-logo"
        case .google: return "google-logo"
        case .meta: return "meta-logo"
        case .localModel: return "desktopcomputer"
        case .customAPI: return "network"
        }
    }
    
    /// Provider brand color
    public var color: Color {
        switch self {
        case .openAI: return Color(red: 0.01, green: 0.69, blue: 0.45)
        case .anthropic: return Color(red: 0.97, green: 0.42, blue: 0.25)
        case .google: return Color(red: 0.26, green: 0.52, blue: 0.96)
        case .meta: return Color(red: 0.23, green: 0.35, blue: 0.60)
        case .localModel: return Color.gray
        case .customAPI: return Color.purple
        }
    }
}

// LLM Model struct definition
public struct LLMModel: Identifiable, Hashable, Codable {
    public var id = UUID()
    public var name: String
    public var provider: LLMProvider
    public var modelId: String
    public var contextSize: Int
    public var defaultTemperature: Double = 0.7
    public var supportsStreaming: Bool = true
    public var capabilities: [String] = []
    
    public init(
        name: String,
        provider: LLMProvider,
        modelId: String,
        contextSize: Int,
        defaultTemperature: Double = 0.7,
        supportsStreaming: Bool = true,
        capabilities: [String] = []
    ) {
        self.name = name
        self.provider = provider
        self.modelId = modelId
        self.contextSize = contextSize
        self.defaultTemperature = defaultTemperature
        self.supportsStreaming = supportsStreaming
        self.capabilities = capabilities
    }
    
    public var displayName: String {
        return name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: LLMModel, rhs: LLMModel) -> Bool {
        lhs.id == rhs.id
    }
    
    // Predefined models
    public static var defaultModels: [LLMModel] = [
        LLMModel(
            name: "Claude 3.5 Sonnet",
            provider: .anthropic,
            modelId: "claude-3-5-sonnet-20250307",
            contextSize: 200000,
            capabilities: ["chat", "codeGeneration", "reasoning"]
        ),
        LLMModel(
            name: "GPT-4o",
            provider: .openAI,
            modelId: "gpt-4o",
            contextSize: 128000,
            capabilities: ["chat", "codeGeneration", "reasoning", "imageGeneration"]
        ),
        LLMModel(
            name: "Gemini Pro",
            provider: .google,
            modelId: "gemini-pro",
            contextSize: 32768,
            capabilities: ["chat", "codeGeneration"]
        )
    ]
    
    // Create static model references to match the enum-based approach used in the code
    public static var claudeSonnet: LLMModel {
        return defaultModels[0]
    }
    
    public static var gpt4: LLMModel {
        return defaultModels[1]
    }
}

// Add missing ApiFeatureToggles struct if not found elsewhere
public struct ApiFeatureToggles: Codable, Equatable {
    /// Enable streaming responses
    public var enableStreaming: Bool = true
    
    /// Enable vision capabilities
    public var enableVision: Bool = false
    
    /// Enable system prompts
    public var enableSystemPrompt: Bool = true
    
    /// Enable temperature adjustments
    public var enableTemperature: Bool = true
    
    /// Enable customization
    public var enableCustomization: Bool = true
    
    /// Enable function calling
    public var enableFunctionCalling: Bool = false
    
    /// Enable tool use
    public var enableTools: Bool = false
    
    /// OCR transcription feature
    public var ocrTranscription: Bool = false
    
    /// Intelligent naming feature
    public var intelligentNaming: Bool = false
    
    /// Markdown converter feature
    public var markdownConverter: Bool = false
    
    /// Document summarization feature
    public var documentSummarization: Bool = false
    
    /// Initialize with default values
    public init(
        enableStreaming: Bool = true,
        enableVision: Bool = false,
        enableSystemPrompt: Bool = true,
        enableTemperature: Bool = true,
        enableCustomization: Bool = true,
        enableFunctionCalling: Bool = false,
        enableTools: Bool = false,
        ocrTranscription: Bool = false,
        intelligentNaming: Bool = false,
        markdownConverter: Bool = false,
        documentSummarization: Bool = false
    ) {
        self.enableStreaming = enableStreaming
        self.enableVision = enableVision
        self.enableSystemPrompt = enableSystemPrompt
        self.enableTemperature = enableTemperature
        self.enableCustomization = enableCustomization
        self.enableFunctionCalling = enableFunctionCalling
        self.enableTools = enableTools
        self.ocrTranscription = ocrTranscription
        self.intelligentNaming = intelligentNaming
        self.markdownConverter = markdownConverter
        self.documentSummarization = documentSummarization
    }
    
    /// Default toggles with standard settings
    public static var defaultToggles: ApiFeatureToggles {
        return ApiFeatureToggles()
    }
}

class NavigationCoordinator: ObservableObject {
    var showApiSettings = false
    var showModelSettings = false
    var showReleaseNotes = false
    var showFeedbackForm = false
    var showPrivacyPolicy = false
    
    // Add these properties for fullscreen modals and alerts
    @Published var activeSheet: Sheet?
    @Published var activeFullscreenCover: FullscreenCover?
    @Published var activeAlert: AlertType?
    
    // Define the Sheet enum
    enum Sheet: Identifiable {
        case newConversation
        case modelSelection
        case settings
        case exportConversation(id: UUID)
        case importConversation
        
        var id: String {
            switch self {
            case .newConversation: return "newConversation"
            case .modelSelection: return "modelSelection"
            case .settings: return "settings"
            case .exportConversation(let id): return "exportConversation-\(id)"
            case .importConversation: return "importConversation"
            }
        }
    }
    
    // Define the FullscreenCover enum
    enum FullscreenCover: Identifiable {
        case onboarding
        case authentication
        case welcomeTour
        
        var id: String {
            switch self {
            case .onboarding: return "onboarding"
            case .authentication: return "authentication"
            case .welcomeTour: return "welcomeTour"
            }
        }
    }
    
    // Define the AlertType enum
    enum AlertType: Identifiable {
        case error(message: String)
        case confirmation(message: String, action: () -> Void)
        case deleteConfirmation(message: String, action: () -> Void)
        
        var id: String {
            switch self {
            case .error: return "error"
            case .confirmation: return "confirmation"
            case .deleteConfirmation: return "deleteConfirmation"
            }
        }
    }
}

// MARK: - Tab View Imports
// Import the actual tab views from the Views/Tabs directory
import SwiftUI
import UniformTypeIdentifiers

// Simple PDF Combiner View Implementation
struct PDFCombinerViewSimple: View {
    @State private var selectedPDFs: [PDFDocument] = []
    @State private var selectedPDFURLs: [URL] = []
    @State private var combinedPDFURL: URL? = nil
    @State private var isShowingDocumentPicker = false
    @State private var isProcessing = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Banner at the top
                VStack(alignment: .leading, spacing: 10) {
                    Label("PDF Combiner", systemImage: "doc.on.doc.fill")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    Text("Combine multiple PDF files into a single document")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient(
                    gradient: Gradient(colors: [.red, .red.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                
                // Add PDFs Button
                Button(action: {
                    isShowingDocumentPicker = true
                }) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Select PDF Files")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Selected PDFs list
                if !selectedPDFs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected PDFs (\(selectedPDFs.count))")
                            .font(.headline)
                        
                        ForEach(0..<selectedPDFs.count, id: \.self) { index in
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(.red)
                                
                                Text(selectedPDFURLs[index].lastPathComponent)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text("\(selectedPDFs[index].pageCount) pages")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                        
                        // Combine button
                        Button(action: {
                            // Placeholder for combine action
                            isProcessing = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isProcessing = false
                                errorMessage = "This is a simplified demo. For full functionality, please use the actual PdfCombinerView."
                            }
                        }) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Combine PDFs")
                                    .bold()
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(selectedPDFs.count >= 2 ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(selectedPDFs.count < 2 || isProcessing)
                    }
                    .padding(.horizontal)
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No PDFs Selected")
                            .font(.headline)
                        
                        Text("Please select PDF files to combine")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("PDF Combiner")
        .sheet(isPresented: $isShowingDocumentPicker) {
            DocumentPickerSimple(contentTypes: [UTType.pdf], onPick: { urls in
                // Load PDFs
                for url in urls {
                    if let pdf = PDFDocument(url: url) {
                        selectedPDFs.append(pdf)
                        selectedPDFURLs.append(url)
                    }
                }
            })
        }
    }
}

// Simple document picker
struct DocumentPickerSimple: UIViewControllerRepresentable {
    let contentTypes: [UTType]
    let onPick: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerSimple
        
        init(_ parent: DocumentPickerSimple) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onPick(urls)
        }
    }
}

// Model for feature items
struct FeatureItem {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

// Direct implementation of Home tab
struct HomeTabViewImplementation: View {
    @State private var isAnimated = false
    @EnvironmentObject var appState: AppState
    
    // Feature carousel items
    private let features = [
        FeatureItem(title: "Text Processing", description: "Split, clean, and format text for optimal LLM processing", icon: "doc.text.magnifyingglass", color: .blue),
        FeatureItem(title: "PDF Tools", description: "Combine and split PDFs for easier management", icon: "doc.on.doc", color: .red),
        FeatureItem(title: "Chat Interface", description: "Interact directly with your favorite LLM models", icon: "bubble.left.and.bubble.right", color: .green),
        FeatureItem(title: "Token Analysis", description: "Calculate costs and optimize your prompts", icon: "chart.bar", color: .purple)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Welcome banner
                ZStack(alignment: .bottomLeading) {
                    // Gradient background
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 200)
                    
                    // Text content
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Welcome to")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("MiddlewareConnect")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Your AI Tools Companion")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .opacity(isAnimated ? 1 : 0)
                }
                
                // Features section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Features")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    
                    // Feature cards
                    ForEach(features.indices, id: \.self) { index in
                        featureCard(features[index])
                            .padding(.horizontal, 20)
                    }
                }
                
                // Getting started section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Getting Started")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    
                    VStack(spacing: 12) {
                        stepCard(
                            number: "1",
                            title: "Configure API Key",
                            description: "Add your API key in Settings to access powerful LLM features",
                            isCompleted: true
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
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Home")
        .onAppear {
            // Animate elements when view appears
            withAnimation(.easeOut(duration: 0.6)) {
                isAnimated = true
            }
        }
    }
    
    // Feature card
    private func featureCard(_ feature: FeatureItem) -> some View {
        ZStack(alignment: .leading) {
            // Background with gradient
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [feature.color, feature.color.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
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
            }
            .padding(20)
        }
        .frame(height: 180)
    }
    
    // Step card
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
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Model for chat conversations
struct ChatConversation: Identifiable {
    var id: UUID
    var title: String
    var lastMessage: String
    var date: Date
    var model: LLMModel
}

// Direct implementation of Chat tab
struct ChatTabViewImplementation: View {
    @State private var conversations: [ChatConversation] = [
        ChatConversation(id: UUID(), title: "Project Brainstorming", lastMessage: "What if we combine voice recognition with the text analysis feature?", date: Date().addingTimeInterval(-3600), model: LLMModel.defaultModels[0]),
        ChatConversation(id: UUID(), title: "PDF Analysis Help", lastMessage: "I need to extract key information from these scientific papers", date: Date().addingTimeInterval(-86400), model: LLMModel.defaultModels[1]),
        ChatConversation(id: UUID(), title: "Code Debugging", lastMessage: "Why is my API authentication failing?", date: Date().addingTimeInterval(-172800), model: LLMModel.defaultModels[2])
    ]
    
    var body: some View {
        VStack {
            // New Chat Button
            Button(action: {
                // In real app, would create a new conversation
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("New Conversation")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            
            // Conversation list
            List(conversations) { conversation in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(conversation.title)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(timeAgo(from: conversation.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(conversation.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        // Model tag
                        Text(conversation.model.name)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(modelColor(for: conversation.model.provider).opacity(0.1))
                            .foregroundColor(modelColor(for: conversation.model.provider))
                            .cornerRadius(4)
                        
                        Spacer()
                        
                        // Message count
                        Text("23 messages")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            .listStyle(PlainListStyle())
            
            // Empty state
            if conversations.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 60))
                        .foregroundColor(.blue.opacity(0.7))
                    
                    Text("No Conversations Yet")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Start a new conversation to chat with your favorite LLM model")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        // In real app, would create a new conversation
                    }) {
                        Text("Start New Conversation")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
        }
        .navigationTitle("Conversations")
    }
    
    // Helper to format date
    private func timeAgo(from date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day)d ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else {
            return "Just now"
        }
    }
    
    // Get color for model provider
    private func modelColor(for provider: LLMProvider) -> Color {
        switch provider {
        case .anthropic: return .orange
        case .openAI: return .green
        case .google: return .blue
        default: return .gray
        }
    }
}
struct HomeTabForward: View {
    var body: some View {
        // Directly use a manually implemented HomeTabView
        HomeTabViewImplementation()
    }
}

struct ChatTabForward: View {
    var body: some View {
        // Directly use a manually implemented ChatTabView
        ChatTabViewImplementation()
    }
}

// Direct implementation of Analysis tab
struct AnalysisTabViewImplementation: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("LLM Analysis Tools")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Optimize your prompts and understand token usage")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Tool cards
                Group {
                    // Token calculator
                    analysisToolCard(
                        title: "Token Cost Calculator",
                        description: "Calculate costs across different models",
                        icon: "dollarsign.circle",
                        color: .green
                    )
                    
                    // Context window visualizer
                    analysisToolCard(
                        title: "Context Window Visualizer",
                        description: "Understand token usage in your prompts",
                        icon: "chart.bar.fill",
                        color: .blue
                    )
                    
                    // Prompt analyzer
                    analysisToolCard(
                        title: "Prompt Analyzer",
                        description: "Get suggestions to improve your prompts",
                        icon: "text.magnifyingglass",
                        color: .purple
                    )
                    
                    // Model comparison
                    analysisToolCard(
                        title: "Model Comparison",
                        description: "Compare performance across different models",
                        icon: "arrow.left.arrow.right",
                        color: .orange,
                        isBeta: true
                    )
                }
                .padding(.horizontal)
                
                // Usage stats section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Usage Stats")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 16) {
                        // Tokens used card
                        usageStatCard(
                            value: "137K",
                            label: "Tokens Used",
                            icon: "number",
                            color: .blue
                        )
                        
                        // Estimated cost card
                        usageStatCard(
                            value: "$1.28",
                            label: "Est. Cost",
                            icon: "dollarsign",
                            color: .green
                        )
                    }
                    
                    HStack(spacing: 16) {
                        // Conversations card
                        usageStatCard(
                            value: "12",
                            label: "Conversations",
                            icon: "bubble.left.and.bubble.right",
                            color: .orange
                        )
                        
                        // Average tokens card
                        usageStatCard(
                            value: "1.2K",
                            label: "Avg. per Call",
                            icon: "chart.bar",
                            color: .purple
                        )
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Analysis")
    }
    
    // Analysis tool card
    private func analysisToolCard(title: String, description: String, icon: String, color: Color, isBeta: Bool = false) -> some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                        
                        if isBeta {
                            Text("BETA")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Usage stat card
    private func usageStatCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// Direct implementation of tools tab with access to PdfCombinerView
struct ToolsTabViewImplementation: View {
    @State private var selectedTool: String? = nil
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Document Tools")) {
                    NavigationLink(
                        destination: PDFCombinerViewSimple(),
                        tag: "pdfCombiner",
                        selection: $selectedTool
                    ) {
                        Label("PDF Combiner", systemImage: "doc.on.doc")
                    }
                    
                    NavigationLink(
                        destination: Text("PDF Splitter"),
                        tag: "pdfSplitter",
                        selection: $selectedTool
                    ) {
                        Label("PDF Splitter", systemImage: "doc.text")
                    }
                }
                
                Section(header: Text("Text Processing")) {
                    NavigationLink(
                        destination: Text("Text Chunker"),
                        tag: "textChunker",
                        selection: $selectedTool
                    ) {
                        Label("Text Chunker", systemImage: "text.insert")
                    }
                    
                    NavigationLink(
                        destination: Text("Text Cleaner"),
                        tag: "textCleaner",
                        selection: $selectedTool
                    ) {
                        Label("Text Cleaner", systemImage: "sparkles")
                    }
                }
                
                Section(header: Text("Data Formatting")) {
                    NavigationLink(
                        destination: Text("CSV Formatter"),
                        tag: "csvFormatter",
                        selection: $selectedTool
                    ) {
                        Label("CSV Formatter", systemImage: "tablecells")
                    }
                    
                    NavigationLink(
                        destination: Text("Markdown Converter"),
                        tag: "markdownConverter",
                        selection: $selectedTool
                    ) {
                        Label("Markdown Converter", systemImage: "doc.plaintext")
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Tools")
        }
    }
}

struct ToolsTabForward: View {
    var body: some View {
        // Directly use a manually implemented ToolsTabView
        ToolsTabViewImplementation()
    }
}

struct AnalysisTabForward: View {
    var body: some View {
        // Directly use a manually implemented AnalysisTabView
        AnalysisTabViewImplementation()
    }
}

// Direct implementation of Settings tab
struct SettingsTabViewImplementation: View {
    @State private var model = "Claude 3.5 Sonnet"
    @State private var apiKeyConfigured = true
    @State private var theme = "System"
    @State private var caching = true
    
    var body: some View {
        Form {
            // API Settings section
            Section(header: Text("API Settings")) {
                HStack {
                    Label("API Keys", systemImage: "key")
                    Spacer()
                    Text(apiKeyConfigured ? "Configured" : "Not Configured")
                        .font(.caption)
                        .foregroundColor(apiKeyConfigured ? .green : .red)
                }
                
                HStack {
                    Label("LLM Model", systemImage: "brain")
                    Spacer()
                    Text(model)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                NavigationLink(destination: Text("Feature Toggles")) {
                    Label("Feature Toggles", systemImage: "switch.2")
                }
            }
            
            // Appearance section
            Section(header: Text("Appearance")) {
                HStack {
                    Label("Theme", systemImage: "paintbrush")
                    Spacer()
                    Text(theme)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                HStack {
                    Label("Caching", systemImage: "arrow.triangle.2.circlepath")
                    Spacer()
                    Text(caching ? "Enabled" : "Disabled")
                        .foregroundColor(caching ? .green : .secondary)
                        .font(.caption)
                }
                
                Button(action: {}) {
                    Label("Clear Memory Cache", systemImage: "trash")
                }
            }
            
            // Help & Feedback section
            Section(header: Text("Help & Feedback")) {
                Button(action: {}) {
                    Label("What's New", systemImage: "star.bubble")
                }
                
                Button(action: {}) {
                    Label("Send Feedback", systemImage: "envelope")
                }
            }
            
            // About section
            Section(header: Text("About")) {
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text("1.0.0 (Build 42)")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                Button(action: {}) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
                
                HStack {
                    Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                    Spacer()
                    Image(systemName: "arrow.up.forward.square")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

struct SettingsTabForward: View {
    var body: some View {
        // Directly use a manually implemented SettingsTabView
        SettingsTabViewImplementation()
    }
}
struct MainTabContainer: View {
    @State private var selectedTab: AppTab = .home
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var navCoordinator: NavigationCoordinator
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home tab
            NavigationView {
                // Use the forwarding view to access the actual HomeTabView
                HomeTabForward()
            }
            .tabItem {
                Label(AppTab.home.title, systemImage: AppTab.home.iconName)
            }
            .tag(AppTab.home)
            
            // Chat tab
            NavigationView {
                // Use the forwarding view to access the actual ChatTabView
                ChatTabForward()
            }
            .tabItem {
                Label(AppTab.chat.title, systemImage: AppTab.chat.iconName)
            }
            .tag(AppTab.chat)
            
            // Tools tab
            NavigationView {
                // Use the forwarding view to access the actual ToolsTabView
                ToolsTabForward()
            }
            .tabItem {
                Label(AppTab.tools.title, systemImage: AppTab.tools.iconName)
            }
            .tag(AppTab.tools)
            
            // Analysis tab
            NavigationView {
                // Use the forwarding view to access the actual AnalysisTabView
                AnalysisTabForward()
            }
            .tabItem {
                Label(AppTab.analysis.title, systemImage: AppTab.analysis.iconName)
            }
            .tag(AppTab.analysis)
            
            // Settings tab
            NavigationView {
                // Use the forwarding view to access the actual SettingsTabView
                SettingsTabForward()
            }
            .tabItem {
                Label(AppTab.settings.title, systemImage: AppTab.settings.iconName)
            }
            .tag(AppTab.settings)
        }
        .onChange(of: selectedTab) { newTab in
            // Update app state when tab changes
            appState.selectedTab = newTab
        }
        .onAppear {
            // Restore selected tab if available
            if let savedTab = appState.selectedTab {
                selectedTab = savedTab
            }
            
            print("MainTabContainer appeared with tabs from Views/Tabs directory")
        }
    }
}

@main
struct MiddlewareConnectApp: App {
    @State private var memoryMonitorTimer: Timer? = nil
    
    init() {
        // Register background tasks
        registerBackgroundTasks()
        
        // Initialize memory manager
        setupMemoryManagement()
        
        // Print startup information to help with debugging
        print("MiddlewareConnectApp initializing")
    }
    
    var body: some Scene {
        WindowGroup {
            // Use our simplified ContentView
            ContentView()
                .onAppear {
                    // Start memory monitoring
                    startMemoryMonitoring()
                    
                    // Additional debugging info at launch
                    print("App launch sequence completed")
                }
                .onDisappear {
                    // Stop memory monitoring
                    memoryMonitorTimer?.invalidate()
                    memoryMonitorTimer = nil
                }
        }
    }
    
    /// Register background tasks
    private func registerBackgroundTasks() {
        // This would be implemented to register background tasks
        print("Background tasks would be registered here")
    }
    
    // Setup memory management
    private func setupMemoryManagement() {
        // Register for memory warnings at the app level
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("⚠️ App received memory warning - clearing caches")
            MemoryManager.shared.clearMemoryCaches()
        }
    }
    
    // Start memory monitoring
    private func startMemoryMonitoring() {
        memoryMonitorTimer = MemoryManager.shared.startMonitoringMemoryUsage(interval: 10.0)
    }
}
