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
                    
                    // Title Group
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundStyle(LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .padding(.bottom, 8)
                        
                        Text("Plainly")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .tracking(1)

                        Text("Simplicity, delivered.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Input Card Component
                    HomeInputView(viewModel: viewModel)
                    
                    // Suggestions
                    HStack(spacing: 12) {
                        SuggestionPill(icon: "doc.text", text: "Contracts")
                        SuggestionPill(icon: "link", text: "YouTube")
                        SuggestionPill(icon: "photo", text: "Screenshots")
                    }
                    .opacity(0.7)
                    
                    Spacer()
                    
                    // Footer
                    Label("Private on-device processing available", systemImage: "lock.shield")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                }
                .padding()
            }
            .onTapGesture {
                hideKeyboard()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: HistoryView()) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title3)
                            .foregroundColor(.indigo)
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
