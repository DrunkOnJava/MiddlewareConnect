import SwiftUI
import Combine

/// A component that displays streaming text responses with a typing animation effect
struct StreamingResponseView: View {
    /// The text to display
    let text: String
    
    /// Indicates if the text is still streaming
    let isStreaming: Bool
    
    /// The animation speed multiplier
    var animationSpeed: Double = 1.0
    
    /// Cursor options
    var showCursor: Bool = true
    var cursorColor: Color = DesignSystem.Colors.primary
    
    /// The current displayed text
    @State private var displayedText: String = ""
    
    /// Animation state
    @State private var animationIndex: Int = 0
    @State private var timer: AnyCancellable?
    
    var body: some View {
        ZStack(alignment: .trailing) {
            Text(displayedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .animation(nil, value: displayedText)
                .contentTransition(.numericText(value: Double(displayedText.count)))
            
            if isStreaming && showCursor {
                Rectangle()
                    .fill(cursorColor)
                    .frame(width: 2, height: 16)
                    .opacity(animationIndex % 2 == 0 ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: animationIndex)
                    .alignmentGuide(.trailing) { _ in 0 }
            }
        }
        .onChange(of: text) { newText in
            updateDisplayedText(newText: newText)
        }
        .onChange(of: isStreaming) { streaming in
            if streaming {
                startCursorBlinking()
            } else {
                stopCursorBlinking()
                // Ensure all text is displayed when streaming ends
                displayedText = text
            }
        }
        .onAppear {
            updateDisplayedText(newText: text)
            if isStreaming {
                startCursorBlinking()
            }
        }
        .onDisappear {
            stopCursorBlinking()
        }
    }
    
    /// Updates the displayed text with smooth typing animation
    private func updateDisplayedText(newText: String) {
        // If not streaming or the text is empty, update immediately
        if !isStreaming || newText.isEmpty {
            displayedText = newText
            return
        }
        
        // If current text is longer than new text (which shouldn't happen in streaming)
        // or if we haven't started displaying text yet, update immediately
        if displayedText.count >= newText.count || displayedText.isEmpty {
            displayedText = newText
            return
        }
        
        // Calculate how many new characters to add
        let newCharacters = newText.dropFirst(displayedText.count)
        
        // If there are no new characters, nothing to do
        if newCharacters.isEmpty {
            return
        }
        
        // Determine typing speed based on number of new characters
        // Faster for more characters to avoid delay
        let charactersPerUpdate = max(1, newCharacters.count / 5)
        let updateCount = Int(ceil(Double(newCharacters.count) / Double(charactersPerUpdate)))
        
        // Calculate the delay between updates
        let totalAnimationTime = min(0.1, Double(newCharacters.count) * 0.01) / animationSpeed
        let updateDelay = totalAnimationTime / Double(updateCount)
        
        // Create a sequence of updates
        var pendingText = displayedText
        
        for (index, chunk) in newCharacters.chunked(into: charactersPerUpdate).enumerated() {
            let chunkString = String(chunk)
            
            // Schedule update with incrementing delay
            let delay = updateDelay * Double(index)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                pendingText += chunkString
                displayedText = pendingText
            }
        }
    }
    
    /// Starts the cursor blinking animation
    private func startCursorBlinking() {
        stopCursorBlinking() // Stop any existing timer
        
        // Create a new timer that toggles the cursor visibility
        timer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.animationIndex += 1
            }
    }
    
    /// Stops the cursor blinking animation
    private func stopCursorBlinking() {
        timer?.cancel()
        timer = nil
    }
}

// MARK: - Extensions

extension StringProtocol {
    /// Chunks a string into arrays of specified size
    func chunked(into size: Int) -> [SubSequence] {
        var result: [SubSequence] = []
        var startIndex = self.startIndex
        
        while startIndex < self.endIndex {
            let endIndex = self.index(startIndex, offsetBy: size, limitedBy: self.endIndex) ?? self.endIndex
            result.append(self[startIndex..<endIndex])
            startIndex = endIndex
        }
        
        return result
    }
}

// MARK: - Preview

struct StreamingResponseView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Example 1: Streaming
            VStack(alignment: .leading, spacing: 20) {
                Text("Streaming Example")
                    .font(DesignSystem.Typography.title2)
                
                StreamingResponseView(
                    text: "This is a streaming response that simulates text being received gradually.",
                    isStreaming: true
                )
                .padding()
                .background(DesignSystem.Colors.secondaryBackground)
                .cornerRadius(DesignSystem.Radius.medium)
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Streaming")
            
            // Example 2: Complete
            VStack(alignment: .leading, spacing: 20) {
                Text("Complete Response")
                    .font(DesignSystem.Typography.title2)
                
                StreamingResponseView(
                    text: "This is a completed response with no more incoming text.",
                    isStreaming: false
                )
                .padding()
                .background(DesignSystem.Colors.secondaryBackground)
                .cornerRadius(DesignSystem.Radius.medium)
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Complete")
            
            // Example 3: Custom styling
            VStack(alignment: .leading, spacing: 20) {
                Text("Custom Styling")
                    .font(DesignSystem.Typography.title2)
                
                StreamingResponseView(
                    text: "This response has custom cursor color and faster animation speed.",
                    isStreaming: true,
                    animationSpeed: 1.5,
                    cursorColor: .red
                )
                .font(DesignSystem.Typography.title3)
                .foregroundColor(.blue)
                .padding()
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(DesignSystem.Radius.medium)
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Custom Styling")
            
            // Example 4: No cursor
            VStack(alignment: .leading, spacing: 20) {
                Text("No Cursor")
                    .font(DesignSystem.Typography.title2)
                
                StreamingResponseView(
                    text: "This streaming response has the cursor hidden.",
                    isStreaming: true,
                    showCursor: false
                )
                .padding()
                .background(DesignSystem.Colors.secondaryBackground)
                .cornerRadius(DesignSystem.Radius.medium)
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("No Cursor")
            
            // Example 5: Dark Mode
            VStack(alignment: .leading, spacing: 20) {
                Text("Dark Mode")
                    .font(DesignSystem.Typography.title2)
                
                StreamingResponseView(
                    text: "This is how streaming responses look in dark mode.",
                    isStreaming: true
                )
                .padding()
                .background(DesignSystem.Colors.secondaryBackground)
                .cornerRadius(DesignSystem.Radius.medium)
            }
            .padding()
            .background(DesignSystem.Colors.background)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Dark Mode")
            .preferredColorScheme(.dark)
        }
    }
}
