import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

// Wrapper to make ShareInput Identifiable for sheet presentation
struct ExplanationWrapper: Identifiable {
    let id = UUID()
    let input: ShareInput
}

struct ContentView: View {
    @State private var inputText: String = ""
    @Namespace private var animation
    @State private var isUnfolded = false // Animation state
    
    // Data for Explanation
    @State private var inputForExplanation: ShareInput?
    
    // Video Picker State
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        ZStack {
            // Background is applied to the ZStack container itself
            
            // 2. Main Content
            if !isUnfolded {
                // --- HOME / INPUT STATE ---
                VStack(spacing: AppLayout.padding) {
                    
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundStyle(.primary)
                            .padding(.bottom, 8)
                        
                        Text("Plainly")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .tracking(1)
                        
                        Text("Simplicity, delivered.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    
                    // Glass Input Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What's on your mind?")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("Paste text or URL...", text: $inputText)
                            .padding()
                            .background(Color.white.opacity(0.5))
                            .cornerRadius(12)
                            .font(.body)
                        
                        HStack {
                            // Media Picker
                            PhotosPicker(selection: $selectedItem, matching: .any(of: [.videos, .images])) {
                                Label("Media", systemImage: "photo.on.rectangle")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.primary.opacity(0.1))
                                    .foregroundColor(.primary)
                                    .cornerRadius(20)
                            }
                            
                            Spacer()
                            
                            // Explain Button
                            Button(action: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    startExplanation()
                                }
                            }) {
                                HStack {
                                    Text("Explain")
                                    Image(systemName: "arrow.right")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    inputText.isEmpty ? Color.gray : Color.primary
                                )
                                .cornerRadius(30)
                                .shadow(color: .primary.opacity(0.2), radius: 10, x: 0, y: 5)
                            }
                            .disabled(inputText.isEmpty)
                            .matchedGeometryEffect(id: "explainButton", in: animation)
                        }
                    }
                    .padding(AppLayout.padding)
                    .glassCard()
                    .matchedGeometryEffect(id: "cardMain", in: animation)
                    
                    // Recent / Suggestions (Placeholder for cleaner UI look)
                    HStack(spacing: 12) {
                        SuggestionPill(icon: "doc.text", text: "Contracts")
                        SuggestionPill(icon: "link", text: "YouTube")
                        SuggestionPill(icon: "photo", text: "Screenshots")
                    }
                    .opacity(0.7)
                    
                    Spacer()
                    
                    // Footer / Privacy
                    Label("Private on-device processing available", systemImage: "lock.shield")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                }
                .padding()
                
            } else {
                // --- RESULT / UNFOLDED STATE ---
                VStack {
                    if let input = inputForExplanation {
                        ExplanationView(input: input) {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                isUnfolded = false
                                inputForExplanation = nil
                            }
                        }
                        .transition(.opacity)
                    }
                }
                // We use the same 'id' to create the morphing effect from the card
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.thinMaterial)
                .matchedGeometryEffect(id: "cardMain", in: animation)
                .ignoresSafeArea()
            }
        }
        .appBackground()
        // Media Picker Change Handler
        .onChange(of: selectedItem) { newItem in
            Task {
                guard let item = selectedItem else { return }
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        let types = item.supportedContentTypes
                        let input: ShareInput
                        if types.contains(where: { $0.conforms(to: .image) }) {
                            input = .imageData(data)
                        } else {
                            input = .videoData(data)
                        }
                        
                        // Trigger Animation
                        self.inputForExplanation = input
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            self.isUnfolded = true
                        }
                        self.selectedItem = nil
                    }
                }
            }
        }
    }
    
    private func startExplanation() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let input: ShareInput
        if let url = URL(string: trimmed), UIApplication.shared.canOpenURL(url) {
            input = .url(url)
        } else {
            input = .text(trimmed)
        }
        
        self.inputForExplanation = input
        self.isUnfolded = true
    }
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
