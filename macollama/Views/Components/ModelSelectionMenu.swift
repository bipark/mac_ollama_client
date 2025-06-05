import SwiftUI

struct ModelSelectionMenu: View {
    @Binding var selectedModel: String?
    @Binding var selectedProvider: LLMProvider
    @Binding var models: [String]
    @Binding var isLoadingModels: Bool
    let onProviderChange: () async -> Void
    let onModelRefresh: () async -> Void
    let onCopyAllMessages: () -> Void
    
    var body: some View {
        HStack {
            Menu {
                ForEach(LLMProvider.allCases, id: \.self) { provider in
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
    }
} 