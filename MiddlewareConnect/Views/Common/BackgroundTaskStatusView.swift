import SwiftUI

/// A view that displays the status of background tasks
struct BackgroundTaskStatusView: View {
    @EnvironmentObject var appState: AppState
    @State private var showDetails: Bool = false
    
    var body: some View {
        VStack {
            if !appState.pendingBackgroundTasks.isEmpty {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Circle().fill(Color.blue))
                    
                    VStack(alignment: .leading) {
                        Text("Background Tasks")
                            .font(.headline)
                        
                        Text("\(appState.pendingBackgroundTasks.count) task\(appState.pendingBackgroundTasks.count == 1 ? "" : "s") in progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showDetails.toggle()
                        }
                    }) {
                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Circle().fill(Color.secondary.opacity(0.2)))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.1))
                )
                .padding(.horizontal)
                
                if showDetails {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(appState.pendingBackgroundTasks, id: \.self) { taskId in
                            HStack {
                                Image(systemName: getIconForTask(taskId))
                                    .foregroundColor(.blue)
                                
                                Text(getDescriptionForTask(taskId))
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.7)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.05))
                    )
                    .padding(.horizontal)
                }
            }
        }
        .animation(.easeInOut, value: appState.pendingBackgroundTasks.count)
        .animation(.easeInOut, value: showDetails)
    }
    
    /// Get the icon for a task based on its ID
    /// - Parameter taskId: The ID of the task
    /// - Returns: The system image name for the task
    private func getIconForTask(_ taskId: String) -> String {
        let components = taskId.components(separatedBy: ":")
        let taskType = components.first ?? ""
        
        switch taskType {
        case "pdfProcessing":
            return "doc.text"
        case "textProcessing":
            return "text.alignleft"
        case "apiRequest":
            return "network"
        default:
            return "arrow.triangle.2.circlepath"
        }
    }
    
    /// Get a human-readable description for a task based on its ID
    /// - Parameter taskId: The ID of the task
    /// - Returns: A description of the task
    private func getDescriptionForTask(_ taskId: String) -> String {
        let components = taskId.components(separatedBy: ":")
        
        guard components.count >= 2 else {
            return "Unknown task"
        }
        
        let taskType = components[0]
        let operationType = components[1]
        
        switch taskType {
        case "pdfProcessing":
            switch operationType {
            case "split":
                return "Splitting PDF"
            case "combine":
                return "Combining PDFs"
            default:
                return "Processing PDF"
            }
            
        case "textProcessing":
            switch operationType {
            case "chunk":
                return "Chunking text"
            case "clean":
                return "Cleaning text"
            default:
                return "Processing text"
            }
            
        case "apiRequest":
            switch operationType {
            case "summarize":
                return "Summarizing document"
            case "markdown":
                return "Converting markdown"
            default:
                return "API request"
            }
            
        default:
            return "Background task"
        }
    }
}

/// A modifier that adds a background task status view to a view
struct BackgroundTaskStatusModifier: ViewModifier {
    @EnvironmentObject var appState: AppState
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            
            if appState.showBackgroundTaskStatus {
                BackgroundTaskStatusView()
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

extension View {
    /// Adds a background task status view to a view
    /// - Returns: A view with a background task status view
    func withBackgroundTaskStatus() -> some View {
        self.modifier(BackgroundTaskStatusModifier())
    }
}

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var mockAppState = {
            let state = AppState()
            state.pendingBackgroundTasks = [
                "pdfProcessing:split:document.pdf",
                "textProcessing:chunk:text.txt:1000:200",
                "apiRequest:summarize:document.txt:brief"
            ]
            state.showBackgroundTaskStatus = true
            return state
        }()
        
        var body: some View {
            BackgroundTaskStatusView()
                .environmentObject(mockAppState)
                .previewLayout(.sizeThatFits)
                .padding()
        }
    }
    
    return PreviewWrapper()
}
