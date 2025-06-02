import Foundation
import AppKit
import swift_llm_bridge

@MainActor
class LLMService: ObservableObject {
    static let shared = LLMService()
    
    @Published var isGenerating = false
    @Published var currentResponse = ""
    
    private var bridge: LLMBridge
    private var currentTask: Task<Void, Never>?
    
    var baseURL: String {
        UserDefaults.standard.string(forKey: "serverAddress") ?? "http://localhost:11434"
    }
    
    private init() {
        // Extract host and port from baseURL directly
        let baseURLString = UserDefaults.standard.string(forKey: "serverAddress") ?? "http://localhost:11434"
        let url = URL(string: baseURLString) ?? URL(string: "http://localhost:11434")!
        let host = url.host ?? "localhost"
        let port = url.port ?? 11434
        
        self.bridge = LLMBridge(
            baseURL: "http://\(host)",
            port: port,
            target: .ollama
        )
    }
    
    func updateConfiguration() {
        let url = URL(string: baseURL) ?? URL(string: "http://localhost:11434")!
        let host = url.host ?? "localhost"
        let port = url.port ?? 11434
        
        self.bridge = bridge.createNewSession(
            baseURL: "http://\(host)",
            port: port,
            target: .ollama
        )
    }
    
    func generateResponse(prompt: String, image: NSImage? = nil, model: String) async throws -> AsyncThrowingStream<String, Error> {
        updateConfiguration()
        
        isGenerating = true
        currentResponse = ""
        
        // Convert NSImage to platform image if needed
        var platformImage: NSImage? = nil
        if let image = image {
            platformImage = image
        }
        
        return AsyncThrowingStream { continuation in
            currentTask = Task {
                do {
                    // Get chat history
                    let chatHistory = try await fetchChatHistory()
                    
                    // Build full prompt with instruction and history
                    let instruction = UserDefaults.standard.string(forKey: "llmInstruction") ?? "You are a helpful assistant."
                    var fullPrompt = instruction + "\n\n"
                    
                    // Add chat history
                    for chat in chatHistory {
                        fullPrompt += "User: \(chat.question)\n"
                        fullPrompt += "Assistant: \(chat.answer)\n\n"
                    }
                    
                    fullPrompt += "User: \(prompt)\n"
                    fullPrompt += "Assistant:"
                    
                    // Send message using bridge
                    let response = try await bridge.sendMessage(
                        content: fullPrompt,
                        image: platformImage,
                        model: model
                    )
                    
                    // Stream the response content
                    let content = response.content
                    currentResponse = content
                    
                    // Simulate streaming by yielding chunks
                    let words = content.components(separatedBy: " ")
                    for (index, word) in words.enumerated() {
                        if index == 0 {
                            continuation.yield(word)
                        } else {
                            continuation.yield(" " + word)
                        }
                        
                        // Small delay to simulate streaming
                        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                        
                        if Task.isCancelled {
                            break
                        }
                    }
                    
                    // Add model info at the end
                    continuation.yield("\n\n**[\(model)]**")
                    continuation.finish()
                    
                } catch {
                    continuation.finish(throwing: error)
                }
                
                isGenerating = false
            }
            
            continuation.onTermination = { @Sendable _ in
                Task { @MainActor in
                    self.currentTask?.cancel()
                    self.isGenerating = false
                }
            }
        }
    }
    
    func listModels() async throws -> [String] {
        updateConfiguration()
        return try await bridge.getAvailableModels()
    }
    
    func cancelGeneration() {
        currentTask?.cancel()
        bridge.cancelGeneration()
        isGenerating = false
    }
    
    private func fetchChatHistory() async throws -> [(question: String, answer: String)] {
        let groupId = ChatViewModel.shared.chatId.uuidString
        let results = try DatabaseManager.shared.fetchQuestionsByGroupId(groupId)
        return results.map { (question: $0.question, answer: $0.answer) }
    }
}

// Keep compatibility with existing OllamaError
enum OllamaError: Error {
    case invalidURL
    case requestFailed
    case invalidResponse
    case decodingError
} 