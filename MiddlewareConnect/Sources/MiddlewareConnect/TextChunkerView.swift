/**
@fileoverview Text Chunker for splitting text into manageable chunks for LLM processing
@module TextChunkerView
Created: 2025-04-01
Last Modified: 2025-04-01
Dependencies:
- SwiftUI
Exports:
- TextChunkerView
/

import SwiftUI
import UniformTypeIdentifiers

struct TextChunkerView: View {
    // MARK: - State Variables
    @State private var inputText: String = ""
    @State private var outputChunks: [TextChunk] = []
    @State private var chunkSize: Int = 500
    @State private var overlapSize: Int = 50
    @State private var chunkMethod: ChunkMethod = .byTokens
    @State private var separator: ChunkSeparator = .paragraph
    @State private var customSeparator: String = "\\n"
    @State private var isProcessing: Bool = false
    @State private var isShowingFileImporter: Bool = false
    @State private var showInfo: Bool = false
    @State private var showCopiedToast: Bool = false
    @State private var copiedChunkIndex: Int? = nil
    @State private var estimatedTokenCount: Int = 0
    @State private var totalTokenCount: Int = 0
    
    // File handling states
    @State private var fileText: String = ""
    @State private var isFileLoaded: Bool = false
    @State private var fileName: String = ""
    
    // MARK: - Enums
    enum ChunkMethod: String, CaseIterable, Identifiable {
        case byTokens = "By Tokens/Characters"
        case bySeparator = "By Separator"
        case bySentences = "By Sentences"
        
        var id: String { self.rawValue }
    }
    
    enum ChunkSeparator: String, CaseIterable, Identifiable {
        case paragraph = "Paragraphs"
        case sentence = "Sentences"
        case line = "Lines"
        case custom = "Custom"
        
        var id: String { self.rawValue }
        
        var separator: String {
            switch self {
            case .paragraph: return "\\n\\s*\\n"
            case .sentence: return "(?<=[.!?])\\s+"
            case .line: return "\\n"
            case .custom: return ""
            }
        }
    }
    
    struct TextChunk: Identifiable {
        let id = UUID()
        let text: String
        let number: Int
        let tokenEstimate: Int
    }
    
    // MARK: - Computed Properties
    var buttonDisabled: Bool {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var textSource: String {
        isFileLoaded ? fileText : inputText
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "text.insert")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    Text("Text Chunker")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        showInfo.toggle()
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.bottom, 5)
                
                Text("Split long text into smaller chunks for optimal LLM processing")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
                // Text Input Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("1. Input Text")
                        .font(.headline)
                    
                    if isFileLoaded {
                        // Show file info if loaded
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text(fileName)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Button(action: {
                                isFileLoaded = false
                                fileName = ""
                                fileText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        
                        Text("File Content Preview:")
                            .font(.subheadline)
                            .padding(.top, 5)
                        
                        ScrollView {
                            Text(fileText.prefix(500))
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .frame(minHeight: 100, maxHeight: 150)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                        }
                        
                        if fileText.count > 500 {
                            Text("... (file truncated for preview)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 2)
                        }
                    } else {
                        // Show text input
                        TextEditor(text: $inputText)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 200)
                            .padding(5)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Estimated token count
                    if !textSource.isEmpty {
                        HStack {
                            Text("Estimated tokens: \(estimateTokens(for: textSource))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(textSource.count) characters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 5)
                    }
                    
                    // File import button
                    Button(action: {
                        isShowingFileImporter = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text(isFileLoaded ? "Import Different File" : "Import Text File")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                    }
                }
                .padding(.vertical)
                
                // Chunking Options Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("2. Chunking Options")
                        .font(.headline)
                    
                    Picker("Chunking Method", selection: $chunkMethod) {
                        ForEach(ChunkMethod.allCases) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Different options based on chunk method
                    if chunkMethod == .byTokens {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("Chunk Size (tokens):")
                                Spacer()
                                Text("\(chunkSize)")
                            }
                            
                            Slider(value: Binding(
                                get: { Double(chunkSize) },
                                set: { chunkSize = Int($0) }
                            ), in: 100...2000, step: 100)
                            
                            HStack {
                                Text("Overlap Size (tokens):")
                                Spacer()
                                Text("\(overlapSize)")
                            }
                            
                            Slider(value: Binding(
                                get: { Double(overlapSize) },
                                set: { overlapSize = Int($0) }
                            ), in: 0...500, step: 10)
                        }
                    } else if chunkMethod == .bySeparator {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Separate by:")
                            
                            Picker("Separator", selection: $separator) {
                                ForEach(ChunkSeparator.allCases) { sep in
                                    Text(sep.rawValue).tag(sep)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            if separator == .custom {
                                TextField("Custom separator (regex)", text: $customSeparator)
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                            }
                        }
                    } else if chunkMethod == .bySentences {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("Sentences per chunk:")
                                Spacer()
                                Text("\(chunkSize/20)")
                            }
                            
                            Slider(value: Binding(
                                get: { Double(chunkSize/20) },
                                set: { chunkSize = Int($0) * 20 }
                            ), in: 1...25, step: 1)
                            
                            HStack {
                                Text("Overlap (sentences):")
                                Spacer()
                                Text("\(overlapSize/20)")
                            }
                            
                            Slider(value: Binding(
                                get: { Double(overlapSize/20) },
                                set: { overlapSize = Int($0) * 20 }
                            ), in: 0...10, step: 1)
                        }
                    }
                    
                    // Process button
                    Button(action: {
                        processText()
                    }) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Process Text")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(buttonDisabled || isProcessing)
                    .opacity(buttonDisabled ? 0.5 : 1.0)
                }
                .padding(.vertical)
                
                // Results Section
                if !outputChunks.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("3. Chunked Results")
                            .font(.headline)
                        
                        HStack {
                            Text("Total chunks: \(outputChunks.count)")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("Est. total tokens: \(totalTokenCount)")
                                .font(.subheadline)
                        }
                        .foregroundColor(.secondary)
                        
                        ForEach(outputChunks) { chunk in
                            ChunkView(chunk: chunk, copiedChunkIndex: $copiedChunkIndex)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Text Chunker")
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [UTType.plainText, UTType.text],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile = try result.get().first else { return }
                
                if selectedFile.startAccessingSecurityScopedResource() {
                    defer { selectedFile.stopAccessingSecurityScopedResource() }
                    
                    if let data = try? Data(contentsOf: selectedFile),
                       let content = String(data: data, encoding: .utf8) {
                        fileText = content
                        fileName = selectedFile.lastPathComponent
                        isFileLoaded = true
                        estimatedTokenCount = estimateTokens(for: fileText)
                    }
                }
            } catch {
                print("Error loading file: \(error.localizedDescription)")
            }
        }
        .alert(isPresented: $showInfo) {
            Alert(
                title: Text("About Text Chunking"),
                message: Text("Text chunking divides long text into smaller pieces for LLM processing. This helps overcome token limits and can improve results by focusing on relevant sections.\n\nMethods:\n• Tokens/Characters: Fixed size chunks\n• Separator: Split at natural breaks\n• Sentences: Maintain sentence integrity"),
                dismissButton: .default(Text("Got it"))
            )
        }
        .overlay(
            // Copied toast
            showCopiedToast ?
            VStack {
                Spacer()
                Text("Chunk copied to clipboard")
                    .padding()
                    .background(Color.gray.opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.bottom, 20)
            }
            : nil
        )
        .onChange(of: showCopiedToast) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showCopiedToast = false
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func processText() {
        guard !textSource.isEmpty else { return }
        
        isProcessing = true
        outputChunks = []
        
        // Use background thread for processing
        DispatchQueue.global(qos: .userInitiated).async {
            switch chunkMethod {
            case .byTokens:
                let chunks = chunkByTokens(text: textSource, size: chunkSize, overlap: overlapSize)
                DispatchQueue.main.async {
                    outputChunks = chunks
                    isProcessing = false
                    calculateTotalTokens()
                }
                
            case .bySeparator:
                let actualSeparator = separator == .custom ? customSeparator : separator.separator
                let chunks = chunkBySeparator(text: textSource, separator: actualSeparator)
                DispatchQueue.main.async {
                    outputChunks = chunks
                    isProcessing = false
                    calculateTotalTokens()
                }
                
            case .bySentences:
                let sentencesPerChunk = chunkSize / 20 // Convert slider value to sentence count
                let overlapSentences = overlapSize / 20
                let chunks = chunkBySentences(text: textSource, sentencesPerChunk: sentencesPerChunk, overlapSentences: overlapSentences)
                DispatchQueue.main.async {
                    outputChunks = chunks
                    isProcessing = false
                    calculateTotalTokens()
                }
            }
        }
    }
    
    private func calculateTotalTokens() {
        totalTokenCount = outputChunks.reduce(0) { $0 + $1.tokenEstimate }
    }
    
    private func chunkByTokens(text: String, size: Int, overlap: Int) -> [TextChunk] {
        var chunks: [TextChunk] = []
        
        // Convert token sizes to approximate character counts (rough estimate)
        let charSize = size * 4
        let charOverlap = overlap * 4
        
        // If text is shorter than a single chunk, return it as is
        if text.count <= charSize {
            let tokenCount = estimateTokens(for: text)
            return [TextChunk(text: text, number: 1, tokenEstimate: tokenCount)]
        }
        
        var startIndex = text.startIndex
        var chunkNumber = 1
        
        while startIndex < text.endIndex {
            // Calculate end index for the current chunk
            let endDistance = min(charSize, text.distance(from: startIndex, to: text.endIndex))
            let potentialEndIndex = text.index(startIndex, offsetBy: endDistance)
            
            // Try to find a good breaking point (whitespace)
            var endIndex = potentialEndIndex
            
            // Only look for a better break point if we're not at the end of the text
            if potentialEndIndex < text.endIndex {
                // Try to find whitespace to break at
                let searchStartIndex = text.index(potentialEndIndex, offsetBy: -min(50, endDistance))
                
                // Find the last whitespace in the search range by manually iterating backward
                var i = potentialEndIndex
                while i > searchStartIndex {
                    i = text.index(before: i)
                    if text[i].isWhitespace {
                        endIndex = text.index(after: i)
                        break
                    }
                }
            }
            
            // Extract the chunk text
            let chunkText = String(text[startIndex..<endIndex])
            
            // Calculate tokens for this chunk
            let tokenCount = estimateTokens(for: chunkText)
            
            // Add to result
            chunks.append(TextChunk(text: chunkText, number: chunkNumber, tokenEstimate: tokenCount))
            
            // Move start index for next chunk, considering overlap
            if charOverlap > 0 && endIndex < text.endIndex {
                let overlapDistance = min(charOverlap, text.distance(from: startIndex, to: endIndex))
                startIndex = text.index(endIndex, offsetBy: -overlapDistance)
            } else {
                startIndex = endIndex
            }
            
            chunkNumber += 1
        }
        
        return chunks
    }
    
    private func chunkBySeparator(text: String, separator: String) -> [TextChunk] {
        var chunks: [TextChunk] = []
        
        do {
            let regex = try NSRegularExpression(pattern: separator)
            let nsString = text as NSString
            
            // Find all matches
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            
            // If no separators found, return the whole text
            if matches.isEmpty {
                let tokenCount = estimateTokens(for: text)
                return [TextChunk(text: text, number: 1, tokenEstimate: tokenCount)]
            }
            
            // Add ranges between separators
            var lastEnd = 0
            for (index, match) in matches.enumerated() {
                if match.range.location > lastEnd {
                    let range = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                    let chunkText = nsString.substring(with: range).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if !chunkText.isEmpty {
                        let tokenCount = estimateTokens(for: chunkText)
                        chunks.append(TextChunk(text: chunkText, number: index + 1, tokenEstimate: tokenCount))
                    }
                }
                lastEnd = match.range.location + match.range.length
            }
            
            // Add the last chunk if needed
            if lastEnd < nsString.length {
                let range = NSRange(location: lastEnd, length: nsString.length - lastEnd)
                let chunkText = nsString.substring(with: range).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !chunkText.isEmpty {
                    let tokenCount = estimateTokens(for: chunkText)
                    chunks.append(TextChunk(text: chunkText, number: chunks.count + 1, tokenEstimate: tokenCount))
                }
            }
        } catch {
            print("Regex error: \(error.localizedDescription)")
            
            // Fallback to basic chunking if regex fails
            let tokenCount = estimateTokens(for: text)
            chunks = [TextChunk(text: text, number: 1, tokenEstimate: tokenCount)]
        }
        
        return chunks
    }
    
    private func chunkBySentences(text: String, sentencesPerChunk: Int, overlapSentences: Int) -> [TextChunk] {
        // First split text into sentences
        let sentences = extractSentences(from: text)
        
        // If text has fewer sentences than requested per chunk, return it as is
        if sentences.count <= sentencesPerChunk {
            let tokenCount = estimateTokens(for: text)
            return [TextChunk(text: text, number: 1, tokenEstimate: tokenCount)]
        }
        
        var chunks: [TextChunk] = []
        var chunkNumber = 1
        
        var index = 0
        while index < sentences.count {
            let endIndex = min(index + sentencesPerChunk, sentences.count)
            let chunkSentences = Array(sentences[index..<endIndex])
            let chunkText = chunkSentences.joined(separator: " ")
            
            let tokenCount = estimateTokens(for: chunkText)
            chunks.append(TextChunk(text: chunkText, number: chunkNumber, tokenEstimate: tokenCount))
            
            // Move to next chunk, considering overlap
            index = endIndex - overlapSentences
            if index <= 0 {
                index = endIndex // Prevent infinite loop for small chunks
            }
            
            chunkNumber += 1
        }
        
        return chunks
    }
    
    private func extractSentences(from text: String) -> [String] {
        // Use a simple regex for sentence extraction
        // This is simplified; a more sophisticated algorithm might be needed for best results
        do {
            let regex = try NSRegularExpression(pattern: "([^.!?]+[.!?]+)")
            let nsString = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            
            var sentences: [String] = []
            for match in matches {
                let sentenceText = nsString.substring(with: match.range).trimmingCharacters(in: .whitespacesAndNewlines)
                if !sentenceText.isEmpty {
                    sentences.append(sentenceText)
                }
            }
            
            // If no sentences were found (regex failed), just return the whole text as one sentence
            if sentences.isEmpty && !text.isEmpty {
                sentences = [text]
            }
            
            return sentences
        } catch {
            print("Regex error: \(error.localizedDescription)")
            return [text]
        }
    }
    
    // Simple token estimator (more accurate estimators would be used in production)
    private func estimateTokens(for text: String) -> Int {
        // A simple rough estimate: ~4 characters per token for English text
        // This is a simplification - real token counts vary by model and text content
        return max(1, Int(Double(text.count) / 4.0))
    }
}

// MARK: - ChunkView Component

struct ChunkView: View {
    let chunk: TextChunkerView.TextChunk
    @Binding var copiedChunkIndex: Int?
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Chunk \(chunk.number)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(chunk.tokenEstimate) tokens")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content
            if isExpanded {
                Text(chunk.text)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                
                // Buttons
                HStack {
                    Button(action: {
                        copyToClipboard(text: chunk.text)
                        copiedChunkIndex = chunk.number
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        shareText(text: chunk.text)
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Spacer to push stats to the right
                    Spacer()
                    
                    Text("\(chunk.text.count) chars")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private func copyToClipboard(text: String) {
        UIPasteboard.general.string = text
    }
    
    private func shareText(text: String) {
        let activityViewController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityViewController, animated: true)
        }
    }
}

struct TextChunkerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TextChunkerView()
        }
    }
}
