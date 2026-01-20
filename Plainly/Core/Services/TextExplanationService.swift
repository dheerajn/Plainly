import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Models

struct ExplanationResult: Identifiable {
    let id = UUID()
    let markdown: String
}

// MARK: - Service

actor TextExplanationService {
    
    // Set to false to attempt using real device models (if available)
    private let forceMock: Bool = false
    
    func explain(text: String) async throws -> ExplanationResult {
        if text.isEmpty {
            throw ExplanationError.emptyInput
        }
        
        // 1. Check if forced to use mock
        if forceMock {
            return await mockExplanation(for: text)
        }
        
        // 2. Check system availability
        #if canImport(FoundationModels)
        let systemModel = SystemLanguageModel.default
        if systemModel.availability == .available {
             do {
                 return try await generateLiveExplanation(for: text)
             } catch {
                 return await mockExplanation(for: text)
             }
        } else {
             return await mockExplanation(for: text)
        }
        #else
        return await mockExplanation(for: text)
        #endif
    }
    
    // MARK: - Live Generation Logic
    
    #if canImport(FoundationModels)
    private func generateLiveExplanation(for text: String) async throws -> ExplanationResult {
        let session = LanguageModelSession()
        
        // Flexible prompt focusing on clarity and Markdown
        // Flexible prompt focusing on clarity and Markdown (Shared)
        let promptString = Prompts.explanationPrompt(for: text)
        
        let prompt = Prompt(promptString)
        let response = try await session.respond(to: prompt)
        
        return ExplanationResult(markdown: response.content)
    }
    #endif
    
    // MARK: - Mock Data
    
    private func mockExplanation(for text: String) async -> ExplanationResult {
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        let response = mockResponse(for: text)
        return ExplanationResult(markdown: response)
    }
    
    private func mockResponse(for text: String) -> String {
        return """
        # TL;DR
        Here is a simple summary of the text you provided.
        
        # Plain English
        - The text says: "\(text.prefix(50))..."
        - It means that we are testing the **HiddenLine** app interface.
        - This is a *mock* response generated because the on-device model was unavailable.
        
        # What This Means for You
        - You can verify the UI layout.
        - The Markdown rendering is working correctly.
        """
    }
}

enum ExplanationError: Error {
    case emptyInput
    case generationFailed
}
