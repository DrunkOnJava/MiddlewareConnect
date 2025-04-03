/**
 * @fileoverview Anthropic API service for Claude LLM integration
 * @module AnthropicService
 * 
 * Created: 2025-04-01
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - Foundation
 * 
 * Exports:
 * - AnthropicService
 * 
 * Notes:
 * - Manages communication with Anthropic's Claude API
 * - Handles authentication, request formatting, and response parsing
 */

import Foundation
import Combine
import Alamofire

/// API Provider enum for identifying different LLM services
public enum APIProvider: String {
    case anthropic
    case openai
    case google
    case mistral
    case meta
}

/// Summary length options for document summarization
enum SummaryLength: String, CaseIterable, Identifiable {
    /// Brief summary (1-2 paragraphs)
    case brief
    
    /// Moderate summary (3-5 paragraphs)
    case moderate
    
    /// Detailed summary (comprehensive coverage)
    case detailed
    
    /// Identifiable requirement
    var id: String { self.rawValue }
    
    /// Display name for the UI
    var displayName: String {
        switch self {
        case .brief:
            return "Brief"
        case .moderate:
            return "Moderate"
        case .detailed:
            return "Detailed"
        }
    }
    
    /// Description of the summary length for the UI
    var description: String {
        switch self {
        case .brief:
            return "A concise overview in 1-2 paragraphs (about 100-150 words)"
        case .moderate:
            return "A balanced summary in 3-5 paragraphs (about 250-350 words)"
        case .detailed:
            return "A comprehensive summary with full details (500+ words)"
        }
    }
    
    /// Target word count for the summary
    var targetWordCount: Int {
        switch self {
        case .brief:
            return 150
        case .moderate:
            return 300
        case .detailed:
            return 600
        }
    }
}

/// Claude 3 model variants
enum Claude3Model: String, CaseIterable, Identifiable {
    case opus = "claude-3-opus-20240307"
    case sonnet = "claude-3-sonnet-20240229"
    case sonnetPlus = "claude-3-5-sonnet-20250307"
    case haiku = "claude-3-haiku-20240307"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .opus:
            return "Claude 3 Opus"
        case .sonnet:
            return "Claude 3 Sonnet"
        case .sonnetPlus:
            return "Claude 3.5 Sonnet"
        case .haiku:
            return "Claude 3 Haiku"
        }
    }
    
    var description: String {
        switch self {
        case .opus:
            return "Most powerful model with highest reasoning capabilities"
        case .sonnet:
            return "Balance of intelligence and speed for most tasks"
        case .sonnetPlus:
            return "Enhanced version of Sonnet with improved capabilities"
        case .haiku:
            return "Fastest and most compact model for simple tasks"
        }
    }
    
    var maxContextWindow: Int {
        switch self {
        case .opus:
            return 200000
        case .sonnet:
            return 100000
        case .sonnetPlus:
            return 200000
        case .haiku:
            return 48000
        }
    }
    
    var costPerInputToken: Double {
        switch self {
        case .opus:
            return 0.000015
        case .sonnet:
            return 0.000003
        case .sonnetPlus:
            return 0.000005
        case .haiku:
            return 0.000000725
        }
    }
    
    var costPerOutputToken: Double {
        switch self {
        case .opus:
            return 0.000075
        case .sonnet:
            return 0.000015
        case .sonnetPlus:
            return 0.000025
        case .haiku:
            return 0.00000362
        }
    }
}

/// Service for interacting with Anthropic's Claude models
class AnthropicService {
    // MARK: - API Request Methods
    
