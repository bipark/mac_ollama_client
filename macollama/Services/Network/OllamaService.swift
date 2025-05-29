import Foundation
import AppKit

enum OllamaError: Error {
    case invalidURL
    case requestFailed
    case invalidResponse
    case decodingError
}

class OllamaService: NSObject, URLSessionDataDelegate {
    static let shared = OllamaService()
    private var continuation: AsyncThrowingStream<String, Error>.Continuation?
    private var lastReceivedContent: String?
    private var currentModel: String?
    private var currentTask: URLSessionDataTask?
    
    var baseURL: String {
        UserDefaults.standard.string(forKey: "serverAddress") ?? "http://localhost:11434"
    }
    
    private override init() {
        super.init()
    }
    
    func generateResponse(prompt: String, image: NSImage? = nil, model: String) async throws -> AsyncThrowingStream<String, Error> {
        currentModel = model
        
        let url = URL(string: "\(baseURL)/api/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let chatHistory = try await fetchChatHistory()
        
        var messages: [[String: Any]] = []
        
        let instruction = UserDefaults.standard.string(forKey: "llmInstruction") ?? "You are a helpful assistant."
        messages.append([
            "role": "system",
            "content": instruction
        ])
        
        for chat in chatHistory {
            messages.append([
                "role": "user",
                "content": chat.question
            ])
            messages.append([
                "role": "assistant",
                "content": chat.answer
            ])
        }
        
        var currentMessage: [String: Any] = [
            "role": "user",
            "content": prompt
        ]
        
        if let image = image,
           let imageData = image.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: imageData),
           let jpegData = bitmapImage.representation(using: .jpeg, properties: [:]),
           let base64String = String(data: jpegData.base64EncodedData(), encoding: .utf8) {
            currentMessage["images"] = [base64String]
        }
        messages.append(currentMessage)
        
        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "stream": true,
            "options": [
                "temperature": UserDefaults.standard.double(forKey: "temperature"),
                "top_p": UserDefaults.standard.double(forKey: "topP"),
                "top_k": UserDefaults.standard.double(forKey: "topK")
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        return AsyncThrowingStream { continuation in
            self.continuation = continuation
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
            let task = session.dataTask(with: request)
            self.currentTask = task
            task.resume()
            
            continuation.onTermination = { @Sendable _ in
                task.cancel()
                session.invalidateAndCancel()
                self.currentTask = nil
            }
        }
    }
    
    func urlSession(_ session: URLSession, 
                   dataTask: URLSessionDataTask, 
                   didReceive data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }
        
        text.components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .forEach { line in
                do {
                    if let jsonData = line.data(using: .utf8),
                       let response = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                        
                        if let done = response["done"] as? Bool, done {
                            if let lastContent = lastReceivedContent,
                               let model = currentModel {
                                continuation?.yield("\(lastContent)\n\n**[\(model)]**")
                            }
                            continuation?.finish()
                            continuation = nil
                            currentModel = nil
                            lastReceivedContent = nil
                            return
                        }
                        
                        if let message = response["message"] as? [String: Any],
                           let content = message["content"] as? String {
                            lastReceivedContent = content
                            continuation?.yield(content)
                        }
                    }
                } catch {
                    print("Error parsing JSON: \(error)")
                }
            }
    }
    
    func urlSession(_ session: URLSession,
                   task: URLSessionTask,
                   didCompleteWithError error: Error?) {
        if let error = error {
            continuation?.finish(throwing: error)
            continuation = nil
        }
    }
    
    private func fetchChatHistory() async throws -> [(question: String, answer: String)] {
        let groupId = ChatViewModel.shared.chatId.uuidString
        let results = try DatabaseManager.shared.fetchQuestionsByGroupId(groupId)
        return results.map { (question: $0.question, answer: $0.answer) }
    }
    
    func listModels() async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/api/tags") else {
            throw OllamaError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw OllamaError.requestFailed
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let models = json["models"] as? [[String: Any]] {
            return models.compactMap { $0["model"] as? String }
        }
        
        throw OllamaError.decodingError
    }
    
    func cancelGeneration() {
        currentTask?.cancel()
        currentTask = nil
        continuation?.finish()
        continuation = nil
        currentModel = nil
        lastReceivedContent = nil
    }
} 
