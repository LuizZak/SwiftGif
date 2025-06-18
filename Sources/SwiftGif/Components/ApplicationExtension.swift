/// The Application Extension contains application-specific information;
/// it conforms with the extension block syntax, and its block label is
/// 0xFF.
///
/// See http://www.w3.org/Graphics/GIF/spec-gif89a.txt section 26.
class ApplicationExtension {
    var identificationBlock: DataBlock
    var applicationIdentifier: String
    var applicationAuthenticationCode: String
    var applicationData: [DataBlock] = []

    init(inputStream: ByteReaderStream) throws {
        identificationBlock = try DataBlock(inputStream: inputStream)

        if !inputStream.isEof {
            while !inputStream.isEof {
                let block = try DataBlock(inputStream: inputStream)
                applicationData.append(block)

                if block.blockSize == 0 {
                    break
                }
            }
        }

        if identificationBlock.blockSize != 11 {
            throw GifError.dataCorrupted()
        }

        let stream = identificationBlock.byteReaderStream()

        applicationIdentifier = try stream.readAscii(length: 8)
        applicationAuthenticationCode = try stream.readAscii(length: 3)
    }
}
