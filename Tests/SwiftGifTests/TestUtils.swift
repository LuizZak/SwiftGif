import Foundation

var testImagePath: String {
    let base: NSString = #filePath
    var active = base.deletingLastPathComponent
    active = active.appendingPathComponent("TestImages")
    return active
}
