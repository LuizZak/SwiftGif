/// The Graphic Control Extension contains parameters used when processing
/// a graphic rendering block. The scope of this extension is the first
/// graphic rendering block to follow. The extension contains only one
/// data sub-block.
/// This block is OPTIONAL; at most one Graphic Control Extension may
/// precede a graphic rendering block. This is the only limit to the number
/// of Graphic Control Extensions that may be contained in a Data Stream.
public struct GraphicControlExtension {
    /// A default Graphic Control Extension, to be used when one was not found
    /// while decoding frames.
    nonisolated(unsafe)
    public static let defaultGce: GraphicControlExtension = GraphicControlExtension(
        blockSize: 4,
        disposalMethod: .notSpecified,
        expectsUserInput: false,
        hasTransparentColor: false,
        delayTime: 100,
        transparentColorIndex: 0
    )

    /// Number of bytes in the block, after the Block Size field and up to
    /// but not including the Block Terminator.
    /// This field contains the fixed value 4.
    public var blockSize: Int

    /// Indicates the way in which the graphic is to be treated after being displayed.
    public var disposalMethod: DisposalMethod

    /// Indicates whether or not user input is expected before continuing.
    /// If the flag is set, processing will continue when user input is
    /// entered.
    /// The nature of the User input is determined by the application
    /// (Carriage Return, Mouse Button Click, etc.).
    ///
    /// Values :    0 -   User input is not expected.
    ///             1 -   User input is expected.
    ///
    /// When a Delay Time is used and the User Input Flag is set,
    /// processing will continue when user input is received or when the
    /// delay time expires, whichever occurs first.
    public var expectsUserInput: Bool

    /// Indicates whether a transparency index is given in the Transparent Index field.
    public var hasTransparentColor: Bool

    /// If not 0, this field specifies the number of hundredths (1/100)
    /// of a second to wait before continuing with the processing of the
    /// Data Stream.
    /// The clock starts ticking immediately after the graphic is rendered.
    /// This field may be used in conjunction with the User Input Flag field.
    public var delayTime: Int

    /// The Transparency Index is such that when encountered, the
    /// corresponding pixel of the display device is not modified and
    /// processing goes on to the next pixel.
    /// The index is present if and only if the Transparency Flag is set
    /// to 1.
    public var transparentColorIndex: Int

    internal init(
        blockSize: Int,
        disposalMethod: GraphicControlExtension.DisposalMethod,
        expectsUserInput: Bool,
        hasTransparentColor: Bool,
        delayTime: Int,
        transparentColorIndex: Int
    ) {
        self.blockSize = blockSize
        self.disposalMethod = disposalMethod
        self.expectsUserInput = expectsUserInput
        self.hasTransparentColor = hasTransparentColor
        self.delayTime = delayTime
        self.transparentColorIndex = transparentColorIndex
    }

    init(inputStream: ByteReaderStream) throws {
        blockSize = try Int(inputStream.readByte())

        let packed = PackedFields(data: try inputStream.readByte())
        guard let disposalMethod = DisposalMethod(rawValue: packed.getBits(index: 3, length: 3)) else {
            throw GifError.dataCorrupted()
        }
        self.disposalMethod = disposalMethod
        expectsUserInput = packed.getBit(at: 6)
        hasTransparentColor = packed.getBit(at: 7)

        if self.disposalMethod == DisposalMethod.notSpecified {
            self.disposalMethod = DisposalMethod.doNotDispose // Elect to keep old image if discretionary
        }

        delayTime = Int(try inputStream.readShort())
        transparentColorIndex = Int(try inputStream.readByte())
        _=try inputStream.readByte() // Block terminator
    }

    /// Enumeration of disposal methods that can be found in a Graphic Control
    /// Extension.
    /// See http://www.w3.org/Graphics/GIF/spec-gif89a.txt section 23.
    public enum DisposalMethod: Int {
        case notSpecified = 0
        case doNotDispose = 1
        case restoreToBackgroundColor = 2
        case restoreToPrevious = 3
    }
}
