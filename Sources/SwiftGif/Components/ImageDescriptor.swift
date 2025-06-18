/// Describes a single image within a Graphics Interchange Format data
/// stream.
/// See http://www.w3.org/Graphics/GIF/spec-gif89a.txt section 20.
///
/// Each image in the Data Stream is composed of an Image Descriptor, an
/// optional Local Color Table, and the image data.  Each image must fit
/// within the boundaries of the Logical Screen, as defined in the
/// Logical Screen Descriptor.
///
/// The Image Descriptor contains the parameters necessary to process a
/// table based image. The coordinates given in this block refer to
/// coordinates within the Logical Screen, and are given in pixels. This
/// block is a Graphic-Rendering Block, optionally preceded by one or more
/// Control blocks such as the Graphic Control Extension, and may be
/// optionally followed by a Local Color Table; the Image Descriptor is
/// always followed by the image data.
///
/// This block is REQUIRED for an image.  Exactly one Image Descriptor must
/// be present per image in the Data Stream.  An unlimited number of images
/// may be present per Data Stream.
///
/// The scope of this block is the Table-based Image Data Block that
/// follows it. This block may be modified by the Graphic Control Extension.
public struct ImageDescriptor {
    /// Gets the position, in pixels, of the top-left corner of the image,
    /// with respect to the top-left corner of the logical screen.
    /// Top-left corner of the logical screen is 0,0.
    public var position: Point

    /// Gets the size of the image in pixels.
    public var size: Size

    /// Gets a boolean value indicating the presence of a Local Color table
    /// immediately following this Image Descriptor.
    public var hasLocalColorTable: Bool

    /// Gets a boolean value indicating whether the image is interlaced. An
    /// image is interlaced in a four-pass interlace pattern; see Appendix E
    /// for details.
    public var isInterlaced: Bool

    /// Gets a boolean value indicating whether the Local Color Table is
    /// sorted.  If the flag is set, the Local Color Table is sorted, in
    /// order of decreasing importance. Typically, the order would be
    /// decreasing frequency, with most frequent color first. This assists
    /// a decoder, with fewer available colors, in choosing the best subset
    /// of colors; the decoder may use an initial segment of the table to
    /// render the graphic.
    public var isSorted: Bool

    /// If the Local Color Table Flag is set to 1, the value in this field
    /// is used to calculate the number of bytes contained in the Local
    /// Color Table. To determine that actual size of the color table,
    /// raise 2 to the value of the field + 1.
    /// This value should be 0 if there is no Local Color Table specified.
    public var localColorTableSizeBits: Int

    /// Gets the actual size of the local colour table.
    public var localColorTableSize: Int {
        2 << localColorTableSizeBits
    }

    init(inputStream: ByteReaderStream) throws {
        if inputStream.remainingBytes < 17 {
            throw GifError.dataCorrupted()
        }

        let left = try Int(inputStream.readShort()) // sub(image) position & size
        let top = try Int(inputStream.readShort())
        let width = try Int(inputStream.readShort())
        let height = try Int(inputStream.readShort())

        position = Point(x: left, y: top)
        size = Size(width: width, height: height)

        let packed = PackedFields(data: try inputStream.readByte())
        hasLocalColorTable = packed.getBit(at: 0)
        isInterlaced = packed.getBit(at: 1)
        isSorted = packed.getBit(at: 2)
        localColorTableSizeBits = packed.getBits(index: 5, length: 3)
    }
}