    /// Call Anthropic API with retry logic using Alamofire
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - requestBody: Request body
    ///   - retryCount: Current retry count
    ///   - completion: Callback with the result
    internal func callAnthropicAPIWithRetry(
        endpoint: String,
        requestBody: [String: Any],
        retryCount: Int,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        // Update API call status
        apiCallStatusSubject.send(.inProgress)
        
        // Create URL
        let url = "\(baseURL)/\(endpoint)"
        
        // Make request with Alamofire
        session.request(url, method: .post, parameters: requestBody, encoding: JSONEncoding.default)
            .validate()
            .responseData { [weak self] response in
                guard let self = self else { return }
                
                switch response.result {
                case .success(let data):
                    self.apiCallStatusSubject.send(.completed)
                    completion(.success(data))
                    
                case .failure(let error):
                    // The RequestInterceptor will handle retries
                    self.apiCallStatusSubject.send(.failed(error))
                    completion(.failure(error))
                }
            }
    }
    
    /// Call Anthropic API with streaming response
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - requestBody: Request body
    internal func callAnthropicStreamingAPI(
        endpoint: String,
        requestBody: [String: Any]
    ) {
        // Cancel any existing streaming task
        currentStreamingTask?.cancel()
        
        // Update API call status
        apiCallStatusSubject.send(.streaming)
        
        // Create URL
        let url = "\(baseURL)/\(endpoint)"
        
        // Create request headers manually (Alamofire DataStreamRequest doesn't use the interceptor)
        var headers = HTTPHeaders()
        headers.add(.contentType("application/json"))
        headers.add(.init(name: "anthropic-version", value: apiVersion))
        
        let apiKey = keychainService.retrieveApiKey(APIProvider.anthropic.rawValue) ?? ""
        if !apiKey.isEmpty {
            headers.add(.init(name: "x-api-key", value: apiKey))
            headers.add(.init(name: "Authorization", value: "Bearer \(apiKey)"))
        }
        
        // Variables to accumulate the response
        var accumulatedText = ""
        var messageId: String? = nil
        
        // Create the streaming request
        currentStreamingTask = session.streamRequest(
            url,
            method: .post,
            headers: headers
        ) { request in
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            } catch {
                print("Error serializing request body: \(error)")
            }
        }
        
