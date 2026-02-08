import Foundation
import XCTest
@testable import AliangIOS

final class ComposerValidatorTests: XCTestCase {
    private let validator = ComposerValidator()

    func testRejectMixedImageAndVideo() {
        let draft = ComposerPostDraft(title: "Title", content: "Content")
        let media: [ComposerMediaDraft] = [
            .init(fileName: "1.jpg", data: Data(repeating: 1, count: 128), mediaType: .image),
            .init(fileName: "1.mp4", data: Data(repeating: 2, count: 128), mediaType: .video),
        ]

        let errors = validator.validate(draft: draft, media: media)
        XCTAssertTrue(errors.contains(.mixedMediaTypes))
    }

    func testRejectMoreThanNineImages() {
        let draft = ComposerPostDraft(title: "Title", content: "Content")
        let media = (1 ... 10).map { index in
            ComposerMediaDraft(
                fileName: "\(index).jpg",
                data: Data(repeating: 1, count: 1024),
                mediaType: .image
            )
        }

        let errors = validator.validate(draft: draft, media: media)
        XCTAssertTrue(errors.contains(.tooManyImages(maxAllowed: 9)))
    }

    func testRejectImageLargerThan10MB() {
        let draft = ComposerPostDraft(title: "Title", content: "Content")
        let oversized = Data(repeating: 7, count: ComposerValidator.maxImageBytes + 1)
        let media = [ComposerMediaDraft(fileName: "big.jpg", data: oversized, mediaType: .image)]

        let errors = validator.validate(draft: draft, media: media)
        XCTAssertTrue(errors.contains(.imageTooLarge(fileName: "big.jpg", maxMB: 10)))
    }
}
