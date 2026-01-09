import Foundation
import FirebaseAILogic
import FirebaseCore

actor GeminiService {
    private let modelName = "gemini-2.5-flash"
    
    init() { 
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    func explainText(text: String) async throws -> String {
        return try await generateResponse(prompt: Prompts.explanationPrompt(for: text))
    }
    
    func explainLink(url: URL) async throws -> String {
        return try await generateResponse(prompt: Prompts.linkExplanationPrompt(for: url.absoluteString))
    }
    
    func explainVideo(url: URL) async throws -> String {
        return try await analyzeYouTubeVideo(videoURL: url.absoluteString)
    }
    
    func explainVideoData(data: Data) async throws -> String {
        let prompt = Prompts.videoExplanationPrompt
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let model = ai.generativeModel(modelName: modelName)
        let videoPart = InlineDataPart(data: data, mimeType: "video/mp4")
        
        do {
            print("--- Gemini Request (Video Data) ---")
            print("Prompt: \(prompt)")
            let response = try await model.generateContent(prompt, videoPart)
            print("--- Gemini Response (Video Data) ---")
            print(response.text ?? "No text")
            print("-----------------------------------")
            return response.text ?? "No clear explanation could be generated."
        } catch {
            print("--- Gemini Error (Video Data) ---")
            print(error)
            print("-----------------------------------")
            throw error
        }
    }
    
    private func generateResponse(prompt: String) async throws -> String {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let model = ai.generativeModel(modelName: modelName)
        
        do {
            print("--- Gemini Request ---")
            print("Prompt: \(prompt)")
            let response = try await model.generateContent(prompt)
            print("--- Gemini Response ---")
            print(response.text ?? "No text")
            print("-----------------------")
            return response.text ?? "No clear explanation could be generated."
        } catch {
            print("--- Gemini Error ---")
            print(error)
            print("-----------------------")
            throw error
        }
    }
    
    func analyzeYouTubeVideo(videoURL: String) async throws -> String {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let model = ai.generativeModel(modelName: modelName)
        let videoPart = FileDataPart(uri: videoURL, mimeType: "video/mp4")
        let prompt = TextPart(Prompts.videoExplanationPrompt)
        
        do {
            print("--- Gemini Request (YouTube Video) ---")
            print("Video URL: \(videoURL)")
            print("Prompt: \(Prompts.videoExplanationPrompt)")
            let response = try await model.generateContent([videoPart, prompt])
            print("--- Gemini Response (YouTube Video) ---")
            print(response.text ?? "No text")
            print("--------------------------------------")
            return response.text ?? "No summary generated."
        } catch {
            print("--- Gemini Error (YouTube Video), falling back to simple prompt ---")
            return try await generateResponse(prompt: videoURL)
        }
    }
    
    func explainImage(data: Data) async throws -> String {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let model = ai.generativeModel(modelName: modelName)
        let imagePart = InlineDataPart(data: data, mimeType: "image/jpeg") 
        let prompt = Prompts.imageExplanationPrompt
        
        do {
            print("--- Gemini Request (Image) ---")
            print("Prompt: \(prompt)")
            let response = try await model.generateContent(prompt, imagePart)
            print("--- Gemini Response (Image) ---")
            print(response.text ?? "No text")
            print("------------------------------")
            return response.text ?? "No clear explanation could be generated."
        } catch {
            print("--- Gemini Error (Image) ---")
            print(error)
            print("------------------------------")
            throw error
        }
    }

    func explainDocument(data: Data, fileName: String, mimeType: String) async throws -> String {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let model = ai.generativeModel(modelName: modelName)
        
        // Gemini supports PDF as InlineData
        let docPart = InlineDataPart(data: data, mimeType: mimeType)
        let prompt = Prompts.documentExplanationPrompt(fileName: fileName)
        
        do {
            print("--- Gemini Request (Document) ---")
            print("FileName: \(fileName), MimeType: \(mimeType)")
            print("Prompt: \(prompt)")
            let response = try await model.generateContent(prompt, docPart)
            print("--- Gemini Response (Document) ---")
            print(response.text ?? "No text")
            print("---------------------------------")
            return response.text ?? "No clear explanation could be generated."
        } catch {
            print("--- Gemini Error (Document) ---")
            print(error)
            print("---------------------------------")
            // Fallback for non-PDF or large files: explain based on metadata if needed
            throw error
        }
    }

    func explainCode(code: String, fileName: String, language: String) async throws -> String {
        let prompt = Prompts.codeExplanationPrompt(fileName: fileName, language: language)
        let fullPrompt = "\(prompt)\n\nCODE:\n\(code)"
        return try await generateResponse(prompt: fullPrompt)
    }
}
