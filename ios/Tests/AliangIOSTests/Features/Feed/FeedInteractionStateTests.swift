import Foundation
import XCTest

@testable import AliangIOS

final class FeedInteractionStateTests: XCTestCase {
    func testBuildInitialInteractionStateMapsPostCounts() {
        let post = FeedPost(
            id: 101,
            userID: 7,
            title: "TrackE",
            content: "interaction wiring",
            postType: "image",
            likeCount: 12,
            commentCount: 6,
            isLiked: true,
            createdAt: Date(),
            author: nil,
            media: []
        )

        let state = FeedView.buildInitialInteractionState(for: post)

        XCTAssertEqual(state.postID, 101)
        XCTAssertEqual(state.likeCount, 12)
        XCTAssertEqual(state.commentCount, 6)
        XCTAssertEqual(state.isLiked, true)
        XCTAssertEqual(state.isLikeUpdating, false)
    }

    func testBuildInitialInteractionStateHandlesZeroCounts() {
        let post = FeedPost(
            id: 102,
            userID: 9,
            title: "TrackE 2",
            content: "",
            postType: "text",
            likeCount: 0,
            commentCount: 0,
            isLiked: false,
            createdAt: Date(),
            author: nil,
            media: []
        )

        let state = FeedView.buildInitialInteractionState(for: post)

        XCTAssertEqual(state.likeCount, 0)
        XCTAssertEqual(state.commentCount, 0)
        XCTAssertEqual(state.isLiked, false)
    }
}
