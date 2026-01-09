import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasShownOnboarding") var hasShown: Bool = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        TabView {
            // Slide 1: Welcome
            OnboardingSlide(
                image: "sparkles",
                title: "Clarity, Instant & Integrated",
                description: "Plainly lives where you are. Get instant summaries from any app using the share sheet—no more copying and switching apps."
            )
            
            // Slide 2: Modes
            OnboardingSlide(
                image: "lock.shield",
                title: "Unmatched Privacy",
                description: "We believe your data is yours. Choose 'On-Device' for 100% private processing that never leaves your phone."
            )
            
            // Slide 3: Get Started
            VStack {
                OnboardingSlide(
                    image: "hand.tap",
                    title: "Ready?",
                    description: "Share text, links, videos, images, documents, or code from any app to Plainly to get instant summaries."
                )
                
                Button(action: {
                    hasShown = true
                    dismiss()
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(.background)
                        .padding(.horizontal, 40)
                        .padding(.vertical, AppLayout.inputFieldHorizontalPadding)
                        .background(Color.primary)
                        .cornerRadius(30)
                        .shadow(radius: 5)
                }
                .padding(.bottom, 50)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .appBackground()
    }
}

struct OnboardingSlide: View {
    let image: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: AppLayout.bottomPadding) {
            Image(systemName: image)
                .font(.system(size: 80))
                .foregroundStyle(.primary)
                .padding()
                .background(Color.primary.opacity(0.05))
                .clipShape(Circle())
            
            Text(title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
        }
        .padding()
    }
}
