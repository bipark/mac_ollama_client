import SwiftUI
import PDFKit
import AppKit

struct MessageInputView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var selectedModel: String?
    @Binding var isGenerating: Bool
    @FocusState private var isTextFieldFocused: Bool
    
    let onSendMessage: () -> Void
    let onCancelGeneration: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Selected image preview
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
                .padding(.bottom, 8)
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
                    .onKeyPress(.return) {
                        let event = NSApplication.shared.currentEvent
                        let shiftPressed = event?.modifierFlags.contains(.shift) ?? false
                        
                        if shiftPressed {
                            return .ignored
                        } else {
                            if !viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onSendMessage()
                            }
                            return .handled
                        }
                    }
                
                VStack(spacing: 8) {
                    HoverImageButton(
                        imageName: isGenerating ? "stop.circle" : "arrow.up.circle",
                        size: 22,
                        btnColor: .blue
                    ) {
                        if isGenerating {
                            onCancelGeneration()
                        } else {
                            onSendMessage()
                        }
                    }

                    HoverImageButton(
                        imageName: "doc.badge.plus", 
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
                            self.viewModel.messageText += "\n[PDF Content]\n" + extractedText
                        }
                    case "txt":
                        do {
                            let textContent = try String(contentsOf: url, encoding: .utf8)
                            if !textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                self.viewModel.messageText += "\n[Text File Content]\n" + textContent
                            }
                        } catch {
                            print("Text file read failed: \(error)")
                        }
                    case "md", "markdown":
                        do {
                            let markdownContent = try String(contentsOf: url, encoding: .utf8)
                            if !markdownContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                self.viewModel.messageText += "\n[Markdown File Content]\n" + markdownContent
                            }
                        } catch {
                            print("Markdown file read failed: \(error)")
                        }
                    default:
                        print("Unsupported file format: \(fileExtension)")
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
} 