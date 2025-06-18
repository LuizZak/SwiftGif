// The Logical Screen Descriptor component of a Graphics Interchange Format
// stream.
// See http://www.w3.org/Graphics/GIF/spec-gif89a.txt section 18.
//
// The Logical Screen Descriptor contains the parameters necessary to
// define the area of the display device within which the images will be
// rendered. The coordinates in this block are given with respect to the
// top-left corner of the virtual screen; they do not necessarily refer to
// absolute coordinates on the display device.  This implies that they
// could refer to window coordinates in a window-based environment or
// printer coordinates when a printer is used.
// This block is REQUIRED; exactly one Logical Screen Descriptor must be
// present per Data Stream.
public struct LogicalScreenDescriptor {
    /// The width and height, in pixels, of the logical screen where the images
    /// will be rendered in the displaying device.
    public var screenSize: Size

    /// Gets a flag indicating the presence of a Global Color Table; if the
    /// flag is set, the Global Color Table will immediately follow the
    /// Logical Screen Descriptor. This flag also selects the interpretation
    /// of the Background Color Index; if the flag is set, the value of the
    /// Background Color Index field should be used as the table index of
    /// the background color.
    public var hasGlobalColorTable: Bool

    /// Gets the number of bits per primary color available to the original
    /// image, minus 1. This value represents the size of the entire palette
    /// from which the colors in the graphic were selected, not the number
    /// of colors actually used in the graphic.
    /// For example, if the value in this field is 3, then the palette of
    /// the original image had 4 bits per primary color available to create
    /// the image.  This value should be set to indicate the richness of
    /// the original palette, even if not every color from the whole
    /// palette is available on the source machine.
    public var colorResolution: Int

    /// Indicates whether the Global Color Table is sorted.
    /// If the flag is set, the Global Color Table is sorted, in order of
    /// decreasing importance. Typically, the order would be decreasing
    /// frequency, with most frequent color first. This assists a decoder,
    /// with fewer available colors, in choosing the best subset of colors;
    /// the decoder may use an initial segment of the table to render the
    /// graphic.
    public var gctIsSorted: Bool

    /// If the Global Color Table Flag is set to 1, the value in this field
    /// is used to calculate the number of bytes contained in the Global
    /// Color Table. To determine that actual size of the color table,
    /// raise 2 to [the value of the field + 1].
    /// Even if there is no Global Color Table specified, set this field
    /// according to the above formula so that decoders can choose the best
    /// graphics mode to display the stream in.
    public var gctSizeBits: Int

    /// Gets the number of colors in the global color table.
    public var globalColorTableSize: Int {
        2 << gctSizeBits
    }

    /// Gets the index into the Global Color Table for the Background Color.
    /// The Background Color is the color used for those pixels on the
    /// screen that are not covered by an image.
    /// If the Global Color Table Flag is set to (zero), this field should
    /// be zero and should be ignored.
    public var backgroundColorIndex: Int

    /// Gets the factor used to compute an approximation of the aspect ratio
    /// of the pixel in the original image.  If the value of the field is
    /// not 0, this approximation of the aspect ratio is computed based on
    /// the formula:
    ///
    /// Aspect Ratio = (Pixel Aspect Ratio + 15) / 64
    ///
    /// The Pixel Aspect Ratio is defined to be the quotient of the pixel's
    /// width over its height.  The value range in this field allows
    /// specification of the wid
    public var pixelAspectRatio: Int

    init(inputStream: ByteReaderStream) throws {
        if inputStream.remainingBytes < 7 {
            throw GifError.dataCorrupted()
        }

        let width = try Int(inputStream.readShort())
        let height = try Int(inputStream.readShort())

        screenSize = Size(width: width, height: height)

        let packed = PackedFields(data: try inputStream.readByte())
        hasGlobalColorTable = packed.getBit(at: 0)
        colorResolution = packed.getBits(index: 1, length: 3)
        gctIsSorted = packed.getBit(at: 4)
        gctSizeBits = packed.getBits(index: 5, length: 3)

        backgroundColorIndex = try Int(inputStream.readByte())
        pixelAspectRatio = try Int(inputStream.readByte())
    }
}
