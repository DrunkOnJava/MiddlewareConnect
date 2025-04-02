/**
 * @fileoverview Text chunking tool view
 * @module TextChunkerView
 * 
 * Created: 2025-03-29
 * Last Modified: 2025-03-29
 * 
 * Dependencies:
 * - SwiftUI
 * 
 * Exports:
 * - TextChunkerView struct
 */

import SwiftUI

/// View for text chunking functionality
struct TextChunkerView: View {
    @State private var inputText: String = ""
    @State private var chunkSize: Int = 4000
    @State private var overlap: Int = 200
    @State private var outputChunks: [String] = []
    @State private var isProcessing: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Text Chunker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Split long text into smaller chunks with optional overlap for processing with LLMs")
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
                // Input area
                VStack(alignment: .leading, spacing: 8) {
                    Text("Input Text")
                        .font(.headline)
                    
                    TextEditor(text: $inputText)
                        .frame(height: 200)
                        .padding(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    HStack {
                        Button("Clear") {
                            inputText = ""
                        }
                        .disabled(inputText.isEmpty)
                        
                        Spacer()
                        
                        Text("\(inputText.count) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Settings
                VStack(alignment: .leading, spacing: 8) {
                    Text("Chunking Settings")
                        .font(.headline)
                    
                    Stepper("Chunk Size: \(chunkSize)", value: $chunkSize, in: 1000...8000, step: 500)
                    
                    Stepper("Overlap: \(overlap)", value: $overlap, in: 0...1000, step: 50)
                    
                    Text("Each chunk will contain up to \(chunkSize) characters with \(overlap) characters of overlap between chunks.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical)
                
                // Process button
                Button(action: processText) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Process Text")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .disabled(inputText.isEmpty || isProcessing)
                
                // Results
                if !outputChunks.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Results (\(outputChunks.count) chunks)")
                            .font(.headline)
                            .padding(.top)
                        
                        ForEach(0..<outputChunks.count, id: \.self) { index in
                            ChunkView(index: index, content: outputChunks[index])
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    /// Process the input text into chunks
    private func processText() {
        guard !inputText.isEmpty else { return }
        
        isProcessing = true
        outputChunks = []
        
        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Split text into chunks
            let characters = Array(inputText)
            var currentIndex = 0
            
            while currentIndex < characters.count {
                let endIndex = min(currentIndex + chunkSize, characters.count)
                let chunk = String(characters[currentIndex..<endIndex])
                outputChunks.append(chunk)
                
                currentIndex = endIndex - overlap
                if currentIndex < 0 || currentIndex >= characters.count {
                    break
                }
            }
            
            isProcessing = false
        }
    }
}

/// View for displaying a text chunk
struct ChunkView: View {
    let index: Int
    let content: String
    
    @State private var isCopied: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Chunk \(index + 1)")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    UIPasteboard.general.string = content
                    isCopied = true
                    
                    // Reset the copied state after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isCopied = false
                    }
                }) {
                    Label(isCopied ? "Copied!" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.borderless)
            }
            
            Text(content)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            Text("\(content.count) characters")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
        }
    }
}