        // Process the response stream
        currentStreamingTask?.responseStream { [weak self] stream in
            guard let self = self else { return }
            
            switch stream.event {
            case .stream(let result):
                switch result {
                case .success(let data):
                    // Process each chunk of streamed data
                    do {
                        // Convert data to string
                        guard let text = String(data: data, encoding: .utf8) else {
                            throw APIError.parsingError
                        }
                        
                        // Split the text by lines - each line is a separate event
                        let lines = text.components(separatedBy: "\n")
                        
                        for line in lines {
                            // Skip empty lines
                            guard !line.isEmpty else { continue }
                            
                            // Check for SSE data format (starts with "data: ")
                            if line.hasPrefix("data: ") {
                                let jsonString = String(line.dropFirst(6))
                                
                                // Handle end of stream
                                if jsonString == "[DONE]" {
                                    let finalResponse = StreamingResponse(
                                        content: accumulatedText,
                                        isComplete: true,
                                        type: .messageStop,
                                        messageId: messageId
                                    )
                                    self.streamingResponseSubject.send(finalResponse)
                                    self.apiCallStatusSubject.send(.streamingCompleted)
                                    continue
                                }
                                
                                // Parse the JSON event
                                if let eventData = jsonString.data(using: .utf8),
                                   let event = try? JSONDecoder().decode(StreamEvent.self, from: eventData) {
                                    
                                    // Handle different event types
                                    switch event.type {
                                    case "message_start":
                                        // Store the message ID
                                        messageId = event.message?.id
                                        
                                        // Reset accumulated text at the start of a new message
                                        accumulatedText = ""
                                        
                                        // Send event
                                        let response = StreamingResponse(
                                            content: "",
                                            type: .messageStart,
                                            messageId: messageId
                                        )
                                        self.streamingResponseSubject.send(response)
                                        
                                    case "content_block_start":
                                        // Handle the start of a content block (no action needed for now)
                                        break
                                        
                                    case "content_block_delta":
                                        // Get the delta text
                                        if let deltaText = event.delta?.text, !deltaText.isEmpty {
                                            // Add to accumulated text
                                            accumulatedText += deltaText
                                            
                                            // Send the new text
                                            let response = StreamingResponse(
                                                content: deltaText,
                                                type: .messageDelta,
                                                messageId: messageId
                                            )
                                            self.streamingResponseSubject.send(response)
                                        }
                                        
                                    case "message_delta":
                                        // Handle message delta (no action needed for content since we handle at content_block_delta)
                                        break
                                        
                                    case "content_block_stop":
                                        // Handle the end of a content block (no action needed for now)
                                        break
                                        
                                    case "message_stop":
                                        // Send final message with complete text
                                        let finalResponse = StreamingResponse(
                                            content: accumulatedText,
                                            isComplete: true,
                                            type: .messageStop,
                                            messageId: messageId
                                        )
                                        self.streamingResponseSubject.send(finalResponse)
                                        self.apiCallStatusSubject.send(.streamingCompleted)
                                        
                                    default:
                                        // Handle unknown event types (just log for now)
                                        print("Unknown event type: \(event.type)")
                                    }
                                }
                            }
                        }
                    } catch {
                        let errorResponse = StreamingResponse(
                            content: "",
                            isComplete: true,
                            type: .error,
                            error: error
                        )
                        self.streamingResponseSubject.send(errorResponse)
                        self.apiCallStatusSubject.send(.failed(error))
                    }
                    
                case .failure(let error):
                    let errorResponse = StreamingResponse(
                        content: "",
                        isComplete: true,
                        type: .error,
                        error: error
                    )
                    self.streamingResponseSubject.send(errorResponse)
                    self.apiCallStatusSubject.send(.failed(error))
                }
                
            case .complete(let completion):
                if let error = completion.error {
                    let errorResponse = StreamingResponse(
                        content: "",
                        isComplete: true,
                        type: .error,
                        error: error
                    )
                    self.streamingResponseSubject.send(errorResponse)
                    self.apiCallStatusSubject.send(.failed(error))
                } else if !accumulatedText.isEmpty {
                    // Ensure we send a final completion if the stream completed without an explicit message_stop
                    let finalResponse = StreamingResponse(
                        content: accumulatedText,
                        isComplete: true,
                        type: .messageStop,
                        messageId: messageId
                    )
                    self.streamingResponseSubject.send(finalResponse)
                    self.apiCallStatusSubject.send(.streamingCompleted)
                }
            }
        }
    }
    // MARK: - Properties
    
    private let baseURL = "https://api.anthropic.com/v1"
    private let apiVersion = "2023-06-01" // Update as needed
    private let retryLimit = 3
    private let retryDelay: TimeInterval = 2.0
    
    // Session manager for network requests
    private let session: Session
    
    // Current streaming task, if any
    private var currentStreamingTask: DataStreamRequest?
    
    // KeychainService for API key management
    private let keychainService: KeychainService
    
    private var apiKey: String {
        return keychainService.retrieveApiKey(APIProvider.anthropic.rawValue) ?? ""
    }
    
    // Publisher for API call status
    private let apiCallStatusSubject = PassthroughSubject<APICallStatus, Never>()
    var apiCallStatus: AnyPublisher<APICallStatus, Never> {
        return apiCallStatusSubject.eraseToAnyPublisher()
    }
    
    // Publisher for streaming responses
    private let streamingResponseSubject = PassthroughSubject<StreamingResponse, Error>()
    var streamingResponse: AnyPublisher<StreamingResponse, Error> {
        return streamingResponseSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(keychainService: KeychainService = KeychainService()) {
        // Configure session with custom interceptor for handling retries
        let interceptor = AnthropicRequestInterceptor(retryLimit: retryLimit, retryDelay: retryDelay, keychainService: keychainService)
        self.session = Session(interceptor: interceptor)
        self.keychainService = keychainService
    }
    
    // MARK: - Methods
    
    /// Summarize a document using Claude
    /// - Parameters:
    ///   - text: The document text to summarize
    ///   - length: Desired summary length
    ///   - model: Claude model to use, defaults to Sonnet
    ///   - completion: Callback with the result
    func summarizeDocument(
        text: String,
        length: SummaryLength,
        model: Claude3Model = .sonnet,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Check API key
        guard !apiKey.isEmpty else {
            completion(.failure(APIError.missingAPIKey))
            return
        }
        
        // Construct the prompt
        let prompt = """
        Please summarize the following document in a \(length.displayName.lowercased()) format (approximately \(length.targetWordCount) words).
        Focus on the key points and main ideas.
        
        DOCUMENT:
        \(text)
        
        SUMMARY:
        """
        
        // Create messages array
        let messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]
        
        // Request body
        let requestBody: [String: Any] = [
            "model": model.rawValue,
            "messages": messages,
            "max_tokens": min(4000, model.maxContextWindow / 10), // Limit response length
            "temperature": 0.3 // Lower temperature for more factual summaries
        ]
        
        // Make API call with retry logic
        self.callAnthropicAPIWithRetry(
            endpoint: "messages",
            requestBody: requestBody,
            retryCount: 0
        ) { result in
            switch result {
            case .success(let responseData):
                do {
                    // Parse JSON response
                    if let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                       let content = json["content"] as? [[String: Any]],
                       let firstContent = content.first,
                       let text = firstContent["text"] as? String {
                        completion(.success(text))
                    } else {
                        completion(.failure(APIError.parsingError))
                    }
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Generate text using the model with optional streaming support
    /// - Parameters:
    ///   - prompt: The prompt to generate text from
    ///   - model: Claude model to use
    ///   - systemPrompt: Optional system prompt to guide the model
    ///   - streaming: Whether to use streaming response
    ///   - completion: Callback with the result (not called when streaming is true)
    func generateText(
        prompt: String,
        model: Claude3Model = .sonnet,
        systemPrompt: String? = nil,
        streaming: Bool = false,
        completion: @escaping (Result<String, Error>) -> Void = { _ in }
    ) {
        // Check API key
        guard !apiKey.isEmpty else {
            completion(.failure(APIError.missingAPIKey))
            return
        }
        
        // Create messages array
        let messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]
        
        // Create request body
        var requestBody: [String: Any] = [
            "model": model.rawValue,
            "messages": messages,
            "max_tokens": 4000,
            "temperature": 0.7
        ]
        
        // Add system prompt if provided
        if let systemPrompt = systemPrompt, !systemPrompt.isEmpty {
            requestBody["system"] = systemPrompt
        }
        
        // Add streaming parameter if needed
        if streaming {
            requestBody["stream"] = true
            
            // Make streaming API call
            self.callAnthropicStreamingAPI(
                endpoint: "messages",
                requestBody: requestBody
            )
        } else {
            // Make API call with retry logic
            self.callAnthropicAPIWithRetry(
                endpoint: "messages",
                requestBody: requestBody,
                retryCount: 0
            ) { result in
                switch result {
                case .success(let responseData):
                    do {
                        // Parse JSON response
                        if let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                           let content = json["content"] as? [[String: Any]],
                           let firstContent = content.first,
                           let text = firstContent["text"] as? String {
                            completion(.success(text))
                        } else {
                            completion(.failure(APIError.parsingError))
                        }
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        /// Validate the API key
        /// - Parameter completion: Callback with the result
        func validateAPIKey(completion: @escaping (Result<Bool, Error>) -> Void) {
            // Check if the API key exists
            guard !apiKey.isEmpty else {
                completion(.failure(APIError.missingAPIKey))
                return
            }
            
            // Create a minimal request to test the API key
            let requestBody: [String: Any] = [
                "model": Claude3Model.haiku.rawValue,
                "messages": [
                    ["role": "user", "content": "Hello"]
                ],
                "max_tokens": 5
            ]
            
            // Make API call
            self.callAnthropicAPIWithRetry(
                endpoint: "messages",
                requestBody: requestBody,
                retryCount: 0
            ) { result in
                switch result {
                case .success(_):
                    // If we got a valid response, the API key is valid
                    completion(.success(true))
                case .failure(let error):
                    // Check if the error is authentication-related
                    if let apiError = error as? APIError, apiError == .authenticationError {
                        completion(.success(false))
                    } else {
                        completion(.failure(error))
                    }
                }
            }
        }
        
        // MARK: - Additional Methods
        
        /// Cancel any ongoing streaming request
        func cancelStreaming() {
            currentStreamingTask?.cancel()
            currentStreamingTask = nil
            
            // Send cancellation event
            let cancellationResponse = StreamingResponse(
                content: "",
                isComplete: true,
                type: .error,
                error: NSError(domain: "AnthropicService", code: -999, userInfo: [NSLocalizedDescriptionKey: "Request cancelled"])
            )
            streamingResponseSubject.send(cancellationResponse)
            apiCallStatusSubject.send(.completed)
        }
    }
    
    /// API Call Status for tracking API calls
    enum APICallStatus {
        case inProgress
        case completed
        case failed(Error)
        case streaming
        case streamingCompleted
    }
    
    /// Streaming Response Model for Claude API
    struct StreamingResponse: Equatable {
        let content: String
        let isComplete: Bool
        let type: StreamingResponseType
        let messageId: String?
        let error: Error?
        
        init(content: String, isComplete: Bool = false, type: StreamingResponseType = .contentBlock, messageId: String? = nil, error: Error? = nil) {
            self.content = content
            self.isComplete = isComplete
            self.type = type
            self.messageId = messageId
            self.error = error
        }
        
        static func == (lhs: StreamingResponse, rhs: StreamingResponse) -> Bool {
            if let lhsError = lhs.error, let rhsError = rhs.error {
                return lhs.content == rhs.content &&
                lhs.isComplete == rhs.isComplete &&
                lhs.type == rhs.type &&
                lhs.messageId == rhs.messageId &&
                lhsError.localizedDescription == rhsError.localizedDescription
            } else if lhs.error != nil || rhs.error != nil {
                return false
            }
            
            return lhs.content == rhs.content &&
            lhs.isComplete == rhs.isComplete &&
            lhs.type == rhs.type &&
            lhs.messageId == rhs.messageId
        }
    }
    
    /// Type of streaming response content
    enum StreamingResponseType: String, Codable, Equatable {
        case contentBlock = "content_block"
        case messageDelta = "message_delta"
        case messageStart = "message_start"
        case messageStop = "message_stop"
        case error = "error"
        case unknown
    }
    
    /// Anthropic API response models for streaming
    
    struct ContentBlock: Codable {
        let type: String
        let text: String?
    }
    
    struct StreamEvent: Codable {
        let type: String
        let message: StreamMessage?
        let index: Int?
        let contentBlock: ContentBlock?
        let delta: ContentDelta?
        
        enum CodingKeys: String, CodingKey {
            case type
            case message
            case index
            case contentBlock = "content_block"
            case delta
        }
    }
    
    struct StreamMessage: Codable {
        let id: String
        let type: String
        let role: String
        let content: [ContentBlock]?
        let stopReason: String?
        let stopSequence: String?
        let usage: StreamUsage?
        
        enum CodingKeys: String, CodingKey {
            case id
            case type
            case role
            case content
            case stopReason = "stop_reason"
            case stopSequence = "stop_sequence"
            case usage
        }
    }
    
    struct ContentDelta: Codable {
        let type: String
        let text: String?
    }
    
    struct StreamUsage: Codable {
        let inputTokens: Int
        let outputTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
        }
    }
    
    /// Request interceptor for handling Anthropic API authentication and retries
    class AnthropicRequestInterceptor: RequestInterceptor, @unchecked Sendable {
        private let retryLimit: Int
        private let retryDelay: TimeInterval
        private let keychainService: KeychainService
        
        init(retryLimit: Int, retryDelay: TimeInterval, keychainService: KeychainService) {
            self.retryLimit = retryLimit
            self.retryDelay = retryDelay
            self.keychainService = keychainService
        }
        
        func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
            var urlRequest = urlRequest
            
            // Add API key from keychain
            let apiKey = keychainService.retrieveApiKey(APIProvider.anthropic.rawValue) ?? ""
            if !apiKey.isEmpty {
                urlRequest.headers.add(.init(name: "x-api-key", value: apiKey))
                urlRequest.headers.add(.init(name: "Authorization", value: "Bearer \(apiKey)"))
            }
            
            // Add version header
            urlRequest.headers.add(.init(name: "anthropic-version", value: "2023-06-01"))
            
            // Add content type
            urlRequest.headers.add(.init(name: "Content-Type", value: "application/json"))
            
            completion(.success(urlRequest))
        }
        
        func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
            let response = request.response
            let retryCount = request.retryCount
            
            // Don't retry if we've hit the limit
            guard retryCount < retryLimit else {
                completion(.doNotRetry)
                return
            }
            
            // Handle specific status codes
            if let statusCode = response?.statusCode {
                switch statusCode {
                case 429: // Rate limit
                    // Calculate exponential backoff with jitter
                    let delay = calculateBackoff(retryCount: retryCount, isRateLimit: true)
                    completion(.retryWithDelay(delay))
                    return
                    
                case 500..<600: // Server errors
                    let delay = calculateBackoff(retryCount: retryCount)
                    completion(.retryWithDelay(delay))
                    return
                    
                case 401: // Authentication error - don't retry
                    completion(.doNotRetry)
                    return
                    
                default:
                    break
                }
            }
            
            // Check for network connectivity errors which should be retried
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                    let delay = calculateBackoff(retryCount: retryCount)
                    completion(.retryWithDelay(delay))
                    return
                default:
                    break
                }
            }
            
            completion(.doNotRetry)
        }
        
        func calculateBackoff(retryCount: Int, isRateLimit: Bool = false) -> TimeInterval {
            // Base exponential backoff
            var delay = retryDelay * pow(2.0, Double(retryCount))
            
            // Add extra delay for rate limits
            if isRateLimit {
                delay *= 1.5
            }
            
            // Add jitter (±20%)
            let jitter = Double.random(in: -0.2...0.2)
            delay = delay * (1.0 + jitter)
            
            return delay
        }
    }
    
    /// API Error Enum
    enum APIError: Error, Equatable {
        case invalidURL
        case noData
        case encodingError
        case parsingError
        case missingAPIKey
        case authenticationError
        case rateLimitExceeded
        case serverError
        case unknown
        
        var localizedDescription: String {
            switch self {
            case .invalidURL:
                return "Invalid API URL"
            case .noData:
                return "No data received from the server"
            case .encodingError:
                return "Error encoding request data"
            case .parsingError:
                return "Error parsing server response"
            case .missingAPIKey:
                return "API key is missing. Please add your API key in Settings"
            case .authenticationError:
                return "Authentication failed. Please check your API key"
            case .rateLimitExceeded:
                return "Rate limit exceeded. Please try again later"
            case .serverError:
                return "Server error occurred. Please try again later"
            case .unknown:
                return "An unknown error occurred"
            }
        }
        
        static func == (lhs: APIError, rhs: APIError) -> Bool {
            switch (lhs, rhs) {
            case (.invalidURL, .invalidURL),
                (.noData, .noData),
                (.encodingError, .encodingError),
                (.parsingError, .parsingError),
                (.missingAPIKey, .missingAPIKey),
                (.authenticationError, .authenticationError),
                (.rateLimitExceeded, .rateLimitExceeded),
                (.serverError, .serverError),
                (.unknown, .unknown):
                return true
            default:
                return false
            }
        }
    }
}
