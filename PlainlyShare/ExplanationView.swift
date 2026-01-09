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
                // Header (Draggable / Close)
                // Using a clearer layout for the header to avoid clipping
                HStack(alignment: .center) {
                    if context == .modal {
                        // Extension Close Button
                        Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 44, height: 44)
                        
                        Spacer()
                    } else {
                        // Empty spacer for balance or leading item
                        Spacer()
                    }
                    
                    Capsule()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(width: 40, height: 5)
                        .padding(.vertical, 8)
                    
                    Spacer()
                    
                    // Invisible spacer for balance if modal
                    if context == .modal {
                        Color.clear.frame(width: 44, height: 44)
                    } else {
                        // Refresh Button in header for nested view
                        Button(action: { viewModel.refresh(input: input) }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .semibold))
                                .padding(8)
                                .background(Circle().fill(.secondary.opacity(0.1)))
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .background(.ultraThinMaterial.opacity(0.5))
                
                // Mode Selector & Utilities
                if context == .modal || viewModel.shouldShowModePicker(for: input) {
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
                        
                        if context == .modal {
                            Spacer()
                            Button(action: { viewModel.refresh(input: input) }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .bold))
                                    .padding(8)
                                    .background(Circle().fill(.secondary.opacity(0.1)))
                            }
                            .disabled(viewModel.isLoading)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                if viewModel.shouldShowModePicker(for: input) {
                    Text(viewModel.selectedMode == .onDevice ? "🔒 Private On-Device Processing" : "☁️ Secured Cloud Processing")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)
                }
                
                // Main Content Card
                ZStack {
                    if let error = viewModel.errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text(error)
                                .multilineTextAlignment(.center)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Button("Retry") {
                                viewModel.retry(input: input)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    } else if viewModel.isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text(viewModel.loadingText)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    } else if let result = viewModel.explanation {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                
                                // Show original input if available (Hide if it's just a placeholder for media)
                                if let text = viewModel.displayInput, 
                                   text != "Image File Upload", 
                                   text != "Video File Upload" {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("YOUR REQUEST")
                                            .font(.caption2.bold())
                                            .foregroundColor(.secondary)
                                            .tracking(1)
                                        
                                        Text(text)
                                            .font(.system(.body, design: .rounded))
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color.secondary.opacity(0.05))
                                            .cornerRadius(12)
                                    }
                                }
                                
                                // Show original image if available
                                if let imageData = viewModel.displayImageData, let uiImage = UIImage(data: imageData) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("REFERENCE IMAGE")
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
                                
                                Divider()
                                
                                // RESULT SECTION
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
                    } else {
                        ContentUnavailableView("Ready to Explain", systemImage: "sparkles", description: Text("Select a mode or input content."))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .cornerRadius(AppLayout.cornerRadius, corners: [.topLeft, .topRight])
                .shadow(color: .primary.opacity(0.04), radius: 15, y: -5)
            }
        }
        .task {
            // Initial Process (Only if NOT restored from history)
            if viewModel.explanation == nil {
                await viewModel.processInput(input)
            }
        }
        .navigationTitle("Explanation")
        .navigationBarTitleDisplayMode(.inline)
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
