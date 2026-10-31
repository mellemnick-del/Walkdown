import Foundation
import SwiftData

/// A photo or scanned page attached to a control.
@Model
final class Evidence {
    @Attribute(.externalStorage)
    var imageData: Data = Data()
    var caption: String = ""
    var createdAt: Date = Date.now

    var control: ControlResult?

    init(imageData: Data, caption: String = "") {
        self.imageData = imageData
        self.caption = caption
    }
}
