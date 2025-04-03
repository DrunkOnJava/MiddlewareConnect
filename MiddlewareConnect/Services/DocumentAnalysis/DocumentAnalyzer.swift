/**
 * @fileoverview Document Analyzer service for PDF analysis
 * @module DocumentAnalyzer
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - Foundation
 * - PDF
 * - LLM
 * - API
 * 
 * Exports:
 * - DocumentAnalyzer
 * - DocumentSummary
 * - ExtractedEntity
 * - DocumentComparison
 * 
 * Notes:
 * - Provides advanced document analysis capabilities
 * - Integrates PDF service, LLM tools, and Claude API
 */

import Foundation
import PDFKit
import Combine
import NaturalLanguage

/// Errors that can occur during document analysis
public enum AnalysisError: Error {
    case documentTooLarge(Int)
    case apiError(Error)
    case processingFailed(Error)
    case invalidDocument
    case emptyDocument
    case extractionFailed
    case unsupportedLanguage(String)
    
    var localizedDescription: String {
        switch self {
        case .documentTooLarge(let tokenCount):
            return "Document is too large (\(tokenCount) tokens) for analysis."
        case .apiError(let error):
            return "API error: \(error.localizedDescription)"
        case .processingFailed(let error):
            return "Processing failed: \(error.localizedDescription)"
        case .invalidDocument:
            return "The document is invalid or corrupted."
        case .emptyDocument:
            return "The document has no text content."
        case .extractionFailed:
            return "Failed to extract information from the document."
        case .unsupportedLanguage(let language):
            return "Unsupported language: \(language)"
        }
    }
}

/// A document summary
public struct DocumentSummary: Codable, Identifiable {
    /// The summary ID
    public let id: UUID
    
    /// The document ID
    public let documentId: String
    
    /// The summary text
    public let summaryText: String
    
    /// The main topics
    public let mainTopics: [String]
    
    /// The creation date
    public let createdAt: Date
    
    /// The token count
    public let tokenCount: Int
    
    /// The document language
    public let language: String?
    
    /// The document title
    public let documentTitle: String
}

/// An entity extracted from a document
public struct ExtractedEntity: Codable, Identifiable {
    /// The entity ID
    public let id: UUID
    
    /// The entity name
    public let name: String
    
    /// The entity type
    public let type: EntityType
    
    /// The confidence score
    public let confidence: Double
    
    /// The entity context
    public let context: String?
    
    /// The document ID
    public let documentId: String
    
    /// Entity types
    public enum EntityType: String, Codable {
        case person
        case organization
        case location
        case date
        case money
        case product
        case event
        case workOfArt
        case other
    }
}

/// A comparison between two documents
public struct DocumentComparison: Codable, Identifiable {
    /// The comparison ID
    public let id: UUID
    
    /// The first document ID
    public let document1Id: String
    
    /// The second document ID
    public let document2Id: String
    
    /// The similarity score
    public let similarityScore: Double
    
    /// The key differences
    public let keyDifferences: [String]
    
    /// The shared topics
    public let sharedTopics: [String]
    
    /// The creation date
    public let createdAt: Date
    
    /// The token count
    public let tokenCount: Int
}

/// Service for analyzing PDF documents
public class DocumentAnalyzer {
    // MARK: - Properties
    
    /// The PDF service
    private let pdfService: PDFService
    
    /// The API client
    private let apiService: AnthropicService
    
    /// The token counter
    private let tokenCounter: TokenCounter
    
    /// The text chunker
    private let textChunker: TextChunker
    
    /// Publisher for analysis progress
    private let progressSubject = CurrentValueSubject<Double, Never>(0)
    public var progress: AnyPublisher<Double, Never> {
        return progressSubject.eraseToAnyPublisher()
    }
    
