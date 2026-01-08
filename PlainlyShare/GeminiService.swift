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
    
    func explainVideo(url: URL) async throws -> String {
        return try await analyzeYouTubeVideo(videoURL: url.absoluteString)
    }
    
    func explainVideoData(data: Data) async throws -> String {
        let prompt = Prompts.videoExplanationPrompt
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let model = ai.generativeModel(modelName: modelName)
        let videoPart = InlineDataPart(data: data, mimeType: "video/mp4")
        
        do {
            let response = try await model.generateContent(prompt, videoPart)
            return response.text ?? "No clear explanation could be generated."
        } catch {
            throw error
        }
    }
    
    private func generateResponse(prompt: String) async throws -> String {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let model = ai.generativeModel(modelName: modelName)
        
        do {
            let response = try await model.generateContent(prompt)
            return response.text ?? "No clear explanation could be generated."
        } catch {
            throw error
        }
    }
    
    func analyzeYouTubeVideo(videoURL: String) async throws -> String {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let model = ai.generativeModel(modelName: modelName)
        let videoPart = FileDataPart(uri: videoURL, mimeType: "video/mp4")
        let prompt = TextPart(Prompts.videoExplanationPrompt)
        
        do {
            let response = try await model.generateContent([videoPart, prompt])
            return response.text ?? "No summary generated."
        } catch {
            return try await generateResponse(prompt: videoURL)
        }
    }
    
    func explainImage(data: Data) async throws -> String {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let model = ai.generativeModel(modelName: modelName)
        let imagePart = InlineDataPart(data: data, mimeType: "image/jpeg") 
        let prompt = Prompts.imageExplanationPrompt
        
        do {
            let response = try await model.generateContent(prompt, imagePart)
            return response.text ?? "No clear explanation could be generated."
        } catch {
            throw error
        }
    }
}
