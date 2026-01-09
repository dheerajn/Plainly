import SwiftUI
import Combine
import UniformTypeIdentifiers
import UIKit

@MainActor
class ExplanationViewModel: ObservableObject {
    @Published var explanation: ExplanationResult?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedMode: ExplanationMode = .onDevice
    @Published var loadingText: String = "Loading..."
    @Published var displayInput: String?
    @Published var displayImageData: Data?
    @Published var isFromHistory: Bool = false
    
    private let textService = TextExplanationService()
    private let geminiService = GeminiService()
    private let youtubeRegexPattern = #"(?i)((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)([\w\-]+)(\S+)?"#

    init(input: ShareInput? = nil, historyItem: HistoryItem? = nil) {
        if let item = historyItem {
            // Restore from History
            self.explanation = ExplanationResult(markdown: item.resultMarkdown)
            self.displayInput = item.originalInput
            self.displayImageData = item.imageData
            self.isLoading = false
            self.selectedMode = item.isCloud ? .gemini : .onDevice
            self.loadingText = "Restored from History"
            self.isFromHistory = true
        } else if let input = input {
            configureMode(for: input)
            updateDisplayInput(for: input)
            self.isFromHistory = false
        }
    }
    
    private func updateDisplayInput(for input: ShareInput) {
        switch input {
        case .text(let text): self.displayInput = text
        case .url(let url): self.displayInput = url.absoluteString
        case .videoData: self.displayInput = "Uploaded Video"
        case .imageData: self.displayInput = "Uploaded Image"
        case .document(_, _, let fileName): self.displayInput = "Document: \(fileName)"
        case .code(_, _, let fileName): self.displayInput = "Source Code: \(fileName)"
        }
    }
    
    private func configureMode(for input: ShareInput) {
        switch input {
        case .url, .videoData, .imageData, .document, .code:
            self.selectedMode = .gemini
        case .text(let text):
            self.selectedMode = isYouTubeURL(text) ? .gemini : .onDevice
        }
    }
    
    // MARK: - Cache
    private var resultCache: [ExplanationMode: String] = [:]
    private var hasSavedToHistory = false