    /// Publisher for analysis status
    private let statusSubject = PassthroughSubject<String, Error>()
    public var status: AnyPublisher<String, Error> {
        return statusSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    /// Initializes a new DocumentAnalyzer
    /// - Parameters:
    ///   - pdfService: The PDF service
    ///   - apiService: The API service
    ///   - tokenCounter: The token counter
    ///   - textChunker: The text chunker
    public init(
        pdfService: PDFService = PDFService.shared,
        apiService: AnthropicService = AnthropicService(),
        tokenCounter: TokenCounter = TokenCounter.shared,
        textChunker: TextChunker? = nil
    ) {
        self.pdfService = pdfService
        self.apiService = apiService
        self.tokenCounter = tokenCounter
        self.textChunker = textChunker ?? TextChunker(maxChunkSize: 10000, tokenCounter: tokenCounter)
    }
    
    // MARK: - Document Analysis
    
    /// Summarizes a PDF document
    /// - Parameters:
    ///   - url: URL of the PDF file
    ///   - length: Desired summary length
    ///   - model: Claude model to use
    /// - Returns: A document summary
    /// - Throws: AnalysisError if summarization fails
    public func summarizeDocument(
        at url: URL,
        length: SummaryLength = .moderate,
        model: Claude3Model = .sonnet
    ) async throws -> DocumentSummary {
        // Update progress
        progressSubject.send(0.1)
        statusSubject.send("Loading PDF...")
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AnalysisError.invalidDocument
        }
        
        // Load the PDF
        guard let pdf = PDFKit.PDFDocument(url: url) else {
            throw AnalysisError.invalidDocument
        }
        
        // Extract text from the document
        progressSubject.send(0.2)
        statusSubject.send("Extracting text...")
        
        var documentText = ""
        var completion = false
        
        // Use the PDF service to extract text
        pdfService.extractText(from: url) { result in
            switch result {
            case .success(let text):
                documentText = text
                completion = true
            case .failure(let error):
                documentText = ""
                completion = true
                print("Error extracting text: \(error.localizedDescription)")
            }
        }
        
        // Wait for completion
        while !completion {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        guard !documentText.isEmpty else {
            throw AnalysisError.emptyDocument
        }
        
        // Count tokens
        progressSubject.send(0.3)
        statusSubject.send("Counting tokens...")
        
        let tokenCount = tokenCounter.countTokens(documentText)
        
        // Check if the document is too large
        let maxDocumentSize = 50000 // Set a reasonable limit
        if tokenCount > maxDocumentSize {
            progressSubject.send(0.4)
            statusSubject.send("Document too large, chunking...")
            
            // Chunk the document and use the first chunk
            let chunks = try textChunker.chunkText(documentText, strategy: .paragraph)
            
            // Use a representative sample
            if chunks.count > 3 {
                documentText = chunks[0] + "\n\n" + chunks[chunks.count / 2] + "\n\n" + chunks[chunks.count - 1]
            } else {
                documentText = chunks.joined(separator: "\n\n")
            }
        }
        
        // Detect language
        progressSubject.send(0.5)
        statusSubject.send("Detecting language...")
        
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(documentText)
        let language = recognizer.dominantLanguage?.rawValue
        
        // Generate summary
        progressSubject.send(0.6)
        statusSubject.send("Generating summary...")
        
        // Create a completion handler
        let resultPromise = Promise<String>()
        
        // Call API to summarize
        apiService.summarizeDocument(
            text: documentText,
            length: length,
            model: model
        ) { result in
            switch result {
            case .success(let summary):
                resultPromise.fulfill(summary)
            case .failure(let error):
                resultPromise.reject(error)
            }
        }
        
        // Wait for the API call to complete
        let summaryText: String
        do {
            summaryText = try await resultPromise.value
        } catch {
            throw AnalysisError.apiError(error)
        }
        
        // Extract main topics
        progressSubject.send(0.8)
        statusSubject.send("Extracting main topics...")
        
        let mainTopics = try await extractMainTopics(from: summaryText, model: model)
        
        // Create summary object
        progressSubject.send(1.0)
        statusSubject.send("Summary complete")
        
        return DocumentSummary(
            id: UUID(),
            documentId: url.lastPathComponent,
            summaryText: summaryText,
            mainTopics: mainTopics,
            createdAt: Date(),
            tokenCount: tokenCount,
            language: language,
            documentTitle: pdf.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String ?? url.lastPathComponent
        )
    }
    
    /// Extracts main topics from a summary
    /// - Parameters:
    ///   - summary: The summary text
    ///   - model: The Claude model to use
    /// - Returns: An array of main topics
    /// - Throws: AnalysisError if extraction fails
    private func extractMainTopics(from summary: String, model: Claude3Model) async throws -> [String] {
        // Create a prompt for topic extraction
        let prompt = """
        Extract the main topics from the following document summary. Return only a list of 3-5 main topics, one per line.
        
        Summary:
        \(summary)
        
        Main Topics:
        """
        
        // Create a completion handler
        let resultPromise = Promise<String>()
        
        // Call API to extract topics
        apiService.generateText(
            prompt: prompt,
            model: model,
            systemPrompt: SystemPrompts.documentAnalyzer
        ) { result in
            switch result {
            case .success(let topics):
                resultPromise.fulfill(topics)
            case .failure(let error):
                resultPromise.reject(error)
            }
        }
        
        // Wait for the API call to complete
        let topicsText: String
        do {
            topicsText = try await resultPromise.value
        } catch {
            throw AnalysisError.apiError(error)
        }
        
        // Parse the topics
        let topics = topicsText
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { line -> String in
                // Remove leading numbers and punctuation
                if let range = line.range(of: #"^\d+[\.\)\-] *"#, options: .regularExpression) {
                    return String(line[range.upperBound...])
                }
                // Remove leading bullet points
                if let range = line.range(of: #"^[\-\•\*] *"#, options: .regularExpression) {
                    return String(line[range.upperBound...])
                }
                return line
            }
        
        return topics
    }
    
    /// Extracts entities from a PDF document
    /// - Parameters:
    ///   - url: URL of the PDF file
    ///   - model: Claude model to use
    /// - Returns: An array of extracted entities
    /// - Throws: AnalysisError if extraction fails
    public func extractEntities(from url: URL, model: Claude3Model = .sonnet) async throws -> [ExtractedEntity] {
        // Update progress
        progressSubject.send(0.1)
        statusSubject.send("Loading PDF...")
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AnalysisError.invalidDocument
        }
        
        // Extract text from the document
        progressSubject.send(0.2)
        statusSubject.send("Extracting text...")
        
        var documentText = ""
        var completion = false
        
        // Use the PDF service to extract text
        pdfService.extractText(from: url) { result in
            switch result {
            case .success(let text):
                documentText = text
                completion = true
            case .failure(let error):
                documentText = ""
                completion = true
                print("Error extracting text: \(error.localizedDescription)")
            }
        }
        
        // Wait for completion
        while !completion {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        guard !documentText.isEmpty else {
            throw AnalysisError.emptyDocument
        }
        
        // Use NLTagger for entity recognition
        progressSubject.send(0.4)
        statusSubject.send("Performing initial entity extraction...")
        
        var entities: [ExtractedEntity] = []
        
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = documentText
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        
        tagger.enumerateTags(in: documentText.startIndex..<documentText.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            if let tag = tag {
                let entityText = String(documentText[tokenRange])
                
                // Map NLTag to EntityType
                let entityType: ExtractedEntity.EntityType
                switch tag {
                case .personalName:
                    entityType = .person
                case .organizationName:
                    entityType = .organization
                case .placeName:
                    entityType = .location
                default:
                    entityType = .other
                }
                
                // Skip if the entity is too short
                if entityText.count < 2 {
                    return true
                }
                
                // Get surrounding context
                let contextRange = getContextRange(around: tokenRange, in: documentText, windowSize: 100)
                let context = String(documentText[contextRange])
                
                // Add to entities if not already present
                if !entities.contains(where: { $0.name == entityText && $0.type == entityType }) {
                    entities.append(ExtractedEntity(
                        id: UUID(),
                        name: entityText,
                        type: entityType,
                        confidence: 0.8, // Estimated confidence
                        context: context,
                        documentId: url.lastPathComponent
                    ))
                }
            }
            
            return true
        }
        
        // If the document is too long, use a sample for Claude analysis
        progressSubject.send(0.6)
        statusSubject.send("Performing advanced entity extraction...")
        
        let tokenCount = tokenCounter.countTokens(documentText)
        let textToAnalyze: String
        
        if tokenCount > 10000 {
            // Chunk the text and use a representative portion
            let chunks = try textChunker.chunkText(documentText, strategy: .paragraph)
            textToAnalyze = getRepresentativeChunks(chunks, maxTokens: 8000).joined(separator: "\n\n")
        } else {
            textToAnalyze = documentText
        }
        
        // Create a prompt for entity extraction
        let prompt = """
        Extract all named entities from the following text, classifying them by type.
        
        Text:
        \(textToAnalyze)
        
        Extract entities and classify them as one of these types: person, organization, location, date, money, product, event, workOfArt, other.
        
        For each entity, provide:
        1. Entity name
        2. Entity type
        3. A confidence score from 0.0 to 1.0
        4. A short context snippet showing where the entity appears
        
        Format your response as a list of entities, one per line, with the format:
        NAME | TYPE | CONFIDENCE | CONTEXT
        """
        
        // Create a completion handler
        let resultPromise = Promise<String>()
        
        // Call API to extract entities
        apiService.generateText(
            prompt: prompt,
            model: model,
            systemPrompt: SystemPrompts.documentAnalyzer
        ) { result in
            switch result {
            case .success(let extractionResult):
                resultPromise.fulfill(extractionResult)
            case .failure(let error):
                resultPromise.reject(error)
            }
        }
        
        // Wait for the API call to complete
        let extractionResult: String
        do {
            extractionResult = try await resultPromise.value
        } catch {
            // If the API call fails, return the entities found by NLTagger
            progressSubject.send(1.0)
            statusSubject.send("Entity extraction complete (partial)")
            return entities
        }
        
        // Parse the entities
        progressSubject.send(0.8)
        statusSubject.send("Processing extracted entities...")
        
        let lines = extractionResult.components(separatedBy: "\n")
        
        for line in lines {
            // Skip headers, empty lines, and list markers
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
               line.hasPrefix("#") ||
               line.hasPrefix("-") ||
               line.hasPrefix("*") ||
               !line.contains("|") {
                continue
            }
            
            // Parse the line
            let components = line.components(separatedBy: " | ")
            
            if components.count >= 3 {
                let name = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let typeString = components[1].lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Skip if name is empty
                if name.isEmpty {
                    continue
                }
                
                // Parse confidence
                var confidence = 0.7 // Default confidence
                if components.count >= 3 {
                    if let parsedConfidence = Double(components[2].trimmingCharacters(in: .whitespacesAndNewlines)) {
                        confidence = parsedConfidence
                    }
                }
                
                // Parse context
                var context: String? = nil
                if components.count >= 4 {
                    context = components[3].trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                // Map type string to EntityType
                let entityType: ExtractedEntity.EntityType
                switch typeString {
                case "person":
                    entityType = .person
                case "organization":
                    entityType = .organization
                case "location":
                    entityType = .location
                case "date":
                    entityType = .date
                case "money":
                    entityType = .money
                case "product":
                    entityType = .product
                case "event":
                    entityType = .event
                case "workofart":
                    entityType = .workOfArt
                default:
                    entityType = .other
                }
                
                // Add to entities if not already present
                if !entities.contains(where: { $0.name == name && $0.type == entityType }) {
                    entities.append(ExtractedEntity(
                        id: UUID(),
                        name: name,
                        type: entityType,
                        confidence: confidence,
                        context: context,
                        documentId: url.lastPathComponent
                    ))
                }
            }
        }
        
        progressSubject.send(1.0)
        statusSubject.send("Entity extraction complete")
        
        return entities
    }
    
    /// Compares two PDF documents
    /// - Parameters:
    ///   - url1: URL of the first PDF file
    ///   - url2: URL of the second PDF file
    ///   - model: Claude model to use
    /// - Returns: A document comparison
    /// - Throws: AnalysisError if comparison fails
    public func compareDocuments(url1: URL, url2: URL, model: Claude3Model = .sonnet) async throws -> DocumentComparison {
        // Update progress
        progressSubject.send(0.1)
        statusSubject.send("Loading PDFs...")
        
        // Check if files exist
        guard FileManager.default.fileExists(atPath: url1.path),
              FileManager.default.fileExists(atPath: url2.path) else {
            throw AnalysisError.invalidDocument
        }
        
        // Load the PDFs
        guard let pdf1 = PDFKit.PDFDocument(url: url1),
              let pdf2 = PDFKit.PDFDocument(url: url2) else {
            throw AnalysisError.invalidDocument
        }
        
        // Extract text from the documents
        progressSubject.send(0.2)
        statusSubject.send("Extracting text from first document...")
        
        var text1 = ""
        var text2 = ""
        var completion1 = false
        var completion2 = false
        
        // Use the PDF service to extract text from the first document
        pdfService.extractText(from: url1) { result in
            switch result {
            case .success(let text):
                text1 = text
                completion1 = true
            case .failure(let error):
                text1 = ""
                completion1 = true
                print("Error extracting text: \(error.localizedDescription)")
            }
        }
        
        // Wait for completion
        while !completion1 {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        progressSubject.send(0.3)
        statusSubject.send("Extracting text from second document...")
        
        // Use the PDF service to extract text from the second document
        pdfService.extractText(from: url2) { result in
            switch result {
            case .success(let text):
                text2 = text
                completion2 = true
            case .failure(let error):
                text2 = ""
                completion2 = true
                print("Error extracting text: \(error.localizedDescription)")
            }
        }
        
        // Wait for completion
        while !completion2 {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        guard !text1.isEmpty, !text2.isEmpty else {
            throw AnalysisError.emptyDocument
        }
        
        // Count tokens
        progressSubject.send(0.4)
        statusSubject.send("Analyzing documents...")
        
        let tokenCount1 = tokenCounter.countTokens(text1)
        let tokenCount2 = tokenCounter.countTokens(text2)
        
        // If documents are too large, use samples
        let textToAnalyze1: String
        let textToAnalyze2: String
        
        if tokenCount1 > 5000 {
            let chunks = try textChunker.chunkText(text1, strategy: .paragraph)
            textToAnalyze1 = getRepresentativeChunks(chunks, maxTokens: 4000).joined(separator: "\n\n")
        } else {
            textToAnalyze1 = text1
        }
        
        if tokenCount2 > 5000 {
            let chunks = try textChunker.chunkText(text2, strategy: .paragraph)
            textToAnalyze2 = getRepresentativeChunks(chunks, maxTokens: 4000).joined(separator: "\n\n")
        } else {
            textToAnalyze2 = text2
        }
        
        // Create a prompt for document comparison
        progressSubject.send(0.5)
        statusSubject.send("Comparing documents...")
        
        let title1 = pdf1.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String ?? url1.lastPathComponent
        let title2 = pdf2.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String ?? url2.lastPathComponent
        
        let prompt = """
        Compare the following two documents and analyze their similarities and differences.
        
        Document 1: \(title1)
        \(textToAnalyze1)
        
        Document 2: \(title2)
        \(textToAnalyze2)
        
        Please provide:
        1. A similarity score between 0.0 (completely different) and 1.0 (identical)
        2. Key differences between the documents
        3. Shared topics or themes
        
        Format your response with clear sections for each part:
        
        SIMILARITY SCORE: [0.0-1.0]
        
        KEY DIFFERENCES:
        - Difference 1
        - Difference 2
        - etc.
        
        SHARED TOPICS:
        - Topic 1
        - Topic 2
        - etc.
        """
        
        // Create a completion handler
        let resultPromise = Promise<String>()
        
        // Call API to compare documents
        apiService.generateText(
            prompt: prompt,
            model: model,
            systemPrompt: SystemPrompts.documentAnalyzer
        ) { result in
            switch result {
            case .success(let comparisonResult):
                resultPromise.fulfill(comparisonResult)
            case .failure(let error):
                resultPromise.reject(error)
            }
        }
        
        // Wait for the API call to complete
        let comparisonResult: String
        do {
            comparisonResult = try await resultPromise.value
        } catch {
            throw AnalysisError.apiError(error)
        }
        
        // Parse the comparison result
        progressSubject.send(0.8)
        statusSubject.send("Processing comparison results...")
        
        // Extract similarity score
        var similarityScore = 0.5 // Default value
        if let scoreRange = comparisonResult.range(of: #"SIMILARITY SCORE:?\s*([0-9]\.[0-9]+)"#, options: .regularExpression) {
            let scoreString = comparisonResult[scoreRange]
            if let match = scoreString.firstMatch(of: /([0-9]\.[0-9]+)/) {
                if let score = Double(match.1) {
                    similarityScore = score
                }
            }
        }
        
        // Extract key differences
        var keyDifferences: [String] = []
        if let differencesRange = comparisonResult.range(of: #"KEY DIFFERENCES:(.*?)(?:SHARED TOPICS|\Z)"#, options: [.regularExpression, .dotMatchesLineSeparators]) {
            let differencesSection = comparisonResult[differencesRange]
            let lines = differencesSection.components(separatedBy: "\n")
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedLine.hasPrefix("-") || trimmedLine.hasPrefix("*") {
                    let difference = trimmedLine.dropFirst().trimmingCharacters(in: .whitespacesAndNewlines)
                    if !difference.isEmpty {
                        keyDifferences.append(difference)
                    }
                }
            }
        }
        
        // Extract shared topics
        var sharedTopics: [String] = []
        if let topicsRange = comparisonResult.range(of: #"SHARED TOPICS:(.*?)(?:\Z)"#, options: [.regularExpression, .dotMatchesLineSeparators]) {
            let topicsSection = comparisonResult[topicsRange]
            let lines = topicsSection.components(separatedBy: "\n")
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedLine.hasPrefix("-") || trimmedLine.hasPrefix("*") {
                    let topic = trimmedLine.dropFirst().trimmingCharacters(in: .whitespacesAndNewlines)
                    if !topic.isEmpty {
                        sharedTopics.append(topic)
                    }
                }
            }
        }
        
        // Create comparison object
        progressSubject.send(1.0)
        statusSubject.send("Comparison complete")
        
        return DocumentComparison(
            id: UUID(),
            document1Id: url1.lastPathComponent,
            document2Id: url2.lastPathComponent,
            similarityScore: similarityScore,
            keyDifferences: keyDifferences,
            sharedTopics: sharedTopics,
            createdAt: Date(),
            tokenCount: tokenCount1 + tokenCount2
        )
    }
    
    // MARK: - Helper Methods
    
    /// Gets representative chunks from a list of chunks
    /// - Parameters:
    ///   - chunks: The chunks to get representatives from
    ///   - maxTokens: The maximum tokens to include
    /// - Returns: Representative chunks
    private func getRepresentativeChunks(_ chunks: [String], maxTokens: Int = 10000) -> [String] {
        var representativeChunks: [String] = []
        var totalTokens = 0
        
        // Add the first chunk
        if chunks.count > 0 {
            let firstChunk = chunks[0]
            let firstTokens = tokenCounter.countTokens(firstChunk)
            
            if totalTokens + firstTokens <= maxTokens {
                representativeChunks.append(firstChunk)
                totalTokens += firstTokens
            }
        }
        
        // Add a middle chunk
        if chunks.count > 2 {
            let middleIndex = chunks.count / 2
            let middleChunk = chunks[middleIndex]
            let middleTokens = tokenCounter.countTokens(middleChunk)
            
            if totalTokens + middleTokens <= maxTokens {
                representativeChunks.append(middleChunk)
                totalTokens += middleTokens
            }
        }
        
        // Add the last chunk
        if chunks.count > 1 {
            let lastChunk = chunks[chunks.count - 1]
            let lastTokens = tokenCounter.countTokens(lastChunk)
            
            if totalTokens + lastTokens <= maxTokens {
                representativeChunks.append(lastChunk)
                totalTokens += lastTokens
            }
        }
        
        // If we need more chunks, add evenly distributed chunks
        if chunks.count > 3 && totalTokens < maxTokens {
            let stride = chunks.count / 4
            
            for i in stride..<chunks.count - 1 step: stride {
                if i == chunks.count / 2 {
                    continue // Skip the middle chunk (already added)
                }
                
                let chunk = chunks[i]
                let chunkTokens = tokenCounter.countTokens(chunk)
                
                if totalTokens + chunkTokens <= maxTokens {
                    representativeChunks.append(chunk)
                    totalTokens += chunkTokens
                } else {
                    break
                }
            }
        }
        
        return representativeChunks
    }
    
    /// Gets a context range around a token range
    /// - Parameters:
    ///   - tokenRange: The token range
    ///   - text: The text
    ///   - windowSize: The window size
    /// - Returns: The context range
    private func getContextRange(
        around tokenRange: Range<String.Index>,
        in text: String,
        windowSize: Int
    ) -> Range<String.Index> {
        let startOffset = min(windowSize, text.distance(from: text.startIndex, to: tokenRange.lowerBound))
        let endOffset = min(windowSize, text.distance(from: tokenRange.upperBound, to: text.endIndex))
        
        let contextStart = text.index(tokenRange.lowerBound, offsetBy: -startOffset)
        let contextEnd = text.index(tokenRange.upperBound, offsetBy: endOffset)
        
        return contextStart..<contextEnd
    }
}

/// A simple promise implementation for async/await
class Promise<T> {
    private var value: T?
    private var error: Error?
    private var isFulfilled = false
    private var isRejected = false
    private var continuation: CheckedContinuation<T, Error>?
    
    func fulfill(_ value: T) {
        guard !isFulfilled && !isRejected else { return }
        
        self.value = value
        isFulfilled = true
        
        if let continuation = continuation {
            continuation.resume(returning: value)
            self.continuation = nil
        }
    }
    
    func reject(_ error: Error) {
        guard !isFulfilled && !isRejected else { return }
        
        self.error = error
        isRejected = true
        
        if let continuation = continuation {
            continuation.resume(throwing: error)
            self.continuation = nil
        }
    }
    
    var value: T {
        get async throws {
            if isFulfilled, let value = value {
                return value
            }
            
            if isRejected, let error = error {
                throw error
            }
            
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
            }
        }
    }
}
