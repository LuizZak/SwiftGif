import Foundation

/// A decoder for GIF files.
public final class GifDecoder {
    /// Plaintext label - identifies the current block as a plain text extension.
    static let code_plaintext_label: UInt8 = 0x01

    /// Extension introducer - identifies the Start of an extension block.
    static let code_extension_introducer: UInt8 = 0x21

    /// Image separator - identifies the start of an Image Descriptor.
    static let code_image_separator: UInt8 = 0x2C

    /// Trailer - This is a single-field block indicating the end of the GIF data
    /// stream.
    static let code_trailer: UInt8 = 0x38

    /// Graphic control label - identifies the current block as a Graphic Control
    /// Extension.
    static let code_graphic_control_label: UInt8 = 0xF9

    // Comment label - identifies the current block as a comment extension.
    static let code_comment_label: UInt8 = 0xFE

    /// Application extension label - identifies the current block as a Application
    /// Extension.
    static let code_application_extension_label: UInt8 = 0xFF

    public var gifHeader: GifHeader
    public var lsd: LogicalScreenDescriptor
    var lastNoDisposalFrame: GifFrame?
    public var frameDelays: [Int] = []
    public var gct: ColorTable?
    public var netscapeExtension: NetscapeExtension?
    public var applicationExtensions: [ApplicationExtension] = []
    public var frames: [GifFrame] = []
    // Non-fatal errors raised during parsing.
    public var errors: [GifError] = []

    init(data: Data) throws {
        let reader = ByteReaderStream(data: data)

        gifHeader = try GifHeader(inputStream: reader)
        lsd = try LogicalScreenDescriptor(inputStream: reader)

        if lsd.hasGlobalColorTable {
            gct = try ColorTable(inputStream: reader, numberOfColors: lsd.globalColorTableSize)
        }

        try readContents(inputStream: reader)
    }

    func readContents(inputStream: ByteReaderStream) throws {
        var done = false
        var lastGce: GraphicControlExtension?

        while !done {
            if inputStream.isEof {
                errors.append(.unexpectedEnfOfFile)
                break
            }

            let code = try inputStream.readByte()

            switch code {
            case Self.code_image_separator:
                try addFrame(inputStream: inputStream, lastGce: lastGce)

            case Self.code_extension_introducer:
                switch try inputStream.readByte() {
                case Self.code_plaintext_label:
                    DataBlock.skipBlocks(inputStream: inputStream)

                case Self.code_graphic_control_label:
                    lastGce = try GraphicControlExtension(inputStream: inputStream)

                case Self.code_comment_label:
                    DataBlock.skipBlocks(inputStream: inputStream)

                case Self.code_application_extension_label:
                    let backtracker = inputStream.makeBacktracker()

                    do {
                        let ext = try NetscapeExtension(inputStream: inputStream)
                        netscapeExtension = ext
                        applicationExtensions.append(ext)
                    } catch {
                        backtracker.backtrack()
                        let ext = try ApplicationExtension(inputStream: inputStream)
                        applicationExtensions.append(ext)
                    }

                default:
                    DataBlock.skipBlocks(inputStream: inputStream)
                }

            case Self.code_trailer:
                done = true

            case 0x00:
                break

            default:
                errors.append(GifError.unknownBlockIdentifier(Int(code)))
            }
        }
    }

    func addFrame(inputStream: ByteReaderStream, lastGce: GraphicControlExtension?) throws {
        let previousFrame: GifFrame? = frames.last

        // Setup frame delay
        if let lastGce {
            frameDelays.append(lastGce.delayTime)
        }

        let frame = try GifFrame(
            inputStream: inputStream,
            logicalScreenDescriptor: lsd,
            globalColorTable: gct,
            graphicControlExtension: lastGce ?? .defaultGce,
            previousFrame: previousFrame,
            previousFrameBut1: lastNoDisposalFrame,
            index: frames.count
        )

        if let lastGce {
            if lastGce.disposalMethod == .doNotDispose || lastGce.disposalMethod == .notSpecified {
                lastNoDisposalFrame = frame
            }
        } else {
            lastNoDisposalFrame = frame
        }

        frames.append(frame)
    }
}
