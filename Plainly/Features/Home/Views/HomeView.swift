import SwiftUI
import PhotosUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    // Onboarding State
    @AppStorage("hasShownOnboarding") var hasShownOnboarding: Bool = false
    @State private var showOnboardingSheet = false
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Background
                AppBackground()
                
                // 2. Main Content
                VStack(spacing: AppLayout.padding) {
                    Spacer()
                    
                    // Title Group
                    VStack(spacing: AppLayout.smallSpacing) {
                        if let appIconName = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
                           let primaryIcon = appIconName["CFBundlePrimaryIcon"] as? [String: Any],
                           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
                           let iconFileName = iconFiles.last,
                           let appIcon = UIImage(named: iconFileName) {
                            Image(uiImage: appIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .padding(.bottom, AppLayout.smallSpacing)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 60))
                                .foregroundStyle(.primary)
                                .padding(.bottom, AppLayout.smallSpacing)
                        }
                        
                        Text("Plainly")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .tracking(1)

                        Text("Instant clarity from any app, private by design.")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Suggestions
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppLayout.standardSpacing) {
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
                    Color.clear.frame(height: AppLayout.inputBarHeight)
                }
                .padding()
                
                // 3. Floating Bottom Bar
                HomeInputView(viewModel: viewModel)
            }
            .onTapGesture {
                hideKeyboard()
            }
            .alert(viewModel.permissionAlertTitle, isPresented: $viewModel.showPermissionAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text(viewModel.permissionAlertMessage)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "person.circle")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: HistoryView()) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
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
        .onChange(of: hasShownOnboarding) { _, newValue in
            if !newValue {
                showOnboardingSheet = true
            }
        }
        .sheet(isPresented: $showOnboardingSheet) {
            OnboardingView()
        }
    }
}
