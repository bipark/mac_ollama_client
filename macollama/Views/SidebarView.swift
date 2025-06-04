import SwiftUI

struct ChatTitle: Identifiable, Equatable {
    let id: Int
    let groupId: String
    let question: String
    let created: String
    let engine: String
    let image: String?
    
    var formattedDate: String {
        let dateFormatter = ISO8601DateFormatter()
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        if let date = dateFormatter.date(from: created) {
            return outputFormatter.string(from: date)
        }
        return created
    }
    
    static func == (lhs: ChatTitle, rhs: ChatTitle) -> Bool {
        return lhs.id == rhs.id &&
               lhs.groupId == rhs.groupId &&
               lhs.question == rhs.question &&
               lhs.created == rhs.created &&
               lhs.engine == rhs.engine &&
               lhs.image == rhs.image
    }
}

struct SidebarView: View {
    @ObservedObject private var viewModel = SidebarViewModel.shared
    @StateObject private var chatViewModel = ChatViewModel.shared
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: ChatTitle?
    @State private var selectedGroupId: String?
    @State private var searchText = ""
    @State private var isSearching = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("l_search".localized, text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.primary)
                    .onChange(of: searchText) { newValue in
                        isSearching = !newValue.isEmpty
                        Task {
                            if newValue.isEmpty {
                                await viewModel.loadChatTitles()
                            } else {
                                await viewModel.searchChatTitles(keyword: newValue)
                            }
                        }
                    }
                
                if isSearching {
                    Button(action: {
                        searchText = ""
                        isSearching = false
                        Task {
                            await viewModel.loadChatTitles()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.vertical, 4)
            
            ScrollViewReader { proxy in
                List(viewModel.chatTitles, selection: $selectedGroupId) { chat in
                    HStack(spacing: 12) {
                        if let imageBase64 = chat.image,
                           let imageData = Data(base64Encoded: imageBase64),
                           let nsImage = NSImage(data: imageData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(chat.question)
                                .lineLimit(2)
                                .font(.headline)
                            
                            HStack {
                                Text(chat.formattedDate)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedGroupId = chat.groupId
                            chatViewModel.loadChat(groupId: chat.groupId)
                        }
                        
                        Spacer()
                        HoverImageButton(imageName: "trash", size: 14, btnColor : .red) {
                            itemToDelete = chat
                            showingDeleteAlert = true
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 1)
                    .background(chat.groupId == selectedGroupId ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(6)
                }
                .listStyle(.sidebar)
                .task {
                    await viewModel.loadChatTitles()
                    if let firstChat = viewModel.chatTitles.first {
                        selectedGroupId = firstChat.groupId
                        chatViewModel.loadChat(groupId: firstChat.groupId)
                    }
                }
                .onChange(of: viewModel.chatTitles) { _ in
                    if let firstId = viewModel.chatTitles.first?.id {
                        withAnimation {
                            proxy.scrollTo(firstId, anchor: .top)
                        }
                    }
                }
                .onChange(of: chatViewModel.chatId) { newId in
                    selectedGroupId = newId.uuidString
                }
                .alert("l_del_question".localized, isPresented: $showingDeleteAlert) {
                    Button("l_cancel".localized, role: .cancel) { }
                    Button("l_delete".localized, role: .destructive) {
                        if let chat = itemToDelete {
                            Task {
                                try? await viewModel.deleteChat(groupId: chat.groupId)
                                if chatViewModel.chatId.uuidString == chat.groupId {
                                    chatViewModel.startNewChat()
                                }
                            }
                        }
                    }
                } message: {
                    Text("l_del_question".localized)
                }
            }
        }
        .frame(minWidth: 260)
    }
}
