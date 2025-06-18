struct PackedFields {
    var bits: [Bool] = []

    init<Integer: BinaryInteger>(data: Integer) {
        for i in 0..<8 {
            let bitShift = 7 - i
            let bitValue = (data >> bitShift) & 1
            let bit = bitValue == 1

            bits.append(bit)
        }
    }

    func getBit(at index: Int) -> Bool {
        return bits[index]
    }

    func getBits(index: Int, length: Int) -> Int {
        var result = 0
        var bitShift = length - 1

        for i in index..<(index + length) {
            let bitValue = (bits[i] ? 1 : 0) << bitShift
            result += bitValue
            bitShift -= 1
        }

        return result
    }
}
