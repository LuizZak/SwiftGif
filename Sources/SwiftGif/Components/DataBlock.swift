import Foundation

/// A data sub-block to form part of a Graphics Interchange Format data
/// stream.
/// See http://www.w3.org/Graphics/GIF/spec-gif89a.txt section 15.
///
/// Data Sub-blocks are units containing data. They do not have a label,
/// these blocks are processed in the context of control blocks, wherever
/// data blocks are specified in the format. The first byte of the Data
/// sub-block indicates the number of data bytes to follow. A data sub-block
/// may contain from 0 to 255 data bytes. The size of the block does not
/// account for the size byte itself, therefore, the empty sub-block is one
/// whose size field contains 0x00.
public struct DataBlock {
    public var blockSize: Int
    public var data: Data

    public var isTooShort: Bool {
        blockSize > data.count
    }
    public var actualBlockSize: Int {
        data.count
    }
    public subscript(index: Int) -> UInt8 {
        data[index]
    }

    init(inputStream: ByteReaderStream) throws {
        blockSize = Int(try inputStream.readByte())
        data = try inputStream.readData(length: blockSize)
    }

    /// Initializes an empty data block.
    init() {
        blockSize = 0
        data = Data()
    }

    /// Returns a `ByteReaderStream` for the underlying data contained within this
    /// block.
    func byteReaderStream() -> ByteReaderStream {
        .init(data: data)
    }

    static func skipStream(inputStream: ByteReaderStream) -> Int {
        if inputStream.isEof {
            return 0
        }

        do {
            let blockSize = Int(try inputStream.readByte())
            try inputStream.advance(by: blockSize)
            return blockSize
        } catch {
            return 0
        }
    }

    static func skipBlocks(inputStream: ByteReaderStream) {
        while skipStream(inputStream: inputStream) > 0 {

        }
    }
}
