import Foundation
import XCTest
@testable import AliangIOS

final class PostTimestampFormatterTests: XCTestCase {
    func testRelativeTextUsesJustNowWithinOneMinuteChineseLocale() {
        let now = Date()
        let target = now.addingTimeInterval(-30)

        let text = PostTimestampFormatter.relativeText(
            for: target,
            relativeTo: now,
            locale: Locale(identifier: "zh_CN")
        )

        XCTAssertEqual(text, "刚刚")
    }

    func testRelativeTextUsesJustNowWithinOneMinuteEnglishLocale() {
        let now = Date()
        let target = now.addingTimeInterval(20)

        let text = PostTimestampFormatter.relativeText(
            for: target,
            relativeTo: now,
            locale: Locale(identifier: "en_US")
        )

        XCTAssertEqual(text, "just now")
    }

    func testRelativeTextFallsBackToMinuteOrAboveOutsideOneMinute() {
        let now = Date()
        let target = now.addingTimeInterval(-120)

        let text = PostTimestampFormatter.relativeText(
            for: target,
            relativeTo: now,
            locale: Locale(identifier: "zh_CN")
        )

        XCTAssertFalse(text.contains("秒"))
    }
}
