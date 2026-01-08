import Foundation

enum ShareInput {
    case text(String)
    case url(URL)
    case videoData(Data) // Small videos (<20MB)
    case imageData(Data)
}
