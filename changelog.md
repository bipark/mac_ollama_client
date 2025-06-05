# Change Log


### 2025/02/07 - v1.0.0

- v1.0.0 Release

### 2024/02/08 - v1.0.1

- Add SSE(Server-Sent Events) Function
- Add Communication Stop Function

### 2024/02/26 - v1.0.2

- Add token speed
- Support multi line input

### 2025/05/29 - v1.1.0

- **Enhanced Settings Panel**: Added Temperature, Top P, Top K parameter controls with intuitive sliders
- **Connection Testing**: Added server connection status checker in settings
- **Multi-format File Support**: Extended file support from images only to images, PDF documents, and text files
- **Improved File Handling**: 
  - PDF files: Automatic text extraction and inclusion in prompts
  - Text files: Direct content reading and inclusion in prompts
  - Images: Maintained existing image processing functionality
- **UI Improvements**: Enhanced settings interface with parameter descriptions and real-time value display

## 2025/06/05 - v1.2.0

- **Multi-platform LLM Support**:
  - Added LM Studio integration with local server (http://localhost:1234)
  - Added Claude API support with API key configuration
  - Added OpenAI API support with API key configuration
- **Selective Service Display**:
  - Added configurable visibility for each LLM service in model selection menu
  - Set default enabled state for Ollama service
  - Added individual toggles for LM Studio, Claude, and OpenAI services
- **Other Changes**:
  - Renamed app from "Ollama Client" to "Multi LLM Client"
  - Updated documentation in multiple languages
  - Fixed model selection handling for multiple services
  - Improved service availability checks and error handling
  - Fixed settings persistence for service visibility toggles
