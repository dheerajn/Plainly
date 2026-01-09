import SwiftUI
import Textual

enum ExplanationMode: String, CaseIterable, Identifiable {
    case onDevice = "On-Device"
    case gemini = "Cloud"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .onDevice: return "iphone.gen2"
        case .gemini: return "cloud.fill"
        }
    }
}

struct ExplanationView: View {
    enum PresentationContext {
        case modal  // Share Extension / Modal sheet
        case nested // In-app unfolded view
    }
    
    let input: ShareInput?
    let context: PresentationContext
    var onClose: () -> Void
    
    @StateObject private var viewModel: ExplanationViewModel
    
    init(input: ShareInput? = nil, historyItem: HistoryItem? = nil, context: PresentationContext = .modal, onClose: @escaping () -> Void) {
        self.input = input
        self.context = context
        self.onClose = onClose
        _viewModel = StateObject(wrappedValue: ExplanationViewModel(input: input, historyItem: historyItem))
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 0) {
                // Header - Only for Modal (Share Extension)
                if context == .modal {
                    ModalHeader(onClose: onClose, onRefresh: { viewModel.refresh(input: input) }, viewModel: viewModel)
                }
                
                // Mode Selector
                if context == .modal || viewModel.shouldShowModePicker(for: input) {
                    ModeSelector(viewModel: viewModel, input: input, context: context)
                }
                
                // Main Content
                ExplanationMainContent(input: input, viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
                    .cornerRadius(AppLayout.cornerRadius, corners: [.topLeft, .topRight])
                    .shadow(color: .primary.opacity(0.04), radius: 15, y: -5)
            }
        }
        .task {
            if viewModel.explanation == nil {
                await viewModel.processInput(input)
            }
        }
        .navigationTitle("Explanation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if context == .nested && !viewModel.isFromHistory {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.refresh(input: input) }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }
}

// MARK: - Subviews

struct ModalHeader: View {
    let onClose: () -> Void
    let onRefresh: () -> Void
    @ObservedObject var viewModel: ExplanationViewModel
    
    var body: some View {
        HStack(alignment: .center) {
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44, height: 44)
            
            Spacer()
            
            if !viewModel.isFromHistory {
                Capsule()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 40, height: 5)
                    .padding(.vertical, 8)
            }
            
            Spacer()
            
            if !viewModel.isFromHistory {
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .bold))
                        .padding(8)
                        .background(Circle().fill(.secondary.opacity(0.1)))
                }
                .disabled(viewModel.isLoading)
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(.ultraThinMaterial.opacity(0.5))
    }
}

struct ModeSelector: View {
    @ObservedObject var viewModel: ExplanationViewModel
    let input: ShareInput?
    let context: ExplanationView.PresentationContext
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                if viewModel.shouldShowModePicker(for: input) {
                    Picker("Mode", selection: $viewModel.selectedMode) {
                        ForEach(ExplanationMode.allCases) { mode in
                            Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.selectedMode) { _, _ in
                        Task { await viewModel.processInput(input) }
                    }
                }
                
                if context == .modal && !viewModel.isFromHistory && !viewModel.shouldShowModePicker(for: input) {
                    Spacer()
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            if viewModel.shouldShowModePicker(for: input) {
                Text(viewModel.selectedMode == .onDevice ? "🔒 Private On-Device Processing" : "☁️ Secured Cloud Processing")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }
        }
    }
}

struct ExplanationMainContent: View {
    let input: ShareInput?
    @ObservedObject var viewModel: ExplanationViewModel
    
    var body: some View {
        ZStack {
            if let error = viewModel.errorMessage {
                ErrorView(error: error) {
                    viewModel.retry(input: input)
                }
            } else if viewModel.isLoading {
                LoadingView(text: viewModel.loadingText)
            } else if let result = viewModel.explanation {
                ExplanationDetailView(viewModel: viewModel, result: result)
            } else {
                ContentUnavailableView("Ready to Explain", systemImage: "sparkles", description: Text("Select a mode or input content."))
            }
        }
    }
}

struct ErrorView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(error)
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(.secondary)
            Button("Retry") { onRetry() }
                .buttonStyle(.bordered)
        }
        .padding()
    }
}

struct LoadingView: View {
    let text: String
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

struct ExplanationDetailView: View {
    @ObservedObject var viewModel: ExplanationViewModel
    let result: ExplanationResult
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let text = viewModel.displayInput, 
                   text != "Image File Upload", 
                   text != "Video File Upload" {
                    InputReferenceSection(title: "YOUR REQUEST", content: text)
                }
                
                if let imageData = viewModel.displayImageData, let uiImage = UIImage(data: imageData) {
                    ImageReferenceSection(title: "REFERENCE IMAGE", uiImage: uiImage)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("EXPLANATION")
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                        .tracking(1)
                    
                    StructuredText(markdown: result.markdown)
                }
            }
            .padding()
        }
    }
}

struct InputReferenceSection: View {
    let title: String
    let content: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption2.bold())
                .foregroundColor(.secondary)
                .tracking(1)
            
            Text(content)
                .font(.system(.body, design: .rounded))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
        }
    }
}

struct ImageReferenceSection: View {
    let title: String
    let uiImage: UIImage
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption2.bold())
                .foregroundColor(.secondary)
                .tracking(1)
            
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5)
        }
    }
}

// Helper for corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
