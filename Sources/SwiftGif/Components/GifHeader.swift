/// The header section of a Graphics Interchange Format stream.
/// See http://www.w3.org/Graphics/GIF/spec-gif89a.txt section 17.
///
/// The Header identifies the GIF Data Stream in context. The Signature
/// field marks the beginning of the Data Stream, and the Version field
/// identifies the set of capabilities required of a decoder to fully
/// process the Data Stream.
/// This block is REQUIRED; exactly one Header must be present per Data
/// Stream.
public struct GifHeader {
    /// Gets the signature of the GIF file. Always `"GIF"` for valid GIF files.
    public var signature: String
    /// Gets the GIF file version signature.
    public var gifVersion: String

    init(inputStream: ByteReaderStream) throws {
        if inputStream.remainingBytes < 6 {
            throw GifError.dataCorrupted("Header too small")
        }

        signature = try inputStream.readAscii(length: 3)
        if signature != "GIF" {
            throw GifError.dataCorrupted("Expected GIF signature bytes, found '\(signature)'")
        }

        gifVersion = try inputStream.readAscii(length: 3)
    }
}
