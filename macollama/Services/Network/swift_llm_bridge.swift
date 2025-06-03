//
//  swift_llm_bridge.swift
//  swift-llm-bridge
//
//  Created by BillyPark on 6/1/25.
//

import Foundation
import Combine

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#endif

public enum LLMTarget: Sendable {
    case ollama
    case lmstudio
    case claude
    case openai
}

@available(iOS 15.0, macOS 12.0, *)
@MainActor
public class LLMBridge: ObservableObject {
    
    public struct Message: Identifiable, Equatable {
        public let id = UUID()
        public var content: String
        public let isUser: Bool
        public let timestamp: Date
        public let image: PlatformImage?
        
        public static func == (lhs: Message, rhs: Message) -> Bool {
            return lhs.id == rhs.id
        }
        
        public init(content: String, isUser: Bool, image: PlatformImage? = nil, timestamp: Date = Date()) {
            self.content = content
            self.isUser = isUser
            self.image = image
            self.timestamp = timestamp
        }
    }
    
    @Published public var messages: [Message] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String? = nil
    @Published public var currentResponse: String = ""
    
    private let baseURL: URL
    private let port: Int
    private let target: LLMTarget
    private let apiKey: String?
    private var generationTask: Task<Void, Never>?
    private let defaultModel = "llama3.2"
    private var tempResponse: String = ""
    
    private var getDefaultModel: String {
        switch target {
        case .ollama:
            return "llama3.2"
        case .lmstudio:
            return "llama3.2"
        case .claude:
            return "claude-3-5-sonnet-20241022"
        case .openai:
            return "gpt-4"
        }
    }
    
