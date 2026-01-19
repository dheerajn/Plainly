# Plainly

**Instant clarity from any app, private by design.**

Plainly is an iOS app that provides critical analysis and explanations of text, links, images, videos, documents, and code shared from any app. It uses AI to expose blind spots, weak assumptions, and hidden risks in content you encounter.

[![iOS](https://img.shields.io/badge/iOS-26.2+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green.svg)](https://developer.apple.com/xcode/swiftui/)

## Features

### 🎯 Critical Analysis
- **Brutally Honest Feedback**: Exposes weak reasoning, blind spots, and hidden assumptions
- **Risk Assessment**: Identifies what could go wrong and what's being underestimated
- **Second-Order Thinking**: Analyzes tradeoffs and long-term consequences

### 📱 Universal Content Support
- **Text**: Analyze any text for clarity and critical thinking
- **URLs**: Skeptical analysis of web content and articles
- **Images**: Interpret images with context awareness
- **Videos**: Cut through hype and surface what matters
- **Documents**: Review PDFs and text files for risks and obligations
- **Code**: Senior engineer-level code review and architecture analysis

### 🔒 Privacy-First Design
- **On-Device Processing**: Uses Apple Intelligence when available
- **Secure Cloud Fallback**: Firebase AI (Gemini) for complex analysis
- **No Data Selling**: Your data is never sold or shared for advertising
- **App Group Storage**: Shared history between main app and share extension

### 🎨 Modern iOS Design
- **SwiftUI**: Native iOS experience with smooth animations
- **Adaptive UI**: Supports both light and dark mode
- **Share Extension**: Access Plainly from any app's share sheet
- **History Management**: Track all your past analyses

## Architecture

### Project Structure

```
Plainly/
├── App/                          # App entry point
│   └── PlainlyApp.swift
├── Features/                     # Feature-based organization
│   ├── Home/                     # Landing page and input
│   │   ├── Views/
│   │   └── ViewModels/
│   ├── History/                  # Past explanations
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Models/
│   ├── Settings/                 # App settings
│   ├── Onboarding/              # First-time user experience
│   └── Explanation/             # Analysis results view
│       ├── Views/
│       └── ViewModels/
├── Core/                        # Shared business logic
│   ├── Services/                # AI services
│   │   ├── GeminiService.swift
│   │   └── TextExplanationService.swift
│   ├── Models/                  # Data models
│   │   ├── ShareInput.swift
│   │   └── Prompts.swift
│   └── DesignSystem/            # UI constants and styles
│       └── DesignSystem.swift
├── Shared/                      # Utilities
│   └── Extensions/
└── Resources/                   # Assets and config
    ├── Assets.xcassets
    └── Plainly.entitlements

PlainlyShare/                    # Share Extension
├── ShareViewController.swift
├── Info.plist
└── PlainlyShare.entitlements
```

### Key Technologies

- **SwiftUI**: Modern declarative UI framework
- **Firebase AI (Gemini)**: Cloud-based AI analysis
- **Apple Intelligence (Textual)**: On-device text processing
- **App Groups**: Shared data between app and extension
- **File System Synchronized Groups**: Automatic Xcode file tracking

### Design Patterns

- **MVVM**: Model-View-ViewModel architecture
- **Feature-Based Organization**: Code organized by feature, not layer
- **Dependency Injection**: ViewModels injected into views
- **Shared Code**: Core services shared between main app and extension

## Setup

### Prerequisites

- Xcode 26.2 or later
- iOS 26.2+ deployment target
- Apple Developer account (for running on device)
- Firebase project (for cloud AI features)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/Plainly.git
   cd Plainly
   ```

2. **Configure Firebase**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Download `GoogleService-Info.plist`
   - Place it in the project root directory

3. **Configure App Groups**
   - Open `Plainly.xcodeproj` in Xcode
   - Update the App Group identifier in:
     - `Plainly.entitlements`
     - `PlainlyShare.entitlements`
     - `HistoryManager.swift` (line 47)

4. **Update Bundle Identifiers**
   - Main app: `com.dheeru.Plainly` (or your own)
   - Share extension: `com.dheeru.Plainly.PlainlyShare`

5. **Build and Run**
   - Select the `Plainly` scheme
   - Choose your target device/simulator
   - Press ⌘R to build and run

## Usage

### Main App

1. **Launch Plainly** from your home screen
2. **Enter text** or tap the image/link buttons
3. **Choose processing mode**:
   - 🔒 On-Device: Private, local processing
   - ☁️ Cloud: More powerful analysis
4. **Review the analysis** with critical insights

### Share Extension

1. **Open any app** (Safari, Photos, Files, etc.)
2. **Tap the Share button**
3. **Select "Plainly"** from the share sheet
4. **Get instant analysis** of the shared content

### Supported Content Types

| Type | Example | Analysis Focus |
|------|---------|----------------|
| Text | Messages, notes | Critical thinking, assumptions |
| URLs | Articles, blogs | Skeptical analysis, bias detection |
| Images | Screenshots, photos | Context, misinterpretation risks |
| Videos | Tutorials, talks | Core claims, oversimplifications |
| Documents | PDFs, contracts | Obligations, risks, loopholes |
| Code | Swift, Python, etc. | Architecture, scalability, bugs |

## Prompts

The app uses carefully crafted prompts for different content types:

- **Base System Prompt**: Establishes critical thinking mindset
- **Text Analysis**: Challenges reasoning and exposes blind spots
- **URL Analysis**: Skeptical evaluation of web content
- **Image Analysis**: Context-aware interpretation
- **Video Analysis**: Cuts through hype
- **Document Analysis**: Legal/contractual risk assessment
- **Code Review**: Senior engineer perspective

All prompts are in [`Plainly/Core/Models/Prompts.swift`](Plainly/Core/Models/Prompts.swift).

## Privacy

Plainly takes privacy seriously:

- ✅ **On-device processing preferred**: Uses Apple Intelligence when available
- ✅ **Secure cloud fallback**: Firebase AI with encryption in transit
- ✅ **No data selling**: Your data is never sold or shared for advertising
- ✅ **Local history storage**: All history stored locally in App Group
- ✅ **No tracking**: No analytics or user tracking

See our [Privacy Policy](https://dheerajn.github.io/Plainly/privacy) for details.

## Development

### Building

```bash
# Clean build
xcodebuild clean -project Plainly.xcodeproj -scheme Plainly

# Build for device
xcodebuild -project Plainly.xcodeproj -scheme Plainly -destination 'generic/platform=iOS'

# Build for simulator
xcodebuild -project Plainly.xcodeproj -scheme Plainly -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Testing

The app uses File System Synchronized Groups, so files are automatically tracked. To verify:

```bash
# List all Swift files
find Plainly -name "*.swift" | sort

# Check folder structure
tree -L 3 Plainly
```

### Adding New Features

1. Create a new folder under `Plainly/Features/`
2. Add `Views/`, `ViewModels/`, and `Models/` subfolders as needed
3. Xcode will automatically track the files
4. Update target membership if sharing with extension

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

- **Developer**: Dheeraj Nandiraju
- **Twitter/X**: [@dheerun1210](https://x.com/dheerun1210)
- **Support**: [Contact via X](https://x.com/dheerun1210)

## Acknowledgments

- **Firebase**: Cloud AI infrastructure
- **Apple Intelligence**: On-device processing
- **Textual**: Markdown rendering library
- **SwiftUI**: Modern UI framework

---

**Made with love for clarity.** ✨
