# MiddlewareConnect iOS App

## Overview

MiddlewareConnect is an iOS application that serves as a powerful middleware layer between users and Claude AI models. It provides advanced document analysis, conversation management, and a suite of PDF manipulation tools, all integrated with Claude's powerful AI capabilities.

## Key Features

- **Claude API Integration**: Seamless communication with Anthropic's Claude models
- **Advanced Document Analysis**: Extract insights, entities, and summaries from PDF documents
- **Conversation Management**: Chat with Claude with full context management and history
- **PDF Tools**: Combine, split, extract text, and annotate PDF documents
- **iCloud Synchronization**: Keep your conversations and documents in sync across devices
- **Token Management**: Optimize token usage for Claude API with advanced context window management

## Architecture

MiddlewareConnect follows a modular architecture with several key components:

### Core Services

- **API Service**: Handles communication with Claude API, including authentication, request formatting, and response parsing
- **Database Service**: Manages local storage using SQLite with the MCP server integration
- **PDF Service**: Provides PDF manipulation capabilities including OCR, text extraction, and annotations
- **LLM Tools**: Token counting, text chunking, and context window management for optimized LLM interactions
- **Cloud Service**: Handles iCloud synchronization with conflict resolution

### UI Components

- **ConversationsView**: Manages the chat interface and conversation history
- **DocumentAnalysisView**: Interface for analyzing PDF documents
- **ToolsView**: Collection of document and text processing utilities
- **SettingsView**: Configuration for API keys, model preferences, and other settings

## Technical Implementation Details

### API Integration

The app connects to Claude models via the Anthropic API with:
- Secure API key storage in Keychain
- Robust error handling and retry logic
- Support for all Claude 3 models (Haiku, Sonnet, Opus)

### Database Integration

Local data is stored in SQLite with:
- Structured schema with migrations
- Repository pattern for clean data access
- Transaction support for data integrity

### PDF Processing

PDF operations include:
- OCR for text extraction from scanned documents
- Document combination and splitting
- Text extraction and analysis
- Annotation support

### LLM Tools

LLM interaction is optimized with:
- Token counting for context management
- Text chunking for large document processing
- Context window management for efficient token usage
- Prompt templates for consistent AI interactions

## Getting Started

### Requirements

- iOS 16.0+
- Xcode 15.0+
- Claude API key from Anthropic

### Installation

1. Clone the repository:
```bash
git clone https://github.com/username/MiddlewareConnect.git
```

2. Open the project in Xcode:
```bash
cd MiddlewareConnect
open MiddlewareConnect.xcodeproj
```

3. Build and run the app on your device or simulator

4. Add your Claude API key in the Settings view

## Development Status

MiddlewareConnect is currently in active development. Current completion status:

| Phase | Component | Completion % | Status |
|-------|-----------|-------------|--------|
| Phase 1 | API Integration | 100% | Complete |
| Phase 1 | Database Integration | 100% | Complete |
| Phase 1 | PDF Processing | 80% | In Progress |
| Phase 2 | LLM Tool Integration | 100% | Complete |
| Phase 2 | Document Analysis | 100% | Complete |
| Phase 2 | Cloud Synchronization | 80% | In Progress |
| Phase 3 | UI Refinement | 80% | In Progress |
| Phase 3 | Performance Optimization | 60% | In Progress |
| Phase 3 | Feedback & Analytics | 20% | Started |
| Phase 4 | Multi-Model Support | 60% | In Progress |
| Phase 4 | Widget Development | 0% | Not Started |
| Phase 4 | Mac Catalyst Support | 0% | Not Started |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [Anthropic](https://www.anthropic.com/) for the Claude AI models
- [PDFKit](https://developer.apple.com/documentation/pdfkit) for PDF manipulation capabilities
- [Vision](https://developer.apple.com/documentation/vision) for OCR functionality
