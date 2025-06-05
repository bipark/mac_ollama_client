import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @State private var serverAddress: String = UserDefaults.standard.string(forKey: "serverAddress") ?? "http://localhost:11434"
    @State private var originalServerAddress: String = UserDefaults.standard.string(forKey: "serverAddress") ?? "http://localhost:11434"
    @State private var lmStudioAddress: String = UserDefaults.standard.string(forKey: "lmStudioAddress") ?? "http://localhost:1234"
    @State private var originalLMStudioAddress: String = UserDefaults.standard.string(forKey: "lmStudioAddress") ?? "http://localhost:1234"
    @State private var claudeApiKey: String = UserDefaults.standard.string(forKey: "claudeApiKey") ?? ""
    @State private var originalClaudeApiKey: String = UserDefaults.standard.string(forKey: "claudeApiKey") ?? ""
    @State private var openaiApiKey: String = UserDefaults.standard.string(forKey: "openaiApiKey") ?? ""
    @State private var originalOpenaiApiKey: String = UserDefaults.standard.string(forKey: "openaiApiKey") ?? ""
    @AppStorage("showOllama") private var showOllama: Bool = true
    @AppStorage("showLMStudio") private var showLMStudio: Bool = false
    @AppStorage("showClaude") private var showClaude: Bool = false
    @AppStorage("showOpenAI") private var showOpenAI: Bool = false
    @State private var llmInstruction: String = UserDefaults.standard.string(forKey: "llmInstruction") ?? "You are a helpful assistant."
    @State private var temperature: Double = UserDefaults.standard.double(forKey: "temperature")
    @State private var topP: Double = UserDefaults.standard.double(forKey: "topP") != 0 ? UserDefaults.standard.double(forKey: "topP") : 0.9
    @State private var topK: Double = UserDefaults.standard.double(forKey: "topK") != 0 ? UserDefaults.standard.double(forKey: "topK") : 40
    @State private var showingDeleteAlert = false
    @State private var isTestingConnection = false
    @State private var connectionTestResult: String?
    @State private var isTestingLMStudioConnection = false
    @State private var lmStudioConnectionTestResult: String?
    
    init(isPresented: Binding<Bool> = .constant(false)) {
        self._isPresented = isPresented
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("LLM Servers")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Toggle(isOn: $showOllama) {
                                Text("Ollama Server")
                                    .foregroundStyle(.secondary)
                            }
                            .onChange(of: showOllama) { _ in
                                Task {
                                    await ContentView.shared.loadModels()
                                }
                            }
                        }
                        HStack {
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
                            
                            Button(action: {
                                testConnection()
                            }) {
                                if isTestingConnection {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Text("l_test_connection".localized)
                                        .font(.caption)
                                }
                            }
                            .disabled(isTestingConnection)
                            .buttonStyle(.bordered)
                        }
                        
                        if let result = connectionTestResult {
                            Text(result)
                                .font(.caption)
                                .foregroundColor(result.contains("l_connection_success".localized) ? .green : .red)
                                .padding(.top, 5)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Toggle(isOn: $showLMStudio) {
                                Text("LMStudio".localized)
                                    .foregroundStyle(.secondary)
                            }
                            .onChange(of: showLMStudio) { _ in
                                Task {
                                    await ContentView.shared.loadModels()
                                }
                            }
                        }
                        HStack {
                            VStack {
                                TextEditor(text: $lmStudioAddress)
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
                            
                            Button(action: {
                                testLMStudioConnection()
                            }) {
                                if isTestingLMStudioConnection {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Text("l_test_connection".localized)
                                        .font(.caption)
                                }
                            }
                            .disabled(isTestingLMStudioConnection)
                            .buttonStyle(.bordered)
                        }
                        
                        if let result = lmStudioConnectionTestResult {
                            Text(result)
                                .font(.caption)
                                .foregroundColor(result.contains("l_connection_success".localized) ? .green : .red)
                                .padding(.top, 5)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Toggle(isOn: $showClaude) {
                                Text("Claude API Key")
                                    .foregroundStyle(.secondary)
                            }
                            .onChange(of: showClaude) { _ in
                                Task {
                                    await ContentView.shared.loadModels()
                                }
                            }
                            .disabled(claudeApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        VStack {
                            TextEditor(text: $claudeApiKey)
                                .font(.body)
                                .padding(10)
                                .foregroundColor(.primary)
                                .background(Color(NSColor.textBackgroundColor))
                                .onChange(of: claudeApiKey) { newValue in
                                    if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        showClaude = false
                                    }
                                }
                        }
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Toggle(isOn: $showOpenAI) {
                                Text("OpenAI API Key")
                                    .foregroundStyle(.secondary)
                            }
                            .onChange(of: showOpenAI) { _ in
                                Task {
                                    await ContentView.shared.loadModels()
                                }
                            }
                            .disabled(openaiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        VStack {
                            TextEditor(text: $openaiApiKey)
                                .font(.body)
                                .padding(10)
                                .foregroundColor(.primary)
                                .background(Color(NSColor.textBackgroundColor))
                                .onChange(of: openaiApiKey) { newValue in
                                    if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        showOpenAI = false
                                    }
                                }
                        }
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                }

                Section(header: Text("LLM Settings")) {
                    
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
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("l_ai_model_instruction".localized)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading) {
                            Text("TEMPERATURE")
                                .foregroundStyle(.secondary)
                            HStack {
                                Text("0.1")
                                    .font(.caption)
                                Slider(value: $temperature, in: 0.1...2.0, step: 0.1)
                                Text("2.0")
                                    .font(.caption)
                                Text(String(format: "%.1f", temperature))
                                    .font(.caption)
                                    .frame(width: 30)
                            }
                            Text("l_temperature_desc".localized)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("TOP P")
                                .foregroundStyle(.secondary)
                            HStack {
                                Text("0.1")
                                    .font(.caption)
                                Slider(value: $topP, in: 0.1...1.0, step: 0.1)
                                Text("1.0")
                                    .font(.caption)
                                Text(String(format: "%.1f", topP))
                                    .font(.caption)
                                    .frame(width: 30)
                            }
                            Text("l_top_p_desc".localized)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("TOP K")
                                .foregroundStyle(.secondary)
                            HStack {
                                Text("1")
                                    .font(.caption)
                                Slider(value: $topK, in: 1...100, step: 1)
                                Text("100")
                                    .font(.caption)
                                Text(String(format: "%.0f", topK))
                                    .font(.caption)
                                    .frame(width: 30)
                            }
                            Text("l_top_k_desc".localized)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Link("l_ollama_method".localized, destination: URL(string: "http://practical.kr/?p=828")!)
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
                        if originalServerAddress != serverAddress || originalLMStudioAddress != lmStudioAddress || originalClaudeApiKey != claudeApiKey || originalOpenaiApiKey != openaiApiKey {
                            Task {
                                saveSettings()
                                try? await Task.sleep(nanoseconds: 100_000_000)
                                await ContentView.shared.loadModels()
                                isPresented = false
                            }
                        } else {
                            saveSettings()
                            isPresented = false
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
            originalLMStudioAddress = lmStudioAddress
            originalClaudeApiKey = claudeApiKey
            originalOpenaiApiKey = openaiApiKey
        }
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(serverAddress, forKey: "serverAddress")
        UserDefaults.standard.set(lmStudioAddress, forKey: "lmStudioAddress")
        UserDefaults.standard.set(claudeApiKey, forKey: "claudeApiKey")
        UserDefaults.standard.set(openaiApiKey, forKey: "openaiApiKey")
        UserDefaults.standard.set(llmInstruction, forKey: "llmInstruction")
        UserDefaults.standard.set(temperature, forKey: "temperature")
        UserDefaults.standard.set(topP, forKey: "topP")
        UserDefaults.standard.set(topK, forKey: "topK")
        UserDefaults.standard.synchronize()
    }
    
    private func deleteAllData() {
        Task {
            do {
                try DatabaseManager.shared.deleteAllData()
                await SidebarViewModel.shared.refresh()
                ChatViewModel.shared.startNewChat()
                isPresented = false
            } catch {
                print("Failed to delete all data: \(error)")
            }
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        connectionTestResult = nil
        
        Task {
            do {
                let url = URL(string: serverAddress)
                var request = URLRequest(url: url!)
                request.httpMethod = "GET"
                request.timeoutInterval = 10.0
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        connectionTestResult = "l_connection_success".localized
                    } else {
                        connectionTestResult = "l_connection_fail_status".localized
                    }
                }
            } catch {
                connectionTestResult = "l_connection_fail".localized
            }
            
            isTestingConnection = false
        }
    }
    
    private func testLMStudioConnection() {
        isTestingLMStudioConnection = true
        lmStudioConnectionTestResult = nil
        
        Task {
            do {
                let url = URL(string: lmStudioAddress)
                var request = URLRequest(url: url!)
                request.httpMethod = "GET"
                request.timeoutInterval = 10.0
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        lmStudioConnectionTestResult = "l_connection_success".localized
                    } else {
                        lmStudioConnectionTestResult = "l_connection_fail_status".localized
                    }
                }
            } catch {
                lmStudioConnectionTestResult = "l_connection_fail".localized
            }
            
            isTestingLMStudioConnection = false
        }
    }
} 
