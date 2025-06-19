import Foundation

class ByteReaderStream {
    let data: Data
    var index: Int = 0

    var remainingBytes: Int {
        data.count - index
    }

    var isEof: Bool {
        index >= data.count
    }

    init(data: Data) {
        self.data = data
    }

    func advance(by length: Int) throws {
        index += length

        if index > data.count {
            throw StreamError.eof
        }
    }

    func readByte() throws -> UInt8 {
        let data = self.data[index]
        try advance(by: 1)
        return data
    }

    func readShort() throws -> UInt16 {
        let low = try readByte()
        let high = try readByte() << 8
        return UInt16(high) | UInt16(low)
    }

    func readData(length: Int) throws -> Data {
        if length == 0 {
            return Data()
        }

        let result = Data(data[index..<(index+length)])
        try advance(by: length)

        return result
    }

    func readAscii(length: Int) throws -> String {
        let data = try readData(length: length)

        return String(decoding: data, as: UTF8.self)
    }

    func makeBacktracker() -> Backtracker {
        Backtracker(inputStream: self, index: self.index)
    }

    /// Possible errors thrown during stream reading.
    enum StreamError: Error {
        /// Reached the end of the stream and attempted to read data.
        case eof
    }

    class Backtracker {
        private var _used: Bool = false
        private let _inputStream: ByteReaderStream
        private let _index: Int

        init(inputStream: ByteReaderStream, index: Int) {
            self._inputStream = inputStream
            self._index = index
        }

        func backtrack() {
            guard !_used else {
                return
            }

            _used = true
            _inputStream.index = _index
        }
    }
}
