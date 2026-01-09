import UniformTypeIdentifiers

enum ShareInput {
    case text(String)
    case url(URL)
    case videoData(Data) // Small videos (<20MB)
    case imageData(Data)
    case document(Data, UTType, fileName: String)
    case code(String, UTType, fileName: String)
}
