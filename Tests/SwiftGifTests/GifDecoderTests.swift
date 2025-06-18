import Foundation
import Testing
@testable import SwiftGif

struct GifDecoderTests {
    @Test
    func loadTestImages() throws {
        let folder = testImagePath
        let contents = try FileManager.default.contentsOfDirectory(atPath: folder)

        for entry in contents where entry.hasSuffix(".gif") {
            let data = try Data(contentsOf: URL(fileURLWithPath: (folder as NSString).appendingPathComponent(entry)))

            _ = try GifDecoder(data: data)
        }
    }
}
