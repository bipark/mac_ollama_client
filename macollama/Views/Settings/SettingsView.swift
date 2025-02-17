import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var serverAddress: String = UserDefaults.standard.string(forKey: "serverAddress") ?? "http://localhost:11434"
    @State private var originalServerAddress: String = UserDefaults.standard.string(forKey: "serverAddress") ?? "http://localhost:11434"
    @State private var llmInstruction: String = UserDefaults.standard.string(forKey: "llmInstruction") ?? "You are a helpful assistant."
    @State private var temperature: Double = UserDefaults.standard.double(forKey: "temperature")
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading) {
                        Text("l_ollama_sddress".localized)
                            .foregroundStyle(.secondary)
                        VStack {
                            TextEditor(text: $serverAddress)
                                .font(.body)
                                .padding(10)
                                .foregroundColor(.primary)
                                .background(Color(NSColor.textBackgroundColor))
                        }
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    VStack(alignment: .leading) {
                        Text("l_llm_inst".localized)
                            .foregroundStyle(.secondary)
                        VStack {
                            TextEditor(text: $llmInstruction)
                                .font(.body)
                                .padding(10)
                                .frame(height: 100)
                                .foregroundColor(.primary)
                                .background(Color(NSColor.textBackgroundColor))
                        }
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    VStack(alignment: .leading) {
                        Text("l_temperature".localized)
                            .foregroundStyle(.secondary)
                        VStack {
                            TextField("", value: $temperature, format: .number)
                                .padding(10)
                                .font(.body)
                                .foregroundColor(.primary)
                                .background(Color(NSColor.textBackgroundColor))
                        }
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                
                Section {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Link("l_ollama_method".localized, destination: URL(string: "http://practical.kr/?p=809")!)
                    }
                }
                
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("l_version".localized)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.gray)
                    }
                }
                
                Section {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Label("l_delete_all".localized, systemImage: "trash")
                                .foregroundColor(.red)
                                .padding(5)
                            Spacer()
                        }
                    }
                }
                

            }
            .formStyle(.grouped)
            .navigationTitle("l_settings".localized)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("l_close".localized) {
                        if originalServerAddress != serverAddress {
                            Task {
                                saveSettings()
                                try? await Task.sleep(nanoseconds: 100_000_000)
                                await ContentView.shared.loadModels()
                                dismiss()
                            }
                        } else {
                            saveSettings()
                            dismiss()
                        }
                    }
                }
            }
        }
        .frame(width: 600, height: 540)
        .fixedSize()
        .alert("l_delete_all".localized, isPresented: $showingDeleteAlert) {
            Button("l_cancel".localized, role: .cancel) { }
            Button("l_delete", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("l_delete_all_question".localized)
        }
        .onAppear {
            originalServerAddress = serverAddress
        }
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(serverAddress, forKey: "serverAddress")
        UserDefaults.standard.set(llmInstruction, forKey: "llmInstruction")
        UserDefaults.standard.set(temperature, forKey: "temperature")
        UserDefaults.standard.synchronize()
    }
    
    private func deleteAllData() {
        Task {
            do {
                try DatabaseManager.shared.deleteAllData()
                await SidebarViewModel.shared.refresh()
                ChatViewModel.shared.startNewChat()
                dismiss()
            } catch {
                print("Failed to delete all data: \(error)")
            }
        }
    }
} 
