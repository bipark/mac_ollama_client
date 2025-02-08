import SwiftUI
import MarkdownUI

struct DetailView: View {
    @Binding var selectedModel: String?
    @StateObject private var viewModel = ChatViewModel.shared
    @Namespace private var bottomID
    @FocusState private var isTextFieldFocused: Bool
    @State private var isGenerating = false  // 통신 상태 추적
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(viewModel.messages) { message in
                            VStack(alignment: .trailing, spacing: 4) {
                                MessageBubble(message: message)
                                if message.isUser {
                                    Text(message.formattedTime)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                            .id(message.id)
                        }
                        Color.clear
                            .frame(height: 1)
                            .id(bottomID)
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.messages.last?.content) { _ in
                    scrollToBottom(proxy: proxy)
                }
            }
            
            if let image = viewModel.selectedImage {
                HStack {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)
                        .cornerRadius(8)
                    
                    Button(action: { viewModel.selectedImage = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            // Message input area
            HStack(spacing: 8) {
                TextField("l_input_message".localized, text: $viewModel.messageText)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .cornerRadius(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(NSColor.textBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.5))
                            )
                    )
                    .foregroundColor(.primary)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        sendMessage()
                    }
                
                Spacer().frame(width: 6)
                HoverImageButton(
                    imageName: isGenerating ? "stop.circle" : "arrow.up.circle",
                    toolTip: isGenerating ? "l_stop".localized : "l_start".localized,
                    size: 22,
                    btnColor: .blue
                ) {
                    if isGenerating {
                        OllamaService.shared.cancelGeneration()
                        isGenerating = false
                    } else {
                        sendMessage()
                    }
                }
//                .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                HoverImageButton(imageName: "photo", toolTip: "l_load_image".localized, size: 22, btnColor : .blue) {
                    selectImage()
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            .overlay(
                Divider(), alignment: .top
            )
        }
        .onChange(of: viewModel.shouldFocusTextField) { shouldFocus in
            if shouldFocus {
                isTextFieldFocused = true
                viewModel.shouldFocusTextField = false
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        proxy.scrollTo(bottomID, anchor: .bottom)
    }
    
    private func selectImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                if let image = NSImage(contentsOf: url) {
                    DispatchQueue.main.async {
                        self.viewModel.selectedImage = image
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        guard let selectedModel = selectedModel,
              !viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let currentText = viewModel.messageText
        let currentImage = viewModel.selectedImage
        
        viewModel.messageText = ""
        viewModel.selectedImage = nil
        isGenerating = true  // 통신 시작
        
        let userMessage = ChatMessage(
            id: viewModel.messages.count * 2,
            content: currentText,
            isUser: true,
            timestamp: Date(),
            image: currentImage,
            engine: selectedModel
        )
        viewModel.messages.append(userMessage)
        
        let waitingMessage = ChatMessage(
            id: viewModel.messages.count * 2 + 1,
            content: "...",
            isUser: false,
            timestamp: Date(),
            image: nil,
            engine: selectedModel
        )
        viewModel.messages.append(waitingMessage)
        
        Task {
            do {
                var fullResponse = ""
                let stream = try await OllamaService.shared.generateResponse(
                    prompt: currentText,
                    image: currentImage,
                    model: selectedModel
                )
                
                for try await response in stream {
                    fullResponse += response
                    
                    if let index = viewModel.messages.lastIndex(where: { !$0.isUser }) {
                        let updatedMessage = ChatMessage(
                            id: viewModel.messages[index].id,
                            content: fullResponse,
                            isUser: false,
                            timestamp: viewModel.messages[index].timestamp,
                            image: nil,
                            engine: selectedModel
                        )
                        viewModel.messages[index] = updatedMessage
                    }
                }
                
                try DatabaseManager.shared.insert(
                    groupId: viewModel.chatId.uuidString,
                    instruction: UserDefaults.standard.string(forKey: "llmInstruction") ?? "",
                    question: currentText,
                    answer: fullResponse,
                    image: currentImage,
                    engine: selectedModel
                )
                
                Task { @MainActor in
                    await SidebarViewModel.shared.refresh()
                }
                
            } catch {
                if let index = viewModel.messages.lastIndex(where: { !$0.isUser }) {
                    let errorMessage = ChatMessage(
                        id: viewModel.messages[index].id,
                        content: "\(error.localizedDescription)",
                        isUser: false,
                        timestamp: Date(),
                        image: nil,
                        engine: selectedModel
                    )
                    viewModel.messages[index] = errorMessage
                }
            }
            
            isGenerating = false  // 통신 종료
        }
    }
}
