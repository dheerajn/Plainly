import SwiftUI
import PhotosUI
import Combine

class HomeViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var isUnfolded = false
    @Published var inputForExplanation: ShareInput?
    @Published var selectedItem: PhotosPickerItem?
    @Published var isPickerPresented: Bool = false
    
    // Permission Alert State
    @Published var showPermissionAlert = false
    @Published var permissionAlertTitle = ""
    @Published var permissionAlertMessage = ""
    
    func requestPhotoPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self.isPickerPresented = true
                    } else {
                        self.showPermissionError()
                    }
                }
            }
        case .authorized, .limited:
            isPickerPresented = true
        case .denied, .restricted:
            showPermissionError()
        @unknown default:
            break
        }
    }
    
    // Auto-process media selection
    func handleMediaSelection(_ newItem: PhotosPickerItem?) {
        guard let item = newItem else { return }
        processMediaItem(item)
    }
    
    private func processMediaItem(_ item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    let types = item.supportedContentTypes
                    let input: ShareInput
                    if types.contains(where: { $0.conforms(to: .image) }) {
                        input = .imageData(data)
                    } else {
                        input = .videoData(data)
                    }
                    
                    self.inputForExplanation = input
                    self.isUnfolded = true
                    // Reset picker
                    self.selectedItem = nil
                }
            }
        }
    }
    
    private func showPermissionError() {
        DispatchQueue.main.async {
            self.permissionAlertTitle = "Photo Library Access Required"
            self.permissionAlertMessage = "Plainly needs permission to access your library to explain images and videos. Please enable access in System Settings."
            self.showPermissionAlert = true
            self.selectedItem = nil // Reset selection
        }
    }
    
    func startExplanation() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let input: ShareInput
        if let url = URL(string: trimmed), UIApplication.shared.canOpenURL(url) {
            input = .url(url)
        } else {
            input = .text(trimmed)
        }
        
        self.inputForExplanation = input
        self.isUnfolded = true
    }
    
    
    @Published var selectedHistoryItem: HistoryItem?
    
    func viewHistoryItem(_ item: HistoryItem) {
        self.selectedHistoryItem = item
        self.isUnfolded = true
    }
    
    func closeExplanation() {
        self.isUnfolded = false
        self.inputForExplanation = nil
        self.selectedHistoryItem = nil
    }
}
