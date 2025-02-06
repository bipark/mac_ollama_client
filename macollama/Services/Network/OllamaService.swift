import Foundation
import AppKit

enum OllamaError: Error {
    case invalidURL
    case requestFailed
    case invalidResponse
    case decodingError
}

class OllamaService {
    static let shared = OllamaService()
    
    var baseURL: String {
        UserDefaults.standard.string(forKey: "serverAddress") ?? "http://localhost:11434"
    }
    
    private init() {}
    
    func generateResponse(prompt: String, image: NSImage? = nil, model: String) async throws -> AsyncThrowingStream<String, Error> {
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
                "temperature": UserDefaults.standard.double(forKey: "temperature")
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        return AsyncThrowingStream { continuation in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.finish(throwing: error)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    continuation.finish(throwing: OllamaError.invalidResponse)
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    continuation.finish(throwing: OllamaError.requestFailed)
                    return
                }
                
                guard let data = data else {
                    continuation.finish(throwing: OllamaError.invalidResponse)
                    return
                }
                
                let lines = String(decoding: data, as: UTF8.self).components(separatedBy: "\n")
                for line in lines where !line.isEmpty {
                    do {
                        if let jsonData = line.data(using: .utf8),
                           let response = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                           let message = response["message"] as? [String: Any],
                           let content = message["content"] as? String {
                            continuation.yield(content)
                        }
                    } catch {
                        continuation.finish(throwing: error)
                        return
                    }
                }
                continuation.finish()
            }
            task.resume()
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
} 