    func processInput(_ input: ShareInput?) async {
        guard let input = input else {
            self.isLoading = false
            self.errorMessage = "No input found."
            return
        }
        
        // Check Cache first
        if let cachedResult = resultCache[selectedMode] {
            self.explanation = ExplanationResult(markdown: cachedResult)
            self.isLoading = false
            self.errorMessage = nil
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        self.explanation = nil
        updateLoadingText(for: input)
        
        do {
            let markdown: String
            switch input {
            case .text(let text):
                if let youtubeURL = extractYouTubeURL(from: text) {
                    markdown = try await geminiService.explainVideo(url: youtubeURL)
                } else if selectedMode == .gemini {
                    markdown = try await geminiService.explainText(text: text)
                } else {
                    let result = try await textService.explain(text: text)
                    markdown = result.markdown
                }
            case .url(let url):
                if isYouTubeURL(url.absoluteString) {
                    markdown = try await geminiService.explainVideo(url: url)
                } else {
                    markdown = try await geminiService.explainLink(url: url)
                }
            case .videoData(let data):
                markdown = try await geminiService.explainVideoData(data: data)
            case .imageData(let data):
                markdown = try await geminiService.explainImage(data: data)
            case .document(let data, let type, let fileName):
                markdown = try await geminiService.explainDocument(data: data, fileName: fileName, mimeType: type.preferredMIMEType ?? "application/pdf")
            case .code(let code, _, let fileName):
                let language = fileName.components(separatedBy: ".").last ?? "Code"
                markdown = try await geminiService.explainCode(code: code, fileName: fileName, language: language)
            }
            
            // Update Cache
            resultCache[selectedMode] = markdown
            
            self.explanation = ExplanationResult(markdown: markdown)
            self.isLoading = false
            
            // SAVE TO HISTORY (Only if it's the first save for this session/request)
            if !hasSavedToHistory {
                saveToHistory(input: input, markdown: markdown)
                hasSavedToHistory = true
            }
            
        } catch {
            self.errorMessage = "Failed: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    private func saveToHistory(input: ShareInput, markdown: String) {
        let historyType: HistoryItem.HistoryType
        let historyText: String
        let inputTitle: String
        
        switch input {
        case .text(let text):
            historyType = .text
            historyText = text
            if isYouTubeURL(text) {
                inputTitle = text // Show full YouTube URL
            } else {
                // First line of text
                inputTitle = text.components(separatedBy: .newlines).first ?? "Text Request"
            }
        case .url(let url):
            historyType = .url
            historyText = url.absoluteString
            inputTitle = historyText // Full link (including YouTube)
        case .videoData:
            historyType = .video
            historyText = "Video File Upload"
            inputTitle = "Video Clip"
        case .imageData:
            historyType = .image
            historyText = "Image File Upload"
            inputTitle = "Image"
        case .document(_, _, let fileName):
            historyType = .document
            historyText = "Document Upload: \(fileName)"
            inputTitle = fileName
        case .code(_, _, let fileName):
            historyType = .code
            historyText = "Code Upload: \(fileName)"
            inputTitle = fileName
        }
        
        let item = HistoryItem(
            date: Date(),
            inputTitle: inputTitle,
            originalInput: historyText,
            resultMarkdown: markdown,
            isCloud: self.selectedMode == .gemini,
            type: historyType,
            imageData: {
                if case .imageData(let data) = input { return data }
                return nil
            }()
        )
        
        HistoryManager.shared.save(item)
    }
    
    func retry(input: ShareInput?) {
        Task { await processInput(input) }
    }
    
    func refresh(input: ShareInput?) {
        resultCache.removeAll()
        Task { await processInput(input) }
    }

    private func updateLoadingText(for input: ShareInput) {
        switch input {
        case .url: loadingText = "Reading Link..."
        case .videoData: loadingText = "Analyzing Video..."
        case .imageData: loadingText = "Analyzing Image..."
        case .text: loadingText = "Processing..."
        case .document: loadingText = "Reading Document..."
        case .code: loadingText = "Analyzing Code..."
        }
    }
    
    func isYouTubeURL(_ text: String) -> Bool {
        return extractYouTubeURL(from: text) != nil
    }
    
    private func extractYouTubeURL(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let regex = try? NSRegularExpression(pattern: youtubeRegexPattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: trimmed.utf16.count)
            if regex.firstMatch(in: trimmed, options: [], range: range) != nil {
                 if let url = URL(string: trimmed), url.scheme != nil, url.host != nil {
                     return url
                 }
            }
        }
        return nil
    }
    
    func shouldShowModePicker(for input: ShareInput?) -> Bool {
        guard let input = input else { return false }
        if case .text(let text) = input {
            return !isYouTubeURL(text)
        }
        return false
    }

    func copyToClipboard(markdown: String) {
        do {
            // Parse Markdown to AttributedString
            // We use inlineOnlyPreservingWhitespace to keep it simple, 
            // but we can try full markdown support if needed.
            let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            let attributedString = try AttributedString(markdown: markdown, options: options)
            
            // Convert to NSAttributedString to manipulate fonts and export to RTF
            let nsAttributedString = NSMutableAttributedString(attributedString: NSAttributedString(attributedString))
            let fullRange = NSRange(location: 0, length: nsAttributedString.length)
            
            // Apply Rounded Font Design
            let baseFont = UIFont.preferredFont(forTextStyle: .body)
            let roundedFont: UIFont
            if let descriptor = baseFont.fontDescriptor.withDesign(.rounded) {
                roundedFont = UIFont(descriptor: descriptor, size: baseFont.pointSize)
            } else {
                roundedFont = baseFont
            }
            
            // Update the font while preserving other traits like bold/italic if possible
            // A more robust way is to enumerate attributes and swap descriptors
            nsAttributedString.enumerateAttribute(NSAttributedString.Key.font, in: fullRange, options: []) { (font, range, stop) in
                if let currentFont = font as? UIFont {
                    if let descriptor = currentFont.fontDescriptor.withDesign(.rounded) {
                        let newFont = UIFont(descriptor: descriptor, size: currentFont.pointSize)
                        nsAttributedString.addAttribute(NSAttributedString.Key.font, value: newFont, range: range)
                    }
                } else {
                    nsAttributedString.addAttribute(NSAttributedString.Key.font, value: roundedFont, range: range)
                }
            }
            
            // Set Pasteboard Items
            let pasteboard = UIPasteboard.general
            var items: [String: Any] = [
                UTType.plainText.identifier: nsAttributedString.string
            ]
            
            // Add RTF if possible
            if let rtfData = try? nsAttributedString.data(from: fullRange, documentAttributes: [NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.rtf]) {
                items[UTType.rtf.identifier] = rtfData
            }
            
            pasteboard.items = [items]
            
            // Provide Haptic Feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
        } catch {
            print("Error parsing markdown for clipboard: \(error)")
            UIPasteboard.general.string = markdown
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }
}
