import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("hasShownOnboarding") var hasShownOnboarding: Bool = false
    
    // Version info
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Your Privacy", systemImage: "lock.shield.fill")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("HiddenLine is designed to be private. Your data is never sold or shared for advertising. We process on-device whenever possible, but may use secure cloud processing when needed to provide the best results.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Link(destination: URL(string: "https://dheerajn.github.io/Plainly/privacy")!) {
                            HStack {
                                Text("Privacy Policy")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Privacy & Security")
                }
                
                Section {
                    Button(role: .destructive) {
                        clearHistory()
                    } label: {
                        Label("Clear All History", systemImage: "trash")
                    }
                } header: {
                    Text("Preferences")
                }
                
                Section {
                    Button {
                        rateApp()
                    } label: {
                        Label("Rate HiddenLine", systemImage: "star.fill")
                    }
                    
                    Button {
                        shareApp()
                    } label: {
                        Label("Share with Friends", systemImage: "square.and.arrow.up")
                    }
                    
                    Link(destination: URL(string: "https://x.com/dheerun1210")!) {
                        Label("Contact Support", systemImage: "x.square.fill")
                    }
                } header: {
                    Text("Feedback & Support")
                }
                
                Section {
                    Button {
                        hasShownOnboarding = false
                        dismiss()
                    } label: {
                        Label("Replay Onboarding", systemImage: "play.circle.fill")
                    }
                } footer: {
                    VStack(alignment: .center, spacing: 8) {
                        Text("HiddenLine")
                            .font(.headline)
                        Text(appVersion)
                            .font(.caption)
                        Text("Made with love for clarity.")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func clearHistory() {
        HistoryManager.shared.clearAll()
    }
    
    private func rateApp() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    private func shareApp() {
        let text = "Check out HiddenLine—the easiest way to get instant clarity from any app!"
        let url = URL(string: "https://plainly.app")!
        let activityVC = UIActivityViewController(activityItems: [text, url], applicationActivities: nil)
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    SettingsView()
}
