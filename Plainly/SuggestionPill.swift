import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

// Wrapper to make ShareInput Identifiable for sheet presentation
struct ExplanationWrapper: Identifiable {
    let id = UUID()
    let input: ShareInput
}

// Micro-component for suggested topics
struct SuggestionPill: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption.weight(.medium))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.3))
        .clipShape(Capsule())
    }
}