    private let urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 300.0
        configuration.timeoutIntervalForResource = 600.0
        configuration.waitsForConnectivity = true
        #if canImport(UIKit)
        configuration.allowsCellularAccess = true
        #endif
        configuration.httpMaximumConnectionsPerHost = 6
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }()
    
    public init(baseURL: String = "http://localhost", port: Int = 11434, target: LLMTarget = .ollama, apiKey: String? = nil) {
        if target == .claude {
            guard let url = URL(string: "https://api.anthropic.com") else {
                fatalError("Invalid Claude API URL")
            }
            self.baseURL = url
            self.port = 443
        } else if target == .openai {
            guard let url = URL(string: "https://api.openai.com") else {
                fatalError("Invalid OpenAI API URL")
            }
            self.baseURL = url
            self.port = 443
        } else {
            guard let url = URL(string: "\(baseURL):\(port)") else {
                fatalError("Invalid base URL")
            }
            self.baseURL = url
            self.port = port
        }
        self.target = target
        self.apiKey = apiKey
    }
    
    public func createNewSession(baseURL: String, port: Int, target: LLMTarget, apiKey: String? = nil) -> LLMBridge {
        return LLMBridge(baseURL: baseURL, port: port, target: target, apiKey: apiKey)
    }
    
    public func getAvailableModels() async throws -> [String] {
        let endpoint = getModelsEndpoint()
        let requestURL = baseURL.appendingPathComponent(endpoint)
        
        do {
            var request = URLRequest(url: requestURL)
            
            if target == .claude {
                guard let key = apiKey else {
                    throw NSError(domain: "LLMBridgeError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Claude API key is required"])
                }
                request.addValue("\(key)", forHTTPHeaderField: "x-api-key")
                request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            
            if target == .openai {
                guard let key = apiKey else {
                    throw NSError(domain: "LLMBridgeError", code: 401, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key is required"])
                }
                request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            
            let (data, _) = try await urlSession.data(for: request)
            
            switch target {
            case .ollama:
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let models = json["models"] as? [[String: Any]] {
                    return models.compactMap { $0["name"] as? String }
                }
            case .lmstudio:
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let data = json["data"] as? [[String: Any]] {
                    return data.compactMap { $0["id"] as? String }
                }
            case .claude:
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let data = json["data"] as? [[String: Any]] {
                    return data.compactMap { $0["id"] as? String }
                }
                // 백업으로 알려진 모델 목록 반환
                return [
                    "claude-opus-4-20250514",
                    "claude-sonnet-4-20250514", 
                    "claude-3-7-sonnet-20250219",
                    "claude-3-5-sonnet-20241022",
                    "claude-3-5-haiku-20241022",
                    "claude-3-opus-20240229",
                    "claude-3-sonnet-20240229",
                    "claude-3-haiku-20240307"
                ]
            case .openai:
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let data = json["data"] as? [[String: Any]] {
                    let availableModels = data.compactMap { $0["id"] as? String }
                    return availableModels.isEmpty ? ["gpt-3.5-turbo", "gpt-4", "gpt-4-turbo-preview", "gpt-4-vision-preview"] : availableModels
                }
                return ["gpt-3.5-turbo", "gpt-4", "gpt-4-turbo-preview", "gpt-4-vision-preview"]
            }
            
            return [getDefaultModel]
            
        } catch {
            // Claude의 경우 API 호출이 실패하면 알려진 모델 목록을 백업으로 반환
            if target == .claude {
                return [
                    "claude-opus-4-20250514",
                    "claude-sonnet-4-20250514", 
                    "claude-3-7-sonnet-20250219",
                    "claude-3-5-sonnet-20241022",
                    "claude-3-5-haiku-20241022",
                    "claude-3-opus-20240229",
                    "claude-3-sonnet-20240229",
                    "claude-3-haiku-20240307"
                ]
            }
            
            errorMessage = "Failed to fetch model list: \(error.localizedDescription)"
            throw error
        }
    }
    
    public func sendMessage(content: String, image: PlatformImage? = nil, model: String? = nil) async throws -> Message {
        isLoading = true
        errorMessage = nil
        tempResponse = ""
        currentResponse = ""
        
        let userMessage = Message(content: content, isUser: true, image: image)
        messages.append(userMessage)
        
        generationTask?.cancel()
        
        var aiMessage: Message?
        let selectedModel = model ?? getDefaultModel
        
        generationTask = Task {
            defer { isLoading = false }
            
            do {
                let endpoint = getChatEndpoint()
                let requestURL = baseURL.appendingPathComponent(endpoint)
                var request = URLRequest(url: requestURL)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                if target == .lmstudio {
                    request.addValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.addValue("keep-alive", forHTTPHeaderField: "Connection")
                } else {
                    request.addValue("application/json", forHTTPHeaderField: "Accept")
                }
                
                if target == .claude {
                    guard let key = apiKey else {
                        throw NSError(domain: "LLMBridgeError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Claude API key is required"])
                    }
                    request.addValue("\(key)", forHTTPHeaderField: "x-api-key")
                    request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                    request.addValue("text/event-stream", forHTTPHeaderField: "Accept")
                }
                
                if target == .openai {
                    guard let key = apiKey else {
                        throw NSError(domain: "LLMBridgeError", code: 401, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key is required"])
                    }
                    request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
                    request.addValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.addValue("keep-alive", forHTTPHeaderField: "Connection")
                }
                
                request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
                request.timeoutInterval = 300.0
                
                let requestData = try createChatRequest(content: content, model: selectedModel, image: image)
                request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
                
                print("Request URL: \(requestURL)")
                print("Request headers: \(request.allHTTPHeaderFields ?? [:])")
                print("Request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")
                
                try await self.processStream(request: request)
                
                if !tempResponse.isEmpty {
                    let message = Message(content: tempResponse, isUser: false, image: nil, timestamp: Date())
                    messages.append(message)
                    aiMessage = message
                    
                    tempResponse = ""
                    currentResponse = ""
                }
                
            } catch {
                errorMessage = error.localizedDescription
                
                if !Task.isCancelled && !tempResponse.isEmpty {
                    let message = Message(content: tempResponse + "\nAn error occurred.", isUser: false, image: nil, timestamp: Date())
                    messages.append(message)
                    aiMessage = message
                    
                    tempResponse = ""
                    currentResponse = ""
                }
            }
        }
        
        await generationTask?.value
        
        return aiMessage ?? Message(content: "Failed to generate response.", isUser: false, image: nil, timestamp: Date())
    }
    
    public func sendMessageStream(content: String, image: PlatformImage? = nil, model: String? = nil) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task { @MainActor in
                isLoading = true
                errorMessage = nil
                tempResponse = ""
                currentResponse = ""
                
                let userMessage = Message(content: content, isUser: true, image: image)
                messages.append(userMessage)
                
                generationTask?.cancel()
                
                let selectedModel = model ?? getDefaultModel
                
                generationTask = Task {
                    defer { 
                        Task { @MainActor in
                            isLoading = false
                        }
                    }
                    
                    do {
                        let endpoint = getChatEndpoint()
                        let requestURL = baseURL.appendingPathComponent(endpoint)
                        var request = URLRequest(url: requestURL)
                        request.httpMethod = "POST"
                        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        
                        if target == .lmstudio {
                            request.addValue("text/event-stream", forHTTPHeaderField: "Accept")
                            request.addValue("keep-alive", forHTTPHeaderField: "Connection")
                        } else {
                            request.addValue("application/json", forHTTPHeaderField: "Accept")
                        }
                        
                        if target == .claude {
                            guard let key = apiKey else {
                                throw NSError(domain: "LLMBridgeError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Claude API key is required"])
                            }
                            request.addValue("\(key)", forHTTPHeaderField: "x-api-key")
                            request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                            request.addValue("text/event-stream", forHTTPHeaderField: "Accept")
                        }
                        
                        if target == .openai {
                            guard let key = apiKey else {
                                throw NSError(domain: "LLMBridgeError", code: 401, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key is required"])
                            }
                            request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
                            request.addValue("text/event-stream", forHTTPHeaderField: "Accept")
                            request.addValue("keep-alive", forHTTPHeaderField: "Connection")
                        }
                        
                        request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
                        request.timeoutInterval = 300.0
                        
                        let requestData = try createChatRequest(content: content, model: selectedModel, image: image)
                        request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
                        
                        print("Request URL: \(requestURL)")
                        print("Request headers: \(request.allHTTPHeaderFields ?? [:])")
                        print("Request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")
                        
                        try await self.processStreamWithContinuation(request: request, continuation: continuation)
                        
                        if !tempResponse.isEmpty {
                            let message = Message(content: tempResponse, isUser: false, image: nil, timestamp: Date())
                            await MainActor.run {
                                messages.append(message)
                            }
                            
                            tempResponse = ""
                            currentResponse = ""
                        }
                        
                        continuation.finish()
                        
                    } catch {
                        await MainActor.run {
                            errorMessage = error.localizedDescription
                        }
                        
                        if !Task.isCancelled && !tempResponse.isEmpty {
                            let message = Message(content: tempResponse + "\nAn error occurred.", isUser: false, image: nil, timestamp: Date())
                            await MainActor.run {
                                messages.append(message)
                            }
                            
                            tempResponse = ""
                            currentResponse = ""
                        }
                        
                        continuation.finish(throwing: error)
                    }
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                Task { @MainActor in
                    self.generationTask?.cancel()
                    self.isLoading = false
                }
            }
        }
    }
    
    public func cancelGeneration() {
        generationTask?.cancel()
        
        if !tempResponse.isEmpty {
            let message = Message(content: tempResponse + "\nCancelled by user.", isUser: false, image: nil, timestamp: Date())
            messages.append(message)
            
            tempResponse = ""
            currentResponse = ""
        }
    }
    
    public func clearMessages() {
        messages.removeAll()
        errorMessage = nil
        tempResponse = ""
        currentResponse = ""
    }
    
    private func getModelsEndpoint() -> String {
        switch target {
        case .ollama:
            return "api/tags"
        case .lmstudio:
            return "v1/models"
        case .claude:
            return "v1/models"
        case .openai:
            return "v1/models"
        }
    }
    
    private func getChatEndpoint() -> String {
        switch target {
        case .ollama:
            return "api/chat"
        case .lmstudio:
            return "v1/chat/completions"
        case .claude:
            return "v1/messages"
        case .openai:
            return "v1/chat/completions"
        }
    }
    
    private func createChatRequest(content: String, model: String, image: PlatformImage?) throws -> [String: Any] {
        switch target {
        case .ollama:
            return createOllamaChatRequest(content: content, model: model, image: image)
        case .lmstudio:
            return createLMStudioChatRequest(content: content, model: model, image: image)
        case .claude:
            return createClaudeChatRequest(content: content, model: model, image: image)
        case .openai:
            return createOpenAIChatRequest(content: content, model: model, image: image)
        }
    }
    
    private func createOllamaChatRequest(content: String, model: String, image: PlatformImage?) -> [String: Any] {
        var chatMessages: [[String: Any]] = []
        
        for message in messages.dropLast() {
            let role = message.isUser ? "user" : "assistant"
            chatMessages.append(["role": role, "content": message.content])
        }
        
        var currentUserMessage: [String: Any] = [
            "role": "user",
            "content": content
        ]
        
        if let userImage = image,
           let imageBase64 = encodeImageToBase64(userImage) {
            currentUserMessage["images"] = [imageBase64]
        }
        
        chatMessages.append(currentUserMessage)
        
        return [
            "model": model,
            "messages": chatMessages,
            "stream": true,
            "temperature": 0.7,
            "top_p": 0.9,
            "top_k": 40
        ]
    }
    
    private func createLMStudioChatRequest(content: String, model: String, image: PlatformImage?) -> [String: Any] {
        var chatMessages: [[String: Any]] = []
        
        for message in messages.dropLast() {
            let role = message.isUser ? "user" : "assistant"
            let messageDict: [String: Any] = [
                "role": role,
                "content": message.content
            ]
            chatMessages.append(messageDict)
        }
        
        let currentUserMessage: [String: Any] = [
            "role": "user",
            "content": content
        ]
        
        chatMessages.append(currentUserMessage)
        
        return [
            "model": model,
            "messages": chatMessages,
            "stream": true,
            "temperature": 0.7,
            "max_tokens": 2048
        ]
    }
    
    private func createClaudeChatRequest(content: String, model: String, image: PlatformImage?) -> [String: Any] {
        var claudeMessages: [[String: Any]] = []
        
        for message in messages.dropLast() {
            let role = message.isUser ? "user" : "assistant"
            claudeMessages.append(["role": role, "content": message.content])
        }
        
        var currentContent: [[String: Any]] = []
        
        if let userImage = image,
           let imageBase64 = encodeImageToBase64(userImage) {
            currentContent.append([
                "type": "image",
                "source": [
                    "type": "base64",
                    "media_type": "image/jpeg",
                    "data": imageBase64
                ]
            ])
        }
        
        currentContent.append([
            "type": "text",
            "text": content
        ])
        
        claudeMessages.append([
            "role": "user",
            "content": currentContent
        ])
        
        return [
            "model": model,
            "messages": claudeMessages,
            "max_tokens": 4096,
            "stream": true,
            "temperature": 0.7
        ]
    }
    
    private func createOpenAIChatRequest(content: String, model: String, image: PlatformImage?) -> [String: Any] {
        var chatMessages: [[String: Any]] = []
        
        for message in messages.dropLast() {
            let role = message.isUser ? "user" : "assistant"
            chatMessages.append(["role": role, "content": message.content])
        }
        
        var currentUserMessage: [String: Any] = [
            "role": "user"
        ]
        
        if let userImage = image,
           let imageBase64 = encodeImageToBase64(userImage) {
            let imageContent: [String: Any] = [
                "type": "image_url",
                "image_url": [
                    "url": "data:image/jpeg;base64,\(imageBase64)"
                ]
            ]
            let textContent: [String: Any] = [
                "type": "text",
                "text": content
            ]
            currentUserMessage["content"] = [textContent, imageContent]
        } else {
            currentUserMessage["content"] = content
        }
        
        chatMessages.append(currentUserMessage)
        
        return [
            "model": model,
            "messages": chatMessages,
            "stream": true,
            "temperature": 0.7,
            "max_tokens": 4096
        ]
    }
    
    private func processStream(request: URLRequest) async throws {
        let (asyncBytes, response) = try await urlSession.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = "Server error: HTTP \(httpResponse.statusCode)"
            throw NSError(domain: "LLMBridgeError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        do {
            for try await line in asyncBytes.lines {
                if Task.isCancelled { break }
                
                if line.isEmpty { continue }
                
                await processStreamLine(line)
            }
        } catch {
            if !Task.isCancelled {
                throw error
            }
        }
    }
    
    private func processStreamLine(_ line: String) async {
        var jsonLine = line
        
        if target == .lmstudio {
            print("LMStudio raw line: '\(line)'")
            
            if line.hasPrefix("data: ") {
                jsonLine = String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
                print("LMStudio extracted JSON: '\(jsonLine)'")
                
                if jsonLine == "[DONE]" || jsonLine.isEmpty { 
                    print("LMStudio stream finished")
                    return 
                }
            } else if line.hasPrefix("event:") || line.hasPrefix(":") || line.isEmpty {
                print("LMStudio skipping SSE metadata: '\(line)'")
                return
            } else if !line.hasPrefix("{") {
                print("LMStudio skipping non-JSON line: '\(line)'")
                return
            }
        }
        
        if target == .claude {
            print("Claude raw line: '\(line)'")
            
            if line.hasPrefix("data: ") {
                jsonLine = String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
                print("Claude extracted JSON: '\(jsonLine)'")
                
                if jsonLine == "[DONE]" || jsonLine.isEmpty {
                    print("Claude stream finished")
                    return
                }
            } else if line.hasPrefix("event:") || line.hasPrefix(":") || line.isEmpty {
                print("Claude skipping SSE metadata: '\(line)'")
                return
            } else if !line.hasPrefix("{") {
                print("Claude skipping non-JSON line: '\(line)'")
                return
            }
        }
        
        if target == .openai {
            print("OpenAI raw line: '\(line)'")
            
            if line.hasPrefix("data: ") {
                jsonLine = String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
                print("OpenAI extracted JSON: '\(jsonLine)'")
                
                if jsonLine == "[DONE]" || jsonLine.isEmpty {
                    print("OpenAI stream finished")
                    return
                }
            } else if line.hasPrefix("event:") || line.hasPrefix(":") || line.isEmpty {
                print("OpenAI skipping SSE metadata: '\(line)'")
                return
            } else if !line.hasPrefix("{") {
                print("OpenAI skipping non-JSON line: '\(line)'")
                return
            }
        }
        
        guard !jsonLine.isEmpty,
              let data = jsonLine.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("Failed to parse JSON: '\(jsonLine)'")
            return
        }
        
        switch target {
        case .ollama:
            await processOllamaStream(json)
        case .lmstudio:
            await processLMStudioStream(json)
        case .claude:
            await processClaudeStream(json)
        case .openai:
            await processOpenAIChatStream(json)
        }
    }
    
    private func processOllamaStream(_ json: [String: Any]) async {
        if let message = json["message"] as? [String: Any],
           let content = message["content"] as? String {
            tempResponse += content
            currentResponse = tempResponse
            print("Ollama content: \(currentResponse)")
        }
        
        if let done = json["done"] as? Bool, done {
            return
        }
    }
    
    private func processLMStudioStream(_ json: [String: Any]) async {
        print("LMStudio JSON: \(json)")
        
        if let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let delta = firstChoice["delta"] as? [String: Any],
           let content = delta["content"] as? String {
            print("LMStudio content chunk: '\(content)'")
            tempResponse += content
            currentResponse = tempResponse
            print("LMStudio accumulated: '\(currentResponse)'")
        }
        
        if let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let finishReason = firstChoice["finish_reason"] as? String,
           finishReason == "stop" {
            print("LMStudio stream completed with finish_reason: stop")
            return
        }
    }
    
    private func processClaudeStream(_ json: [String: Any]) async {
        print("Claude JSON: \(json)")
        
        if let type = json["type"] as? String {
            switch type {
            case "content_block_delta":
                if let delta = json["delta"] as? [String: Any],
                   let text = delta["text"] as? String {
                    print("Claude content chunk: '\(text)'")
                    tempResponse += text
                    currentResponse = tempResponse
                    print("Claude accumulated: '\(currentResponse)'")
                }
            case "message_stop":
                print("Claude stream completed with message_stop")
                return
            default:
                break
            }
        }
    }
    
    private func processOpenAIChatStream(_ json: [String: Any]) async {
        print("OpenAI JSON: \(json)")
        
        if let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let delta = firstChoice["delta"] as? [String: Any],
           let content = delta["content"] as? String {
            print("OpenAI content chunk: '\(content)'")
            tempResponse += content
            currentResponse = tempResponse
            print("OpenAI accumulated: '\(currentResponse)'")
        }
        
        if let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let finishReason = firstChoice["finish_reason"] as? String,
           finishReason == "stop" {
            print("OpenAI stream completed with finish_reason: stop")
            return
        }
    }
    
    private func processStreamWithContinuation(request: URLRequest, continuation: AsyncThrowingStream<String, Error>.Continuation) async throws {
        let (asyncBytes, response) = try await urlSession.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = "Server error: HTTP \(httpResponse.statusCode)"
            throw NSError(domain: "LLMBridgeError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        do {
            for try await line in asyncBytes.lines {
                if Task.isCancelled { break }
                
                if line.isEmpty { continue }
                
                await processStreamLineWithContinuation(line, continuation: continuation)
            }
        } catch {
            if !Task.isCancelled {
                throw error
            }
        }
    }
    
    private func processStreamLineWithContinuation(_ line: String, continuation: AsyncThrowingStream<String, Error>.Continuation) async {
        var jsonLine = line
        
        if target == .lmstudio {
            if line.hasPrefix("data: ") {
                jsonLine = String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if jsonLine == "[DONE]" || jsonLine.isEmpty { 
                    return 
                }
            } else if line.hasPrefix("event:") || line.hasPrefix(":") || line.isEmpty {
                return
            } else if !line.hasPrefix("{") {
                return
            }
        }
        
        if target == .claude {
            if line.hasPrefix("data: ") {
                jsonLine = String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if jsonLine == "[DONE]" || jsonLine.isEmpty {
                    return
                }
            } else if line.hasPrefix("event:") || line.hasPrefix(":") || line.isEmpty {
                return
            } else if !line.hasPrefix("{") {
                return
            }
        }
        
        if target == .openai {
            if line.hasPrefix("data: ") {
                jsonLine = String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if jsonLine == "[DONE]" || jsonLine.isEmpty {
                    return
                }
            } else if line.hasPrefix("event:") || line.hasPrefix(":") || line.isEmpty {
                return
            } else if !line.hasPrefix("{") {
                return
            }
        }
        
        guard !jsonLine.isEmpty,
              let data = jsonLine.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        switch target {
        case .ollama:
            await processOllamaStreamWithContinuation(json, continuation: continuation)
        case .lmstudio:
            await processLMStudioStreamWithContinuation(json, continuation: continuation)
        case .claude:
            await processClaudeStreamWithContinuation(json, continuation: continuation)
        case .openai:
            await processOpenAIStreamWithContinuation(json, continuation: continuation)
        }
    }
    
    private func processOllamaStreamWithContinuation(_ json: [String: Any], continuation: AsyncThrowingStream<String, Error>.Continuation) async {
        if let message = json["message"] as? [String: Any],
           let content = message["content"] as? String {
            tempResponse += content
            await MainActor.run {
                currentResponse = tempResponse
            }
            continuation.yield(content)
        }
        
        if let done = json["done"] as? Bool, done {
            return
        }
    }
    
    private func processLMStudioStreamWithContinuation(_ json: [String: Any], continuation: AsyncThrowingStream<String, Error>.Continuation) async {
        if let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let delta = firstChoice["delta"] as? [String: Any],
           let content = delta["content"] as? String {
            tempResponse += content
            await MainActor.run {
                currentResponse = tempResponse
            }
            continuation.yield(content)
        }
        
        if let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let finishReason = firstChoice["finish_reason"] as? String,
           finishReason == "stop" {
            return
        }
    }
    
    private func processClaudeStreamWithContinuation(_ json: [String: Any], continuation: AsyncThrowingStream<String, Error>.Continuation) async {
        if let type = json["type"] as? String {
            switch type {
            case "content_block_delta":
                if let delta = json["delta"] as? [String: Any],
                   let text = delta["text"] as? String {
                    tempResponse += text
                    await MainActor.run {
                        currentResponse = tempResponse
                    }
                    continuation.yield(text)
                }
            case "message_stop":
                return
            default:
                break
            }
        }
    }
    
    private func processOpenAIStreamWithContinuation(_ json: [String: Any], continuation: AsyncThrowingStream<String, Error>.Continuation) async {
        if let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let delta = firstChoice["delta"] as? [String: Any],
           let content = delta["content"] as? String {
            tempResponse += content
            await MainActor.run {
                currentResponse = tempResponse
            }
            continuation.yield(content)
        }
        
        if let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let finishReason = firstChoice["finish_reason"] as? String,
           finishReason == "stop" {
            return
        }
    }
    
    private func encodeImageToBase64(_ image: PlatformImage, compressionQuality: CGFloat = 0.8) -> String? {
        #if canImport(UIKit)
        let resizedImage = resizeImageIfNeeded(image, maxSize: 1024)
        guard let imageData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        return imageData.base64EncodedString()
        #elseif canImport(AppKit)
        let resizedImage = resizeImageIfNeeded(image, maxSize: 1024)
        guard let cgImage = resizedImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let imageData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality]) else {
            return nil
        }
        return imageData.base64EncodedString()
        #endif
    }
    
    #if canImport(UIKit)
    private func resizeImageIfNeeded(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        let maxDimension = max(size.width, size.height)
        
        if maxDimension <= maxSize {
            return image
        }
        
        let scaleFactor = maxSize / maxDimension
        let newWidth = size.width * scaleFactor
        let newHeight = size.height * scaleFactor
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    #elseif canImport(AppKit)
    private func resizeImageIfNeeded(_ image: NSImage, maxSize: CGFloat) -> NSImage {
        let size = image.size
        let maxDimension = max(size.width, size.height)
        
        if maxDimension <= maxSize {
            return image
        }
        
        let scaleFactor = maxSize / maxDimension
        let newWidth = size.width * scaleFactor
        let newHeight = size.height * scaleFactor
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        image.draw(in: CGRect(origin: .zero, size: newSize))
        resizedImage.unlockFocus()
        
        return resizedImage
    }
    #endif
    
    public func getBaseURL() -> URL {
        return baseURL
    }
    
    public func getPort() -> Int {
        return port
    }
    
    public func getTarget() -> LLMTarget {
        return target
    }
}
