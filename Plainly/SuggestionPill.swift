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
        HStack(spacing: AppLayout.extraSmallSpacing) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption.weight(.medium))
        .padding(.horizontal, AppLayout.standardSpacing)
        .padding(.vertical, AppLayout.smallSpacing)
        .background(AppColors.glassSurface)
        .clipShape(Capsule())
    }
}
