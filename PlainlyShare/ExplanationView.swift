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
                    .foregroundStyle(.white)
            }
            .frame(width: AppLayout.iconButtonSize, height: AppLayout.iconButtonSize)
            
            Spacer()
            
            if !viewModel.isFromHistory {
                Capsule()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 40, height: 5)
                    .padding(.vertical, AppLayout.smallSpacing)
            }
            
            Spacer()
            
            if !viewModel.isFromHistory {
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .bold))
                        .padding(AppLayout.smallSpacing)
                        .background(Circle().fill(.secondary.opacity(0.1)))
                }
                .disabled(viewModel.isLoading)
            } else {
                Color.clear.frame(width: AppLayout.iconButtonSize, height: AppLayout.iconButtonSize)
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
        VStack(spacing: AppLayout.smallSpacing) {
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
            .padding(.vertical, AppLayout.smallSpacing)
            
            if viewModel.shouldShowModePicker(for: input) {
                Text(viewModel.selectedMode == .onDevice ? "🔒 Private On-Device Processing" : "☁️ Secured Cloud Processing")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, AppLayout.smallSpacing)
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
    @State private var showingCopied = false
    
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
                    HStack {
                        Text("EXPLANATION")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                            .tracking(1)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.copyToClipboard(markdown: result.markdown)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showingCopied = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showingCopied = false
                                }
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: showingCopied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 10, weight: .bold))
                                Text(showingCopied ? "COPIED" : "COPY")
                                    .font(.caption2.bold())
                            }
                            .foregroundStyle(showingCopied ? .green : .primary.opacity(0.7))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background {
                                Capsule()
                                    .fill(Color.primary.opacity(0.05))
                                    .overlay {
                                        Capsule()
                                            .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                                    }
                            }
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(showingCopied ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showingCopied)
                    }
                    
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
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .tracking(1)
            
            Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { isExpanded.toggle() } }) {
                HStack(spacing: 8) {
                    if !isExpanded {
                        Text(content)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .transition(.opacity)
                    } else {
                        Text("Hide original request")
                            .font(.caption)
                            .foregroundColor(.primary.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(AppLayout.smallCornerRadius)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                Text(content)
                    .font(.system(.body, design: .rounded))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(AppLayout.smallCornerRadius)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
            }
        }
    }
}

struct ImageReferenceSection: View {
    let title: String
    let uiImage: UIImage
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .tracking(1)
            
            Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { isExpanded.toggle() } }) {
                HStack(spacing: 8) {
                    if !isExpanded {
                        HStack(spacing: 4) {
                            Image(systemName: "photo")
                                .font(.caption2)
                            Text("Image Attached")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                    } else {
                        Text("Hide image")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(AppLayout.smallCornerRadius)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(AppLayout.smallCornerRadius)
                    .shadow(color: .black.opacity(0.1), radius: 5)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                    ))
            }
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
