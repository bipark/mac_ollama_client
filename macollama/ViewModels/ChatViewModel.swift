import Foundation
import AppKit

class ChatViewModel: ObservableObject {
    static let shared = ChatViewModel()
    
    @Published var messages: [ChatMessage] = []
    @Published var selectedImage: NSImage?
    @Published var messageText: String = ""
    @Published var chatId = UUID()
    @Published var shouldFocusTextField: Bool = false
    
    private init() {}
    
    func startNewChat() {
        messages.removeAll()
        selectedImage = nil
        messageText = ""
        chatId = UUID()
        shouldFocusTextField = true
    }
    
    @MainActor
    func loadChat(groupId: String) {
        do {
            let results = try DatabaseManager.shared.fetchQuestionsByGroupId(groupId)
            messages = []
            
            let dateFormatter = ISO8601DateFormatter()
            
            for result in results {
                var image: NSImage? = nil
                if let imageBase64 = result.image,
                   let imageData = Data(base64Encoded: imageBase64),
                   let nsImage = NSImage(data: imageData) {
                    image = nsImage
                }
                
                let timestamp = dateFormatter.date(from: result.created) ?? Date()
                
                messages.append(ChatMessage(
                    id: result.id * 2,
                    content: result.question,
                    isUser: true,
                    timestamp: timestamp,
                    image: image,
                    engine: result.engine
                ))
                
                messages.append(ChatMessage(
                    id: result.id * 2 + 1,
                    content: result.answer,
                    isUser: false,
                    timestamp: timestamp,
                    image: nil,
                    engine: result.engine
                ))
            }
            
            chatId = UUID(uuidString: groupId) ?? UUID()
        } catch {
            print("Failed to load chat: \(error)")
        }
    }
} 
