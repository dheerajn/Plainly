import SwiftUI
import PhotosUI

struct HomeInputView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            HStack(spacing: AppLayout.standardSpacing) {
                // Media Picker
                PhotosPicker(selection: $viewModel.selectedItem, matching: .any(of: [.videos, .images])) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: AppLayout.iconButtonSize, height: AppLayout.iconButtonSize)
                        .background(Circle().fill(Color.primary.opacity(0.05)))
                }
                .onChange(of: viewModel.selectedItem) { _, newItem in
                    viewModel.handleMediaSelection(newItem)
                }
                
                // TextField Bar
                HStack {
                    TextField("Ask me to explain anything...", text: $viewModel.inputText, axis: .vertical)
                        .lineLimit(1...5)
                        .font(.body)
                        .padding(.horizontal, AppLayout.inputFieldHorizontalPadding)
                        .padding(.vertical, AppLayout.inputFieldVerticalPadding)
                    
                    if !viewModel.inputText.isEmpty {
                        Button(action: {
                            hideKeyboard()
                            viewModel.startExplanation()
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Color.primary)
                        }
                        .padding(.trailing, 6)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .background(Capsule().fill(Color.primary.opacity(0.05)))
                .background(Capsule().stroke(Color.primary.opacity(0.1), lineWidth: 0.5))
            }
            .padding(.horizontal, AppLayout.inputFieldHorizontalPadding)
            .padding(.vertical, AppLayout.inputFieldVerticalPadding)
            .background(.ultraThinMaterial)
            .clipShape(Capsule(style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            .padding(.horizontal)
            .padding(.bottom, AppLayout.bottomPadding)
        }
    }
}
