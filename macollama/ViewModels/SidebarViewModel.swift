import Foundation

@MainActor
class SidebarViewModel: ObservableObject {
    static let shared = SidebarViewModel() 
    
    @Published var chatTitles: [ChatTitle] = []
    
    func loadChatTitles() async {
        do {
            let results = try DatabaseManager.shared.fetchTitles()
            chatTitles = results.map { result in
                ChatTitle(
                    id: result.id,
                    groupId: result.groupId,
                    question: result.question,
                    created: result.created,
                    engine: result.engine,
                    image: result.image
                )
            }
        } catch {
            print("Failed to load chat titles: \(error)")
        }
    }
    
    func deleteChat(groupId: String) async throws {
        try DatabaseManager.shared.deleteGroupChats(groupId: groupId)
        await loadChatTitles()
    }
    
    func refresh() {
        Task {
            await loadChatTitles()
        }
    }
    
    func searchChatTitles(keyword: String) async {
        do {
            let results = try DatabaseManager.shared.searchMessages(keyword: keyword)
            chatTitles = results.map { result in
                ChatTitle(
                    id: result.id,
                    groupId: result.groupId,
                    question: result.question,
                    created: result.created,
                    engine: result.engine,
                    image: result.image
                )
            }
        } catch {
            print("Failed to search chat titles: \(error)")
        }
    }
} 
