import SwiftUI
import PhotosUI

struct HomeInputView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's on your mind?")
                .font(.headline)
                .foregroundColor(.secondary)
            
            TextField("Paste text or URL...", text: $viewModel.inputText, axis: .vertical)
                .lineLimit(3...8) // Min 3 lines, Max 8 lines before scrolling
                .padding()
                .background(Color.white.opacity(0.6))
                .cornerRadius(16)
                .font(.body)
                .textInputAutocapitalization(.sentences)
                .frame(maxHeight: 200) // Explicit constraint to prevent layout breaking
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            HStack {
                // Media Picker
                PhotosPicker(selection: $viewModel.selectedItem, matching: .any(of: [.videos, .images])) {
                    Label("Media", systemImage: "photo.on.rectangle")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(20)
                }
                .onChange(of: viewModel.selectedItem) { newItem in
                    viewModel.handleMediaSelection(newItem)
                }
                
                Spacer()
                
                // Explain Button
                Button(action: {
                    hideKeyboard()
                    viewModel.startExplanation()
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
                        viewModel.inputText.isEmpty ? Color.gray : Color.indigo
                    )
                    .cornerRadius(30)
                    .shadow(color: .indigo.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .disabled(viewModel.inputText.isEmpty)
            }
        }
        .padding(AppLayout.padding)
        .glassCard()
    }
}
