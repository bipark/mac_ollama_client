import SwiftUI

struct ModelSelectionMenu: View {
    @Binding var selectedModel: String?
    @Binding var selectedProvider: LLMProvider
    @Binding var models: [String]
    @Binding var isLoadingModels: Bool
    let onProviderChange: () async -> Void
    let onModelRefresh: () async -> Void
    let onCopyAllMessages: () -> Void
    
    @State private var availableProviders: [LLMProvider] = []
    
    private func updateAvailableProviders() {
        availableProviders = LLMProvider.allCases.filter { provider in
            switch provider {
            case .ollama:
                return UserDefaults.standard.bool(forKey: "showOllama")
            case .lmstudio:
                return UserDefaults.standard.bool(forKey: "showLMStudio")
            case .claude:
                return UserDefaults.standard.bool(forKey: "showClaude")
            case .openai:
                return UserDefaults.standard.bool(forKey: "showOpenAI")
            }
        }
        
        // 현재 선택된 provider가 available하지 않으면 첫 번째 available provider로 변경
        if !availableProviders.contains(selectedProvider),
           let firstProvider = availableProviders.first {
            selectedProvider = firstProvider
            LLMService.shared.refreshForProviderChange()
            Task {
                await onProviderChange()
            }
        }
    }
    
    var body: some View {
        HStack {
            Menu {
                ForEach(availableProviders, id: \.self) { provider in
                    Button(action: {
                        selectedProvider = provider
                        LLMService.shared.refreshForProviderChange()
                        Task { await onProviderChange() }
                    }) {
                        HStack {
                            Text(provider.rawValue)
                            if selectedProvider == provider {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedProvider.rawValue)
                    Image(systemName: "chevron.down")
                }
            }
            .frame(width: 160)
            
            Menu {
                ForEach(models, id: \.self) { model in
                    Button(action: {
                        selectedModel = model
                    }) {
                        Text(model)
                    }
                }
                Divider()
                Button(action: { Task { await onModelRefresh() } }) {
                    HStack {
                        if isLoadingModels {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                        Label("l_refresh".localized, systemImage: "arrow.clockwise")
                    }
                }
                .disabled(isLoadingModels)
            } label: {
                HStack {
                    if isLoadingModels {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("l_loading".localized)
                    } else {
                        Text(selectedModel ?? "l_select_model".localized)
                    }
                    Image(systemName: "chevron.down")
                }
            }
            .frame(width: 300)
            .disabled(isLoadingModels)

            Spacer()
            HoverImageButton(
                imageName: "document.on.document"
            ) {
                onCopyAllMessages()
            }
        }
        .onAppear {
            updateAvailableProviders()
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            updateAvailableProviders()
        }
    }
} 