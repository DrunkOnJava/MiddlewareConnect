import SwiftUI

/// View for cleaning and formatting text
struct TextCleanerView: View {
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var removeExtraSpaces: Bool = true
    @State private var removeExtraNewlines: Bool = true
    @State private var normalizeQuotes: Bool = true
    @State private var fixCommonTypos: Bool = true
    @State private var trimWhitespace: Bool = true
    @State private var convertToLowercase: Bool = false
    @State private var convertToUppercase: Bool = false
    @State private var copiedOutput: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Input Text Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Input Text")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(inputText.count) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    TextEditor(text: $inputText)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 200)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                        .onChange(of: inputText) { _ in
                            cleanText()
                        }
                }
                
                // Cleaning Options
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cleaning Options")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Remove extra spaces", isOn: $removeExtraSpaces)
                            .onChange(of: removeExtraSpaces) { _ in cleanText() }
                        
                        Toggle("Remove extra newlines", isOn: $removeExtraNewlines)
                            .onChange(of: removeExtraNewlines) { _ in cleanText() }
                        
                        Toggle("Normalize quotes", isOn: $normalizeQuotes)
                            .onChange(of: normalizeQuotes) { _ in cleanText() }
                        
                        Toggle("Fix common typos", isOn: $fixCommonTypos)
                            .onChange(of: fixCommonTypos) { _ in cleanText() }
                        
                        Toggle("Trim whitespace", isOn: $trimWhitespace)
                            .onChange(of: trimWhitespace) { _ in cleanText() }
                    }
                    
                    HStack {
                        Toggle("Convert to lowercase", isOn: $convertToLowercase)
                            .onChange(of: convertToLowercase) { newValue in
                                if newValue {
                                    convertToUppercase = false
                                }
                                cleanText()
                            }
                        
                        Spacer()
                        
                        Toggle("Convert to UPPERCASE", isOn: $convertToUppercase)
                            .onChange(of: convertToUppercase) { newValue in
                                if newValue {
                                    convertToLowercase = false
                                }
                                cleanText()
                            }
                    }
                }
                
                Divider()
                
                // Output Text Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Cleaned Output")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(outputText.count) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            copyOutputToClipboard()
                        }) {
                            Label(
                                copiedOutput ? "Copied" : "Copy",
                                systemImage: copiedOutput ? "checkmark" : "doc.on.doc"
                            )
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    if outputText.isEmpty {
                        Text("Enter text in the input area to see the cleaned output")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        TextEditor(text: .constant(outputText))
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 200)
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                            .disabled(true)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Text Cleaner")
    }
    
    private func cleanText() {
        guard !inputText.isEmpty else {
            outputText = ""
            return
        }
        
        var cleanedText = inputText
        
        // Apply selected cleaning operations
        if trimWhitespace {
            cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if removeExtraSpaces {
            // Replace multiple spaces with a single space
            cleanedText = cleanedText.replacingOccurrences(
                of: "[ \\t]+",
                with: " ",
                options: .regularExpression
            )
        }
        
        if removeExtraNewlines {
            // Replace multiple newlines with a single newline
            cleanedText = cleanedText.replacingOccurrences(
                of: "\\n{3,}",
                with: "\n\n",
                options: .regularExpression
            )
        }
        
        if normalizeQuotes {
            // Replace curly quotes with straight quotes
            cleanedText = cleanedText.replacingOccurrences(of: """, with: "\"")
            cleanedText = cleanedText.replacingOccurrences(of: """, with: "\"")
            cleanedText = cleanedText.replacingOccurrences(of: "'", with: "'")
            cleanedText = cleanedText.replacingOccurrences(of: "'", with: "'")
        }
        
        if fixCommonTypos {
            // Fix common typos
            let typoFixes: [String: String] = [
                "teh": "the",
                "adn": "and",
                "waht": "what",
                "taht": "that",
                "thier": "their",
                "recieve": "receive",
                "seperate": "separate",
                "definately": "definitely",
                "occured": "occurred",
                "untill": "until",
                "accross": "across",
                "acheive": "achieve",
                "beleive": "believe",
                "concious": "conscious",
                "foriegn": "foreign",
                "occassion": "occasion",
                "publically": "publicly",
                "refered": "referred",
                "wierd": "weird"
            ]
            
            for (typo, correction) in typoFixes {
                // Use word boundaries to only replace whole words
                let pattern = "\\b\(typo)\\b"
                cleanedText = cleanedText.replacingOccurrences(
                    of: pattern,
                    with: correction,
                    options: .regularExpression
                )
            }
        }
        
        if convertToLowercase {
            cleanedText = cleanedText.lowercased()
        } else if convertToUppercase {
            cleanedText = cleanedText.uppercased()
        }
        
        outputText = cleanedText
    }
    
    private func copyOutputToClipboard() {
        UIPasteboard.general.string = outputText
        copiedOutput = true
        
        // Reset the "Copied" status after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedOutput = false
        }
        
        // Show a haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

struct TextCleanerView_Previews: PreviewProvider {
    static var previews: some View {
        TextCleanerView()
    }
}