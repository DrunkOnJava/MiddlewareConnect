/**
 * @fileoverview Markdown Converter for converting between markdown and other formats
 * @module MarkdownConverterView
 * 
 * Created: 2025-04-01
 * Last Modified: 2025-04-01
 * 
 * Dependencies:
 * - SwiftUI
 * - WebKit
 * 
 * Exports:
 * - MarkdownConverterView
 */

import SwiftUI
import WebKit
import UniformTypeIdentifiers

struct MarkdownConverterView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var appState: AppState
    
    // MARK: - State Variables
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var selectedConversion: ConversionType = .markdownToHTML
    @State private var showPreview: Bool = false
    @State private var isConverting: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isImporting: Bool = false
    @State private var isExporting: Bool = false
    @State private var showReferenceGuide: Bool = false
    @State private var fileName: String = ""
    @State private var webViewHeight: CGFloat = 200
    @State private var selectedRenderingStyle: RenderingStyle = .github
    
    // MARK: - Enums
    
    enum ConversionType: String, CaseIterable, Identifiable {
        case markdownToHTML = "Markdown → HTML"
        case htmlToMarkdown = "HTML → Markdown"
        case markdownToPlainText = "Markdown → Plain Text"
        case textToMarkdown = "Text → Markdown"
        
        var id: String { self.rawValue }
        
        var description: String {
            switch self {
            case .markdownToHTML:
                return "Convert Markdown syntax to HTML code"
            case .htmlToMarkdown:
                return "Convert HTML code to Markdown syntax"
            case .markdownToPlainText:
                return "Strip Markdown formatting to plain text"
            case .textToMarkdown:
                return "Add Markdown formatting to plain text"
            }
        }
        
        var inputPlaceholder: String {
            switch self {
            case .markdownToHTML, .markdownToPlainText:
                return "# Enter Markdown here\n\nThis is a **bold** text with *italic* emphasis.\n\n- List item 1\n- List item 2"
            case .htmlToMarkdown:
                return "<h1>Enter HTML here</h1>\n\n<p>This is a <strong>bold</strong> text with <em>italic</em> emphasis.</p>\n\n<ul>\n  <li>List item 1</li>\n  <li>List item 2</li>\n</ul>"
            case .textToMarkdown:
                return "Title\n\nThis is a paragraph with important text and emphasized words.\n\n* Point one\n* Point two"
            }
        }
        
        var inputLabel: String {
            switch self {
            case .markdownToHTML, .markdownToPlainText:
                return "Markdown Input"
            case .htmlToMarkdown:
                return "HTML Input"
            case .textToMarkdown:
                return "Text Input"
            }
        }
        
        var outputLabel: String {
            switch self {
            case .markdownToHTML:
                return "HTML Output"
            case .htmlToMarkdown, .textToMarkdown:
                return "Markdown Output"
            case .markdownToPlainText:
                return "Plain Text Output"
            }
        }
    }
    
    enum RenderingStyle: String, CaseIterable, Identifiable {
        case github = "GitHub"
        case basic = "Basic"
        case documentation = "Documentation"
        case blog = "Blog"
        case custom = "Custom"
        
        var id: String { self.rawValue }
        
        var cssClassName: String {
            self.rawValue.lowercased()
        }
    }
    
    // MARK: - Computed Properties
    
    var isInputEmpty: Bool {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var showHTMLPreview: Bool {
        showPreview && selectedConversion == .markdownToHTML && !outputText.isEmpty
    }
    
    var previewHTML: String {
        // Add custom CSS based on selected style
        let styleCSS: String
        switch selectedRenderingStyle {
        case .github:
            styleCSS = """
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
                    font-size: 16px;
                    line-height: 1.6;
                    color: #24292e;
                    padding: 15px;
                }
                h1 { font-size: 2em; border-bottom: 1px solid #eaecef; padding-bottom: 0.3em; }
                h2 { font-size: 1.5em; border-bottom: 1px solid #eaecef; padding-bottom: 0.3em; }
                code { background-color: rgba(27,31,35,0.05); border-radius: 3px; padding: 0.2em 0.4em; }
                pre { background-color: #f6f8fa; border-radius: 3px; padding: 16px; overflow: auto; }
                blockquote { padding: 0 1em; color: #6a737d; border-left: 0.25em solid #dfe2e5; }
                table { border-collapse: collapse; width: 100%; }
                table th, table td { padding: 6px 13px; border: 1px solid #dfe2e5; }
                table tr { background-color: #fff; border-top: 1px solid #c6cbd1; }
                table tr:nth-child(2n) { background-color: #f6f8fa; }
                a { color: #0366d6; text-decoration: none; }
                a:hover { text-decoration: underline; }
                ul, ol { padding-left: 2em; }
            </style>
            """
        case .basic:
            styleCSS = """
            <style>
                body {
                    font-family: system-ui, -apple-system, sans-serif;
                    line-height: 1.5;
                    padding: 15px;
                    max-width: 800px;
                    margin: 0 auto;
                }
                code { background-color: #f0f0f0; padding: 0.2em; }
                pre { background-color: #f0f0f0; padding: 1em; overflow: auto; }
                blockquote { border-left: 3px solid #ccc; margin-left: 0; padding-left: 1em; }
            </style>
            """
        case .documentation:
            styleCSS = """
            <style>
                body {
                    font-family: 'SF Pro Display', -apple-system, sans-serif;
                    font-size: 15px;
                    line-height: 1.6;
                    color: #333;
                    padding: 15px;
                    max-width: 860px;
                    margin: 0 auto;
                }
                h1, h2, h3 { color: #0070c9; }
                h1 { font-size: 28px; border-bottom: 1px solid #e6e6e6; }
                h2 { font-size: 22px; }
                code { font-family: 'SF Mono', monospace; background-color: #f7f7f7; padding: 2px 4px; border-radius: 4px; }
                pre { background-color: #f7f7f7; border-radius: 4px; padding: 16px; overflow: auto; }
                pre code { background-color: transparent; padding: 0; }
                blockquote { margin-left: 0; padding-left: 1em; border-left: 4px solid #e6e6e6; color: #666; }
                table { width: 100%; border-collapse: collapse; margin: 1em 0; }
                table th { background-color: #f7f7f7; text-align: left; }
                table th, table td { padding: 8px; border: 1px solid #e6e6e6; }
                a { color: #0070c9; text-decoration: none; }
                a:hover { text-decoration: underline; }
                .note { background-color: #f7f7f7; padding: 1em; border-left: 4px solid #0070c9; margin: 1em 0; }
            </style>
            """
        case .blog:
            styleCSS = """
            <style>
                body {
                    font-family: 'Georgia', serif;
                    font-size: 18px;
                    line-height: 1.7;
                    color: #333;
                    padding: 15px;
                    max-width: 700px;
                    margin: 0 auto;
                }
                h1 { font-size: 36px; font-weight: normal; margin-top: 1.5em; }
                h2 { font-size: 28px; font-weight: normal; margin-top: 1.3em; }
                h3 { font-size: 22px; font-weight: normal; }
                p { margin-bottom: 1.5em; }
                code { font-family: 'Courier New', monospace; background-color: #f9f9f9; padding: 2px 4px; }
                pre { background-color: #f9f9f9; padding: 1em; overflow: auto; border-radius: 5px; }
                blockquote { font-style: italic; margin-left: 0; padding: 0 1em; border-left: 3px solid #ddd; color: #555; }
                a { color: #0066cc; text-decoration: none; border-bottom: 1px solid #ddd; }
                a:hover { border-bottom: 1px solid #0066cc; }
                img { max-width: 100%; height: auto; border-radius: 5px; }
            </style>
            """
        case .custom:
            styleCSS = """
            <style>
                body {
                    font-family: var(--font-family, system-ui);
                    font-size: var(--font-size, 16px);
                    line-height: var(--line-height, 1.6);
                    color: var(--text-color, #333);
                    background-color: var(--background-color, #fff);
                    padding: 15px;
                    max-width: var(--max-width, 800px);
                    margin: 0 auto;
                }
                h1, h2, h3 { color: var(--heading-color, #000); }
                code { background-color: var(--code-bg, #f5f5f5); padding: 0.2em 0.4em; }
                pre { background-color: var(--pre-bg, #f5f5f5); padding: 1em; overflow: auto; }
                blockquote { border-left: 4px solid var(--blockquote-border, #ddd); margin-left: 0; padding-left: 1em; }
                a { color: var(--link-color, #0366d6); }
                
                /* Custom theme variables - default to dark mode */
                :root {
                    --font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
                    --font-size: 16px;
                    --line-height: 1.6;
                    --text-color: #c9d1d9;
                    --background-color: #0d1117;
                    --heading-color: #e6edf3;
                    --code-bg: #161b22;
                    --pre-bg: #161b22;
                    --blockquote-border: #30363d;
                    --link-color: #58a6ff;
                    --max-width: 800px;
                }
                
                /* Apply light mode if prefers-light */
                @media (prefers-color-scheme: light) {
                    :root {
                        --text-color: #24292e;
                        --background-color: #ffffff;
                        --heading-color: #000000;
                        --code-bg: #f6f8fa;
                        --pre-bg: #f6f8fa;
                        --blockquote-border: #dfe2e5;
                        --link-color: #0366d6;
                    }
                }
            </style>
            """
        }
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            \(styleCSS)
        </head>
        <body>
            \(outputText)
        </body>
        </html>
        """
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "arrow.left.arrow.right.square")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    Text("Markdown Converter")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        showReferenceGuide.toggle()
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.bottom, 5)
                
                Text("Convert between Markdown and other text formats")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
                // Conversion Type Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("1. Conversion Type")
                        .font(.headline)
                    
                    Picker("Conversion Type", selection: $selectedConversion) {
                        ForEach(ConversionType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedConversion) { _ in
                        // Clear outputs when changing conversion type
                        if !isInputEmpty {
                            outputText = ""
                            showPreview = false
                        }
                    }
                    
                    Text(selectedConversion.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 5)
                
                // Input Text Area
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("2. \(selectedConversion.inputLabel)")
                            .font(.headline)
                        
                        Spacer()
                        
                        if !fileName.isEmpty {
                            HStack {
                                Image(systemName: "doc")
                                Text(fileName)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(6)
                        }
                        
                        Button(action: {
                            isImporting = true
                        }) {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    
                    // Text editor for input
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $inputText)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 200)
                            .padding(5)
                            .onChange(of: inputText) { _ in
                                // Clear output when input changes
                                outputText = ""
                                showPreview = false
                            }
                        
                        if inputText.isEmpty {
                            Text(selectedConversion.inputPlaceholder)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.gray)
                                .padding(10)
                                .allowsHitTesting(false)
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    
                    // Action buttons
                    HStack {
                        Button(action: {
                            convertText()
                        }) {
                            if isConverting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Convert")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isInputEmpty ? Color.gray.opacity(0.3) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(isInputEmpty || isConverting)
                        
                        Button(action: {
                            inputText = ""
                            outputText = ""
                            fileName = ""
                            showPreview = false
                        }) {
                            Text("Clear")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                        .disabled(isInputEmpty && outputText.isEmpty)
                    }
                }
                .padding(.vertical, 5)
                
                // Output Section (if there's output)
                if !outputText.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("3. \(selectedConversion.outputLabel)")
                                .font(.headline)
                            
                            Spacer()
                            
                            if selectedConversion == .markdownToHTML {
                                Picker("Style", selection: $selectedRenderingStyle) {
                                    ForEach(RenderingStyle.allCases) { style in
                                        Text(style.rawValue).tag(style)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .labelsHidden()
                                
                                Toggle(isOn: $showPreview) {
                                    Text("Preview")
                                        .font(.subheadline)
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                                .labelsHidden()
                            }
                            
                            Button(action: {
                                copyToClipboard(text: outputText)
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            Button(action: {
                                isExporting = true
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        
                        // Show either preview or raw output text
                        if showHTMLPreview {
                            // HTML Preview
                            MarkedHTMLView(html: previewHTML, dynamicHeight: $webViewHeight)
                                .frame(height: webViewHeight)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        } else {
                            // Raw output text
                            ScrollView {
                                Text(outputText)
                                    .font(.system(.body, design: .monospaced))
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .frame(height: 250)
                        }
                        
                        // Export options
                        HStack {
                            Button(action: {
                                inputText = outputText
                                outputText = ""
                                showPreview = false
                            }) {
                                HStack {
                                    Image(systemName: "arrow.up")
                                    Text("Use as Input")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                            
                            Button(action: {
                                isExporting = true
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Save")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
                
                // Additional Tools (if content exists)
                if !isInputEmpty && !outputText.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Additional Tools")
                            .font(.headline)
                        
                        HStack(spacing: 10) {
                            Button(action: {
                                appState.openInTextCleaner(text: outputText)
                            }) {
                                VStack {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 24))
                                    Text("Clean Text")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                            
                            Button(action: {
                                appState.openInTextChunker(text: outputText)
                            }) {
                                VStack {
                                    Image(systemName: "scissors")
                                        .font(.system(size: 24))
                                    Text("Chunk Text")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                            
                            Button(action: {
                                appState.openInContextVisualizer(text: outputText)
                            }) {
                                VStack {
                                    Image(systemName: "text.magnifyingglass")
                                        .font(.system(size: 24))
                                    Text("Visualize Context")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .padding()
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Conversion Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showReferenceGuide) {
                MarkdownReferenceGuideView()
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [UTType.plainText, UTType.markdown, UTType.html, UTType.text],
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let selectedFile = try result.get().first else { return }
                    
                    if selectedFile.startAccessingSecurityScopedResource() {
                        defer { selectedFile.stopAccessingSecurityScopedResource() }
                        
                        if let data = try? Data(contentsOf: selectedFile),
                           let content = String(data: data, encoding: .utf8) {
                            inputText = content
                            fileName = selectedFile.lastPathComponent
                            
                            // Auto-select conversion type based on file extension
                            if selectedFile.pathExtension.lowercased() == "md" || selectedFile.pathExtension.lowercased() == "markdown" {
                                selectedConversion = .markdownToHTML
                            } else if selectedFile.pathExtension.lowercased() == "html" || selectedFile.pathExtension.lowercased() == "htm" {
                                selectedConversion = .htmlToMarkdown
                            } else {
                                // Default to text to markdown for other text files
                                selectedConversion = .textToMarkdown
                            }
                        }
                    }
                } catch {
                    errorMessage = "Error importing file: \(error.localizedDescription)"
                    showError = true
                }
            }
            .fileExporter(
                isPresented: $isExporting,
                document: TextFileDocument(text: outputText),
                contentType: getExportContentType(),
                defaultFilename: getDefaultExportFilename()
            ) { result in
                switch result {
                case .success:
                    print("File exported successfully")
                case .failure(let error):
                    errorMessage = "Error exporting file: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
        .navigationTitle("Markdown Converter")
    }
    
    // MARK: - Methods
    
    private func convertText() {
        guard !isInputEmpty else { return }
        
        isConverting = true
        
        // Use background thread for processing
        DispatchQueue.global(qos: .userInitiated).async {
            var result = ""
            var error: Error? = nil
            
            do {
                switch selectedConversion {
                case .markdownToHTML:
                    result = try convertMarkdownToHTML(inputText)
                case .htmlToMarkdown:
                    result = try convertHTMLToMarkdown(inputText)
                case .markdownToPlainText:
                    result = try convertMarkdownToPlainText(inputText)
                case .textToMarkdown:
                    result = try convertTextToMarkdown(inputText)
                }
            } catch let conversionError {
                error = conversionError
            }
            
            DispatchQueue.main.async {
                isConverting = false
                
                if let error = error {
                    errorMessage = "Conversion error: \(error.localizedDescription)"
                    showError = true
                } else {
                    outputText = result
                    
                    // Auto-show preview for HTML output
                    if selectedConversion == .markdownToHTML {
                        showPreview = true
                    }
                }
            }
        }
    }
    
    private func convertMarkdownToHTML(_ markdown: String) throws -> String {
        // For a real app, use a proper Markdown parser library
        // This is a simplified implementation for demonstration
        
        var html = markdown
        
        // Headers
        let headerRegexes = [
            try NSRegularExpression(pattern: "^# (.+)$", options: [.anchorsMatchLines]),
            try NSRegularExpression(pattern: "^## (.+)$", options: [.anchorsMatchLines]),
            try NSRegularExpression(pattern: "^### (.+)$", options: [.anchorsMatchLines]),
            try NSRegularExpression(pattern: "^#### (.+)$", options: [.anchorsMatchLines]),
            try NSRegularExpression(pattern: "^##### (.+)$", options: [.anchorsMatchLines]),
            try NSRegularExpression(pattern: "^###### (.+)$", options: [.anchorsMatchLines])
        ]
        
        for (i, regex) in headerRegexes.enumerated() {
            let level = i + 1
            html = regex.stringByReplacingMatches(
                in: html,
                options: [],
                range: NSRange(location: 0, length: html.utf16.count),
                withTemplate: "<h\(level)>$1</h\(level)>"
            )
        }
        
        // Bold
        let boldRegex = try NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*", options: [])
        html = boldRegex.stringByReplacingMatches(
            in: html,
            options: [],
            range: NSRange(location: 0, length: html.utf16.count),
            withTemplate: "<strong>$1</strong>"
        )
        
        // Italic
        let italicRegex = try NSRegularExpression(pattern: "\\*(.+?)\\*", options: [])
        html = italicRegex.stringByReplacingMatches(
            in: html,
            options: [],
            range: NSRange(location: 0, length: html.utf16.count),
            withTemplate: "<em>$1</em>"
        )
        
        // Unordered lists
        let ulItemRegex = try NSRegularExpression(pattern: "^- (.+)$", options: [.anchorsMatchLines])
        let ulMatches = ulItemRegex.matches(
            in: html,
            options: [],
            range: NSRange(location: 0, length: html.utf16.count)
        )
        
        if !ulMatches.isEmpty {
            // Group list items
            let listPattern = "(^- .+$\\n?)+"
            let listRegex = try NSRegularExpression(pattern: listPattern, options: [.anchorsMatchLines])
            
            html = listRegex.stringByReplacingMatches(
                in: html,
                options: [],
                range: NSRange(location: 0, length: html.utf16.count),
                withTemplate: "<ul>\n$0\n</ul>"
            )
            
            // Then replace individual items
            html = ulItemRegex.stringByReplacingMatches(
                in: html,
                options: [],
                range: NSRange(location: 0, length: html.utf16.count),
                withTemplate: "<li>$1</li>"
            )
        }
        
        // Links
        let linkRegex = try NSRegularExpression(pattern: "\\[(.+?)\\]\\((.+?)\\)", options: [])
        html = linkRegex.stringByReplacingMatches(
            in: html,
            options: [],
            range: NSRange(location: 0, length: html.utf16.count),
            withTemplate: "<a href=\"$2\">$1</a>"
        )
        
        // Code blocks
        let codeBlockRegex = try NSRegularExpression(pattern: "```(.+?)```", options: [.dotMatchesLineSeparators])
        html = codeBlockRegex.stringByReplacingMatches(
            in: html,
            options: [],
            range: NSRange(location: 0, length: html.utf16.count),
            withTemplate: "<pre><code>$1</code></pre>"
        )
        
        // Inline code
        let inlineCodeRegex = try NSRegularExpression(pattern: "`(.+?)`", options: [])
        html = inlineCodeRegex.stringByReplacingMatches(
            in: html,
            options: [],
            range: NSRange(location: 0, length: html.utf16.count),
            withTemplate: "<code>$1</code>"
        )
        
        // Blockquotes
        let blockquoteRegex = try NSRegularExpression(pattern: "^> (.+)$", options: [.anchorsMatchLines])
        html = blockquoteRegex.stringByReplacingMatches(
            in: html,
            options: [],
            range: NSRange(location: 0, length: html.utf16.count),
            withTemplate: "<blockquote>$1</blockquote>"
        )
        
        // Paragraphs (simple approach - this would need to be more sophisticated in a real app)
        let paragraphRegex = try NSRegularExpression(pattern: "([^\\n]+)\\n\\n", options: [])
        html = paragraphRegex.stringByReplacingMatches(
            in: html,
            options: [],
            range: NSRange(location: 0, length: html.utf16.count),
            withTemplate: "<p>$1</p>\n\n"
        )
        
        // Handle any remaining newlines as line breaks
        html = html.replacingOccurrences(of: "\n", with: "<br>")
        
        // Fix line breaks in code blocks
        let tagFixRegex = try NSRegularExpression(pattern: "<pre><code>(.+?)</code></pre>", options: [.dotMatchesLineSeparators])
        let nsHtml = html as NSString
        let tagMatches = tagFixRegex.matches(
            in: html,
            options: [],
            range: NSRange(location: 0, length: nsHtml.length)
        )
        
        var result = html
        for match in tagMatches.reversed() {
            let codeContent = nsHtml.substring(with: match.range(at: 1))
            let fixedContent = codeContent.replacingOccurrences(of: "<br>", with: "\n")
            let matchRange = match.range
            let replacementString = "<pre><code>\(fixedContent)</code></pre>"
            
            let nsResult = result as NSString
            result = nsResult.replacingCharacters(in: matchRange, with: replacementString)
        }
        
        return result
    }
    
    private func convertHTMLToMarkdown(_ html: String) throws -> String {
        // For a real app, use a proper HTML to Markdown converter library
        // This is a simplified implementation for demonstration
        
        var markdown = html
        
        // Headers
        for i in 1...6 {
            let headerRegex = try NSRegularExpression(pattern: "<h\(i)[^>]*>(.+?)</h\(i)>", options: [.dotMatchesLineSeparators, .caseInsensitive])
            let headerPrefix = String(repeating: "#", count: i)
            markdown = headerRegex.stringByReplacingMatches(
                in: markdown,
                options: [],
                range: NSRange(location: 0, length: markdown.utf16.count),
                withTemplate: "\(headerPrefix) $1\n\n"
            )
        }
        
        // Bold
        let boldRegex = try NSRegularExpression(pattern: "<(?:strong|b)[^>]*>(.+?)</(?:strong|b)>", options: [.dotMatchesLineSeparators, .caseInsensitive])
        markdown = boldRegex.stringByReplacingMatches(
            in: markdown,
            options: [],
            range: NSRange(location: 0, length: markdown.utf16.count),
            withTemplate: "**$1**"
        )
        
        // Italic
        let italicRegex = try NSRegularExpression(pattern: "<(?:em|i)[^>]*>(.+?)</(?:em|i)>", options: [.dotMatchesLineSeparators, .caseInsensitive])
        markdown = italicRegex.stringByReplacingMatches(
            in: markdown,
            options: [],
            range: NSRange(location: 0, length: markdown.utf16.count),
            withTemplate: "*$1*"
        )
        
        // Links
        let linkRegex = try NSRegularExpression(pattern: "<a[^>]*href=[\"']([^\"']+)[\"'][^>]*>(.+?)</a>", options: [.dotMatchesLineSeparators, .caseInsensitive])
        markdown = linkRegex.stringByReplacingMatches(
            in: markdown,
            options: [],
            range: NSRange(location: 0, length: markdown.utf16.count),
            withTemplate: "[$2]($1)"
        )
        
        // List items
        let listItemRegex = try NSRegularExpression(pattern: "<li[^>]*>(.+?)</li>", options: [.dotMatchesLineSeparators, .caseInsensitive])
        markdown = listItemRegex.stringByReplacingMatches(
            in: markdown,
            options: [],
            range: NSRange(location: 0, length: markdown.utf16.count),
            withTemplate: "- $1\n"
        )
        
        // Remove list containers
        let ulRegex = try NSRegularExpression(pattern: "<ul[^>]*>|</ul>", options: [.caseInsensitive])
        markdown = ulRegex.stringByReplacingMatches(
            in: markdown,
            options: [],
            range: NSRange(location: 0, length: markdown.utf16.count),
            withTemplate: ""
        )
        
        let olRegex = try NSRegularExpression(pattern: "<ol[^>]*>|</ol>", options: [.caseInsensitive])
        markdown = olRegex.stringByReplacingMatches(
            in: markdown,
            options: [],
            range: NSRange(location: 0, length: markdown.utf16.count),
            withTemplate: ""
        )
        
        // Code blocks
        let codeBlockRegex = try NSRegularExpression(pattern: "<pre[^>]*><code[^>]*>(.+?)</code></pre>", options: [.dotMatchesLineSeparators, .caseInsensitive])
        markdown = codeBlockRegex.stringByReplacingMatches(
            in: markdown,
            options: [],
            range: NSRange(location: 0, length: markdown.utf16.count),
            withTemplate: "```\n$1\n```\n\n"
        )
        
        // Inline code
        let inlineCodeRegex = try NSRegularExpression(pattern: "<code[^>]*>(.+?)</code>", options: [.dotMatchesLineSeparators, .caseInsensitive])
        markdown = inlineCodeRegex.stringByReplacingMatches(
            in: markdown,
            options: [],
            range: NSRange(location: 0, length: markdown.utf16.count),
            withTemplate: "`$1`"
        )
        
        // Blockquotes
        let blockquoteRegex = try NSRegularExpression(pattern: "<blockquote[^>]*>(.+?)</blockquote>", options: [.dotMatchesLineSeparators, .caseInsensitive])
        markdown = blockquoteRegex.stringByReplacingMatches(
            in: markdown,
            options: [],
            range: NSRange(location: 0, length: markdown.utf16.count),
            withTemplate: "> $1\n\n"
        )
        
        // Paragraphs
        let paragraphRegex = try NSRegularExpression(pattern: "<p[^>]*>(.+?)</p>", options: [.dotMatchesLineSeparators, .caseInsensitive])
        markdown = paragraphRegex.stringByReplacingMatches(
            in: markdown,
            options: [],
            range: NSRange(location: 0, length: markdown.utf16.count),
            withTemplate: "$1\n\n"
        )
        
        // Replace <br> with newlines
        let brRegex = try NSRegularExpression(pattern: "<br[^>]*>", options: [.caseInsensitive])
        markdown = brRegex.stringByReplacingMatches(
            in: markdown,
            options: [],
            range: NSRange(location: 0, length: markdown.utf16.count),
            withTemplate: "\n"
        )
        
        // Clean up any remaining HTML tags
        let htmlTagRegex = try NSRegularExpression(pattern: "<[^>]+>", options: [])
        markdown = htmlTagRegex.stringByReplacingMatches(
            in: markdown,
            options: [],
            range: NSRange(location: 0, length: markdown.utf16.count),
            withTemplate: ""
        )
        
        // Convert HTML entities
        markdown = markdown.replacingOccurrences(of: "&lt;", with: "<")
        markdown = markdown.replacingOccurrences(of: "&gt;", with: ">")
        markdown = markdown.replacingOccurrences(of: "&amp;", with: "&")
        markdown = markdown.replacingOccurrences(of: "&quot;", with: "\"")
        markdown = markdown.replacingOccurrences(of: "&#39;", with: "'")
        
        // Clean up excessive newlines
        while markdown.contains("\n\n\n") {
            markdown = markdown.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        
        return markdown
    }
    
    private func convertMarkdownToPlainText(_ markdown: String) throws -> String {
        // For a real app, use a proper Markdown parser library
        // This is a simplified implementation for demonstration
        
        var plainText = markdown
        
        // Remove headers formatting
        for i in 1...6 {
            let headerPrefix = String(repeating: "#", count: i)
            let headerRegex = try NSRegularExpression(pattern: "^\(headerPrefix) (.+)$", options: [.anchorsMatchLines])
            plainText = headerRegex.stringByReplacingMatches(
                in: plainText,
                options: [],
                range: NSRange(location: 0, length: plainText.utf16.count),
                withTemplate: "$1"
            )
        }
        
        // Remove bold formatting
        let boldRegex = try NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*", options: [])
        plainText = boldRegex.stringByReplacingMatches(
            in: plainText,
            options: [],
            range: NSRange(location: 0, length: plainText.utf16.count),
            withTemplate: "$1"
        )
        
        // Remove italic formatting
        let italicRegex = try NSRegularExpression(pattern: "\\*(.+?)\\*", options: [])
        plainText = italicRegex.stringByReplacingMatches(
            in: plainText,
            options: [],
            range: NSRange(location: 0, length: plainText.utf16.count),
            withTemplate: "$1"
        )
        
        // Replace links with just the text
        let linkRegex = try NSRegularExpression(pattern: "\\[(.+?)\\]\\(.+?\\)", options: [])
        plainText = linkRegex.stringByReplacingMatches(
            in: plainText,
            options: [],
            range: NSRange(location: 0, length: plainText.utf16.count),
            withTemplate: "$1"
        )
        
        // Remove list markers but keep the text
        let listItemRegex = try NSRegularExpression(pattern: "^- (.+)$", options: [.anchorsMatchLines])
        plainText = listItemRegex.stringByReplacingMatches(
            in: plainText,
            options: [],
            range: NSRange(location: 0, length: plainText.utf16.count),
            withTemplate: "$1"
        )
        
        // Clean up code blocks
        let codeBlockRegex = try NSRegularExpression(pattern: "```(.+?)```", options: [.dotMatchesLineSeparators])
        plainText = codeBlockRegex.stringByReplacingMatches(
            in: plainText,
            options: [],
            range: NSRange(location: 0, length: plainText.utf16.count),
            withTemplate: "$1"
        )
        
        // Clean up inline code
        let inlineCodeRegex = try NSRegularExpression(pattern: "`(.+?)`", options: [])
        plainText = inlineCodeRegex.stringByReplacingMatches(
            in: plainText,
            options: [],
            range: NSRange(location: 0, length: plainText.utf16.count),
            withTemplate: "$1"
        )
        
        // Remove blockquote formatting
        let blockquoteRegex = try NSRegularExpression(pattern: "^> (.+)$", options: [.anchorsMatchLines])
        plainText = blockquoteRegex.stringByReplacingMatches(
            in: plainText,
            options: [],
            range: NSRange(location: 0, length: plainText.utf16.count),
            withTemplate: "$1"
        )
        
        // Clean up excessive whitespace
        while plainText.contains("\n\n\n") {
            plainText = plainText.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        
        return plainText
    }
    
    private func convertTextToMarkdown(_ text: String) throws -> String {
        // For a real app, a more sophisticated algorithm would be needed
        // This is a simplified implementation for demonstration
        
        var markdown = text
        let lines = text.components(separatedBy: "\n")
        
        // If the first line looks like a title, convert it to H1
        if lines.count > 1 {
            let firstLine = lines[0].trimmingCharacters(in: .whitespacesAndNewlines)
            if !firstLine.isEmpty && firstLine.count <= 100 && !firstLine.contains("\n") {
                // Looks like a title
                markdown = "# " + firstLine + "\n\n" + lines.dropFirst().joined(separator: "\n")
            }
        }
        
        // Try to detect list items
        let potentialListItems = try NSRegularExpression(pattern: "^\\s*[\\*\\-]\\s+(.+)$", options: [.anchorsMatchLines])
        let matches = potentialListItems.matches(
            in: markdown,
            options: [],
            range: NSRange(location: 0, length: markdown.utf16.count)
        )
        
        if matches.isEmpty {
            // If no list items were detected, search for bullet-like patterns
            let bulletPatternRegex = try NSRegularExpression(pattern: "^\\s*([\\*\\-o•●\\d]+[\\)\\.]?)\\s+(.+)$", options: [.anchorsMatchLines])
            markdown = bulletPatternRegex.stringByReplacingMatches(
                in: markdown,
                options: [],
                range: NSRange(location: 0, length: markdown.utf16.count),
                withTemplate: "- $2"
            )
        }
        
        // Try to detect potential section headers
        // Look for short lines that are followed by longer content
        var lineArr = markdown.components(separatedBy: "\n")
        for i in 0..<lineArr.count-1 {
            let line = lineArr[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if line.count > 0 && line.count < 50 && !line.hasPrefix("#") && !line.hasPrefix("-") {
                // Check if the next line is longer or empty
                let nextLine = lineArr[i+1].trimmingCharacters(in: .whitespacesAndNewlines)
                if nextLine.isEmpty || nextLine.count > line.count {
                    // This looks like a section header
                    lineArr[i] = "## " + line
                }
            }
        }
        markdown = lineArr.joined(separator: "\n")
        
        // Try to detect emphasized text
        // Look for ALL CAPS text and convert to bold
        let allCapsRegex = try NSRegularExpression(pattern: "\\b([A-Z]{3,})\\b", options: [])
        markdown = allCapsRegex.stringByReplacingMatches(
            in: markdown,
            options: [],
            range: NSRange(location: 0, length: markdown.utf16.count),
            withTemplate: "**$1**"
        )
        
        // Look for text with surrounding punctuation like _text_ or *text*
        let emphasisRegex = try NSRegularExpression(pattern: "(?<![\\w\\*_])([\\*_])([^\\*_\\n]+?)\\1(?![\\w\\*_])", options: [])
        markdown = emphasisRegex.stringByReplacingMatches(
            in: markdown,
            options: [],
            range: NSRange(location: 0, length: markdown.utf16.count),
            withTemplate: "*$2*"
        )
        
        // Try to detect URLs and convert to Markdown links
        let urlRegex = try NSRegularExpression(pattern: "(https?://[^\\s]+)", options: [])
        markdown = urlRegex.stringByReplacingMatches(
            in: markdown,
            options: [],
            range: NSRange(location: 0, length: markdown.utf16.count),
            withTemplate: "[$1]($1)"
        )
        
        // Add paragraph breaks
        // For simplicity, add a blank line after each paragraph
        markdown = markdown.replacingOccurrences(of: "\n\n", with: "\n\n")
        
        return markdown
    }
    
    private func copyToClipboard(text: String) {
        UIPasteboard.general.string = text
        // In a real app, show a temporary confirmation toast
    }
    
    private func getExportContentType() -> UTType {
        switch selectedConversion {
        case .markdownToHTML:
            return UTType.html
        case .htmlToMarkdown, .textToMarkdown:
            return UTType.markdown
        case .markdownToPlainText:
            return UTType.plainText
        }
    }
    
    private func getDefaultExportFilename() -> String {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        
        switch selectedConversion {
        case .markdownToHTML:
            return "converted_\(timestamp).html"
        case .htmlToMarkdown, .textToMarkdown:
            return "converted_\(timestamp).md"
        case .markdownToPlainText:
            return "converted_\(timestamp).txt"
        }
    }
}

// MARK: - Supporting Views and Models

struct MarkedHTMLView: UIViewRepresentable {
    let html: String
    @Binding var dynamicHeight: CGFloat
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.backgroundColor = UIColor.clear
        
        // Disable text selection for smoother experience
        webView.configuration.preferences.javaScriptEnabled = true
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(html, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: MarkedHTMLView
        
        init(parent: MarkedHTMLView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Update the height to fit content
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { height, _ in
                if let height = height as? CGFloat {
                    self.parent.dynamicHeight = height
                }
            }
            
            // Disable text selection for better UX
            webView.evaluateJavaScript("""
                document.documentElement.style.webkitUserSelect = 'none';
                document.documentElement.style.userSelect = 'none';
            """)
        }
    }
}

struct TextFileDocument: FileDocument {
    var text: String
    
    init(text: String) {
        self.text = text
    }
    
    static var readableContentTypes: [UTType] { [.plainText, .html, .markdown] }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}

struct MarkdownReferenceGuideView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Markdown Syntax Guide")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Markdown is a lightweight markup language with plain-text formatting syntax. This guide covers the basic syntax to help you get started.")
                            .padding(.bottom, 10)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Headers")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("# Header 1")
                                Text("## Header 2")
                                Text("### Header 3")
                            }
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Emphasis")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("*Italic text*")
                                Text("**Bold text**")
                                Text("***Bold and italic text***")
                            }
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Lists")
                                .font(.headline)
                            
                            Text("Unordered Lists:")
                                .fontWeight(.medium)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("- Item 1")
                                Text("- Item 2")
                                Text("  - Subitem 2.1")
                                Text("  - Subitem 2.2")
                            }
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            
                            Text("Ordered Lists:")
                                .fontWeight(.medium)
                                .padding(.top, 5)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("1. First item")
                                Text("2. Second item")
                                Text("   1. Subitem 2.1")
                                Text("   2. Subitem 2.2")
                            }
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                    }
                    
                    Group {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Links")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("[Link text](https://example.com)")
                                Text("[Link with title](https://example.com \"Title\")")
                            }
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Images")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("![Alt text](image-url.jpg)")
                                Text("![Alt text with title](image-url.jpg \"Title\")")
                            }
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Code")
                                .font(.headline)
                            
                            Text("Inline code:")
                                .fontWeight(.medium)
                            
                            Text("`inline code`")
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                            
                            Text("Code blocks:")
                                .fontWeight(.medium)
                                .padding(.top, 5)
                            
                            Text("```\ncode block\nwith multiple lines\n```")
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Blockquotes")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("> This is a blockquote")
                                Text("> ")
                                Text("> It can span multiple lines")
                            }
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Horizontal Rule")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("---")
                                Text("or")
                                Text("***")
                                Text("or")
                                Text("___")
                            }
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                        
                        Text("For more details, visit [Markdown Guide](https://www.markdownguide.org/).")
                    }
                }
                .padding()
            }
            .navigationBarTitle("Markdown Reference", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - App State (Minimal implementation for this example)

class AppState: ObservableObject {
    func openInTextCleaner(text: String) {
        // In a real app, this would navigate to TextCleanerView and pass the text
        print("Open in TextCleaner: \(text.prefix(50))...")
    }
    
    func openInTextChunker(text: String) {
        // In a real app, this would navigate to TextChunkerView and pass the text
        print("Open in TextChunker: \(text.prefix(50))...")
    }
    
    func openInContextVisualizer(text: String) {
        // In a real app, this would navigate to ContextWindowVisualizerView and pass the text
        print("Open in ContextVisualizer: \(text.prefix(50))...")
    }
}

// MARK: - Preview

struct MarkdownConverterView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MarkdownConverterView()
                .environmentObject(AppState())
        }
    }
}
