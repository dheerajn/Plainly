import UIKit
import Social
import SwiftUI
import UniformTypeIdentifiers


@objc(ShareViewController)
class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Extract text/url from the extension context
        extractProcessingInput { [weak self] input in
            guard let self = self else { return }
            
            // Host the SwiftUI view
            let rootView = ExplanationView(input: input, context: .modal, onClose: {
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            })
            
            let hostingController = UIHostingController(rootView: rootView)
            self.addChild(hostingController)
            self.view.addSubview(hostingController.view)
            
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
            ])
            
            hostingController.didMove(toParent: self)
        }
    }

    private func extractProcessingInput(completion: @escaping (ShareInput?) -> Void) {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            completion(nil)
            return
        }

        // Search for providers
        for item in extensionItems {
            if let attachments = item.attachments {
                for provider in attachments {
                    // Check for PDF
                    if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                        provider.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { (item, error) in
                            if let url = item as? URL, let data = try? Data(contentsOf: url) {
                                DispatchQueue.main.async { completion(.document(data, .pdf, fileName: url.lastPathComponent)) }
                                return
                            }
                        }
                    }
                    // Check for Source Code
                    else if provider.hasItemConformingToTypeIdentifier(UTType.sourceCode.identifier) {
                        provider.loadItem(forTypeIdentifier: UTType.sourceCode.identifier, options: nil) { (item, error) in
                            if let url = item as? URL, let code = try? String(contentsOf: url) {
                                DispatchQueue.main.async { completion(.code(code, .sourceCode, fileName: url.lastPathComponent)) }
                                return
                            }
                        }
                    }
                    // Check for Video File (Movie)
                    else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                        provider.loadItem(forTypeIdentifier: UTType.movie.identifier, options: nil) { (item, error) in
                            // Item might be a URL to a file or Data
                            if let url = item as? URL, let data = try? Data(contentsOf: url) {
                                DispatchQueue.main.async { completion(.videoData(data)) }
                                return
                            } else if let data = item as? Data {
                                DispatchQueue.main.async { completion(.videoData(data)) }
                                return
                            }
                        }
                    }
                    // Check for Image
                    else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                         provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { (item, error) in
                             if let url = item as? URL, let data = try? Data(contentsOf: url) {
                                 DispatchQueue.main.async { completion(.imageData(data)) }
                                 return
                             } else if let image = item as? UIImage, let data = image.jpegData(compressionQuality: 0.8) {
                                  DispatchQueue.main.async { completion(.imageData(data)) }
                                  return
                             } else if let data = item as? Data {
                                 DispatchQueue.main.async { completion(.imageData(data)) }
                                 return
                             }
                         }
                    }
                    // Check for URL (Web Link) - Moved lower to avoid catching file URLs
                    else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { (item, error) in
                            if let url = item as? URL {
                                DispatchQueue.main.async { completion(.url(url)) }
                                return
                            }
                        }
                    } 
                    // Check for Plain Text Files
                    else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (item, error) in
                            if let url = item as? URL, let text = try? String(contentsOf: url) {
                                DispatchQueue.main.async { completion(.document(text.data(using: .utf8) ?? Data(), .plainText, fileName: url.lastPathComponent)) }
                                return
                            } else if let text = item as? String {
                                DispatchQueue.main.async { completion(.text(text)) }
                                return
                            }
                        }
                    }
                    // Check for Text
                    else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { (item, error) in
                            if let text = item as? String {
                                DispatchQueue.main.async {
                                    completion(.text(text))
                                }
                                return
                            }
                        }
                    }
                }
            }
        }
        
        // Fallback or exit if necessary
    }
}
