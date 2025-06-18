/// An application extension which controls the number of times an animation
/// should be displayed.
///
/// See http://www.let.rug.nl/~kleiweg/gif/netscape.html for format
public class NetscapeExtension: ApplicationExtension {
    /// Number of times to repeat the frames of the animation. 0 to repeat indefinitely,
    /// -1 to not repeat.
    private(set) var loopCount: Int = 0

    override init(inputStream: ByteReaderStream) throws {
        try super.init(inputStream: inputStream)

        if applicationIdentifier != "NETSCAPE" {
            throw GifError.incorrectExtension("Expected NETSCAPE application identifier.")
        }
        if applicationAuthenticationCode != "2.0" {
            throw GifError.incorrectExtension("Expected '2.0' application authentication code in NETSCAPE application extension.")
        }

        for block in applicationData {
            if block.blockSize == 0 {
                break
            }

            // The first byte in a netscape application extension data block should
            // be 1. Ignore if anything else.
            let reader = block.byteReaderStream()
            if try block.blockSize > 2 && reader.readByte() == 1 {
                loopCount = Int.init(try reader.readShort())
            }
        }
    }
}
