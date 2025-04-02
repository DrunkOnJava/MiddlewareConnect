import SwiftUI

/// The supported tabs for navigation within the app
enum Tab: String, CaseIterable, Identifiable {
    // Main navigation tabs
    case home
    case text
    case textClean
    case markdown
    case pdfCombine
    case pdfSplit
    case summarize
    case csv
    case image
    case tokenCost
    case contextWindow
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .text: return "Text Chunker"
        case .textClean: return "Text Cleaner"
        case .markdown: return "Markdown Converter"
        case .pdfCombine: return "PDF Combiner"
        case .pdfSplit: return "PDF Splitter"
        case .summarize: return "Document Summarizer"
        case .csv: return "CSV Formatter"
        case .image: return "Image Splitter"
        case .tokenCost: return "Token Cost Calculator"
        case .contextWindow: return "Context Window"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .text: return "doc.text.magnifyingglass"
        case .textClean: return "pencil.and.outline"
        case .markdown: return "arrow.2.squarepath"
        case .pdfCombine: return "doc.on.doc"
        case .pdfSplit: return "doc.on.doc.fill"
        case .summarize: return "doc.text.magnifyingglass"
        case .csv: return "tablecells"
        case .image: return "photo.on.rectangle"
        case .tokenCost: return "dollarsign.circle"
        case .contextWindow: return "chart.bar.xaxis"
        }
    }
}