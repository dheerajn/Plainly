import Foundation

struct Prompts {
    
    static func explanationPrompt(for text: String) -> String {
        return """
        Rewrite the following text to be extremely clear and easy to understand.
        
        Guidelines:
        - Use plain, simple English.
        - Use Markdown formatting.
        - Use bullet points or lists whenever they make the text easier to read.
        - Structuring: Adapt the structure to the input (e.g., use a summary, list of key points, or step-by-step explanation as appropriate).
        - Tone: Neutral, helpful, and objective.
        
        Input Text:
        "\(text)"
        
        Output Format (Markdown):
        # TL;DR
        (Summary)
                
        # Plain English
        (Explanation)
                
        # What This Means for You
        (Implications)
        """
    }
    
    static func linkExplanationPrompt(for url: String) -> String {
        return """
        Get the contents of the URL and explain this page
        
        URL: \(url)
        
        Output Format (Markdown):
        # TL;DR
        (Summary)
                
        # Plain English
        (Detailed explanation of the page content)
                
        # What This Means for You
        (Implications or actions for the reader)
        """
    }
    
    static var videoExplanationPrompt: String {
        """
        Analyze the following video link and provide a clear explanation.
        
        Instructions:
        1. Identification: Identify the video title and topic based on the URL context.
        2. Content Summary: If you have access to the transcript or general knowledge of this video, summarize the key points.
        3. Plain English: Explain the concepts simply.
        4. Practical Implications: Explain "What This Means for You".
        
        IMPORTANT: If you cannot access the specific video content, clearly state that you are explaining based on the context/metadata available.
        
        Output Format (Markdown):
        # TL;DR
        (Summary)
        
        # Plain English
        (Explanation)
        
        # What This Means for You
        (Implications)
        """
    }
    
    static var imageExplanationPrompt: String {
        """
        Analyze the image and provide a clear explanation.
        
        Instructions:
        1. Identification: Identify the key objects, text, or scene in the image.
        2. Content Summary: Explain what is happening or what the image represents.
        3. Plain English: Explain the concepts simply.
        4. Practical Implications: Explain "What This Means for You" if applicable.
        
        Output Format (Markdown):
        # TL;DR
        (Summary)
        
        # Plain English
        (Explanation)

        # Details
        (Detailed explanation)
        """
    }
}
