import SwiftUI
import PDFKit
import AppKit
import UniformTypeIdentifiers

struct ImagePreviewView: View {
    let image: NSImage
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: 60)
                .cornerRadius(8)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

struct MessageInputView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var selectedModel: String?
    @Binding var isGenerating: Bool
    @Binding var isLoadingModels: Bool
    @FocusState private var isTextFieldFocused: Bool
    @State private var cursorPosition: Int = 0
    
    let onSendMessage: () -> Void
    let onCancelGeneration: () -> Void
    
    private var messageEditor: some View {
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
            .foregroundColor(isLoadingModels ? .gray : .primary)
            .disabled(isLoadingModels)
            .focused($isTextFieldFocused)
            .background(
                GeometryReader { _ in
                    Color.clear.preference(
                        key: TextViewKey.self,
                        value: findTextView(in: NSApplication.shared.keyWindow?.contentView)
                    )
                }
            )
            .onPreferenceChange(TextViewKey.self) { textView in
                if let textView = textView {
                    cursorPosition = textView.selectedRange().location
                }
            }
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
    }
    
    private func findTextView(in view: NSView?) -> NSTextView? {
        if let textView = view as? NSTextView {
            return textView
        }
        
        for subview in view?.subviews ?? [] {
            if let textView = findTextView(in: subview) {
                return textView
            }
        }
        
        return nil
    }
    
    private var actionButtons: some View {
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
            .disabled(isLoadingModels)

            HoverImageButton(
                imageName: "doc.badge.plus", 
                size: 22, 
                btnColor: .blue
            ) {
                selectFile()
            }
            .disabled(isLoadingModels)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let image = viewModel.selectedImage {
                ImagePreviewView(image: image) {
                    viewModel.selectedImage = nil
                    viewModel.messageText = viewModel.messageText.replacingOccurrences(of: "[이미지]", with: "")
                }
            }
            
            HStack(spacing: 8) {
                messageEditor
                actionButtons
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
        panel.message = "Select a file"
        
        var allowedTypes = [
            UTType.image,
            UTType.pdf,
            UTType.text,
            UTType.plainText
        ]
        
        if let markdownType = UTType("public.markdown") {
            allowedTypes.append(markdownType)
        }
        
        panel.allowedContentTypes = allowedTypes
        panel.allowedFileTypes = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp", "pdf", "md", "markdown", "txt"]
        
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

struct TextViewKey: PreferenceKey {
    static var defaultValue: NSTextView? = nil
    
    static func reduce(value: inout NSTextView?, nextValue: () -> NSTextView?) {
        value = nextValue()
    }
} 
