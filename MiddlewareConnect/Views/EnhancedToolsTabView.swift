import SwiftUI
import Foundation

/// Fixed Tools Tab View for browsing and discovering app tools
struct EnhancedToolsTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Text Processing")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    toolCard(
                        name: "Text Chunker",
                        icon: "doc.text.magnifyingglass",
                        description: "Split long text into smaller chunks for processing with LLMs",
                        color: .blue,
                        destination: .text
                    )
                    
                    toolCard(
                        name: "Text Cleaner",
                        icon: "pencil.and.outline",
                        description: "Clean and format text by removing extra spaces, formatting, and more",
                        color: .blue,
                        destination: .textClean
                    )
                    
                    toolCard(
                        name: "Markdown Converter",
                        icon: "doc.plaintext",
                        description: "Convert between Markdown and other formats with AI assistance",
                        color: .blue,
                        destination: .markdown,
                        isNew: true
                    )
                }
                .padding(.horizontal)
                
                Text("PDF Tools")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    toolCard(
                        name: "PDF Combiner",
                        icon: "doc.on.doc",
                        description: "Merge multiple PDF files into a single document",
                        color: .red,
                        destination: .pdfCombine
                    )
                    
                    toolCard(
                        name: "PDF Splitter",
                        icon: "doc.on.doc.fill",
                        description: "Split large PDF files into smaller documents by pages",
                        color: .red,
                        destination: .pdfSplit
                    )
                }
                .padding(.horizontal)
                
                Text("Data Formatting")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    toolCard(
                        name: "CSV Formatter",
                        icon: "tablecells",
                        description: "Format, clean, and convert CSV data for analysis",
                        color: .purple,
                        destination: .csv
                    )
                    
                    toolCard(
                        name: "Image Splitter",
                        icon: "photo.on.rectangle",
                        description: "Split images into smaller tiles for processing",
                        color: .pink,
                        destination: .image,
                        isNew: true
                    )
                }
                .padding(.horizontal)
                
                Text("Analysis Tools")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    toolCard(
                        name: "Token Cost Calculator",
                        icon: "dollarsign.circle",
                        description: "Calculate the cost of API calls based on token count",
                        color: .orange,
                        destination: .tokenCost
                    )
                    
                    toolCard(
                        name: "Context Visualizer",
                        icon: "arrow.up.left.and.arrow.down.right",
                        description: "Visualize token usage within the context window",
                        color: .indigo,
                        destination: .contextViz,
                        isNew: true
                    )
                }
                .padding(.horizontal)
                
                Spacer(minLength: 50)
            }
            .padding(.vertical)
        }
        .onAppear {
            print("Simple EnhancedToolsTabView appeared")
        }
    }
    
    // Tool card for grid view
    private func toolCard(name: String, icon: String, description: String, color: Color, destination: Tab, isNew: Bool = false) -> some View {
        Button {
            print("Setting activeTab to: \(destination)")
            appState.activeTab = destination
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Icon with circle background
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                
                // Tool name and NEW badge if applicable
                HStack {
                    Text(name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if isNew {
                        Text("NEW")
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                }
                
                // Tool description
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(height: 45, alignment: .top)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 170)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}