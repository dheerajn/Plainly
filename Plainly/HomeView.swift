import SwiftUI
import PhotosUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    // Onboarding State
    @AppStorage("hasShownOnboarding") var hasShownOnboarding: Bool = false
    @State private var showOnboardingSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Background
                AppBackground()
                
                // 2. Main Content
                VStack(spacing: AppLayout.padding) {
                    Spacer()
                    
                    // Title Group
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundStyle(.primary)
                            .padding(.bottom, 8)
                        
                        Text("Plainly")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .tracking(1)

                        Text("Simplicity, delivered.")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Suggestions
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            SuggestionPill(icon: "doc.text", text: "Contracts")
                            SuggestionPill(icon: "link", text: "YouTube")
                            SuggestionPill(icon: "photo", text: "Screenshots")
                            SuggestionPill(icon: "doc.fill", text: "PDFs")
                            SuggestionPill(icon: "chevron.left.forwardslash.chevron.right", text: "Code")
                            SuggestionPill(icon: "video", text: "Videos")
                            SuggestionPill(icon: "newspaper", text: "Articles")
                        }
                        .padding(.horizontal)
                    }
                    .opacity(0.8)
                    
                    Spacer()
                    
                    // Invisible spacer to push content up when input bar is present
                    Color.clear.frame(height: 100)
                }
                .padding()
                
                // 3. Floating Bottom Bar
                HomeInputView(viewModel: viewModel)
            }
            .onTapGesture {
                hideKeyboard()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: HistoryView()) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $viewModel.isUnfolded) {
                if let historyItem = viewModel.selectedHistoryItem {
                    ExplanationView(historyItem: historyItem, context: .nested) {
                        viewModel.closeExplanation()
                    }
                } else if let input = viewModel.inputForExplanation {
                    ExplanationView(input: input, context: .nested) {
                        viewModel.closeExplanation()
                    }
                }
            }
        }
        .onAppear {
            if !hasShownOnboarding {
                showOnboardingSheet = true
            }
        }
        .sheet(isPresented: $showOnboardingSheet) {
            OnboardingView()
        }
    }
}
