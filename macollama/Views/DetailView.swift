import SwiftUI
import MarkdownUI
import PDFKit
import Cocoa

struct DetailView: View {
    @Binding var selectedModel: String?
    @StateObject private var viewModel = ChatViewModel.shared
    @Namespace private var bottomID
    @FocusState private var isTextFieldFocused: Bool
    @State private var isGenerating = false  // 통신 상태 추적
    @State private var responseStartTime: Date? // 응답 시작 시간 추가
    @State private var tokenCount: Int = 0 // 토큰 카운트 추가
    
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
                TextEditor(text: $viewModel.messageText)
                    .frame(height: 60)
                    .padding(8)
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
                
                VStack(spacing: 8) {
                    HoverImageButton(
                        imageName: isGenerating ? "stop.circle" : "arrow.up.circle",
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

                    HoverImageButton(imageName: "doc.badge.plus", 
                        // toolTip: "l_load_file".localized, 
                        size: 22, 
                        btnColor: .blue
                    ) {
                        selectFile()
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
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
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image, .pdf, .plainText]
        panel.allowedFileTypes = ["md", "markdown"]
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let fileExtension = url.pathExtension.lowercased()
                
                DispatchQueue.main.async {
                    switch fileExtension {
                    case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp":
                        if let image = NSImage(contentsOf: url) {
                            self.viewModel.selectedImage = image
                        }
                    case "pdf":
                        let extractedText = self.extractTextFromPDF(pdfURL: url)
                        if !extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            self.viewModel.messageText += "\n[PDF 내용]\n" + extractedText
                        }
                    case "txt":
                        do {
                            let textContent = try String(contentsOf: url, encoding: .utf8)
                            if !textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                self.viewModel.messageText += "\n[텍스트 파일 내용]\n" + textContent
                            }
                        } catch {
                            print("텍스트 파일 읽기 실패: \(error)")
                        }
                    case "md", "markdown":
                        do {
                            let markdownContent = try String(contentsOf: url, encoding: .utf8)
                            if !markdownContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                self.viewModel.messageText += "\n[마크다운 파일 내용]\n" + markdownContent
                            }
                        } catch {
                            print("마크다운 파일 읽기 실패: \(error)")
                        }
                    default:
                        print("지원하지 않는 파일 형식: \(fileExtension)")
                    }
                }
            }
        }
    }
    
    private func extractTextFromPDF(pdfURL: URL) -> String {
        guard let pdfDocument = PDFDocument(url: pdfURL) else { return "" }
        var fullText = ""
        
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            if let pageText = page.string {
                fullText += pageText + "\n\n"
            }
        }
        
        return fullText
    }
    
    private func convertPDFToImages(pdfURL: URL) -> [String] {
        guard let pdfDocument = PDFDocument(url: pdfURL) else { return [] }
        var base64Images: [String] = []
        
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            let pageRect = page.bounds(for: .mediaBox)
            let image = NSImage(size: pageRect.size)
            
            image.lockFocus()
            NSColor.white.setFill()
            pageRect.fill()
            page.draw(with: .mediaBox, to: NSGraphicsContext.current!.cgContext)
            image.unlockFocus()
            
            if let tiffData = image.tiffRepresentation,
               let bitmapRep = NSBitmapImageRep(data: tiffData),
               let jpegData = bitmapRep.representation(using: .jpeg, properties: [:]) {
                let base64String = jpegData.base64EncodedString()
                base64Images.append(base64String)
            }
        }
        
        return base64Images
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
        
        responseStartTime = Date() // 응답 시작 시간 기록
        tokenCount = 0 // 토큰 카운트 초기화
        
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
                    tokenCount += response.count 
                    
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
                
                if let startTime = responseStartTime {
                    let elapsedTime = Date().timeIntervalSince(startTime)
                    let tokensPerSecond = Double(tokenCount) / elapsedTime
                    let statsMessage = "\n\n---\n \(String(format: "%.1f", tokensPerSecond)) tokens/sec"
                    
                    if let index = viewModel.messages.lastIndex(where: { !$0.isUser }) {
                        let updatedMessage = ChatMessage(
                            id: viewModel.messages[index].id,
                            content: fullResponse + statsMessage,
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
            
            isGenerating = false
            responseStartTime = nil
            tokenCount = 0 
        }
    }
}
