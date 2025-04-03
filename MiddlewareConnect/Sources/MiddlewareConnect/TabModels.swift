import SwiftUI

/// Tab identifiers for navigation
public enum Tab: String, CaseIterable {
    case text = "text"
    case textClean = "text-clean"
    case markdown = "markdown"
    case summarize = "summarize"
    case pdfCombine = "pdf-combine"
    case pdfSplit = "pdf-split"
    case csv = "csv"
    case image = "image"
    case tokenCost = "token-cost"
    case contextViz = "context-viz"
    
    public var displayName: String {
        switch self {
        case .text: return "Text Chunker"
        case .textClean: return "Text Cleaner"
        case .markdown: return "Markdown Converter"
        case .summarize: return "Document Summarizer"
        case .pdfCombine: return "PDF Combiner"
        case .pdfSplit: return "PDF Splitter"
        case .csv: return "CSV Formatter"
        case .image: return "Image Splitter"
        case .tokenCost: return "Token Cost Calculator"
        case .contextViz: return "Context Window Visualizer"
        }
    }
    
    public var systemImageName: String {
        switch self {
        case .text: return "doc.text"
        case .textClean: return "pencil"
        case .markdown: return "doc.plaintext"
        case .summarize: return "doc.text.magnifyingglass"
        case .pdfCombine: return "doc.on.doc"
        case .pdfSplit: return "doc.on.doc.fill"
        case .csv: return "tablecells"
        case .image: return "photo"
        case .tokenCost: return "dollarsign.circle"
        case .contextViz: return "arrow.up.left.and.arrow.down.right"
        }
    }
}
