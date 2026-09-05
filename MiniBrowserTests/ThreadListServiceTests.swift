import Foundation
import XCTest
@testable import MiniBrowser

final class ThreadListServiceTests: XCTestCase {
    func testSortURLsMatchOfficialListModes() {
        XCTAssertEqual(ThreadListSort.momentum.url.absoluteString,
                       "https://img.2chan.net/b/futaba.php?mode=cat&sort=6")
        XCTAssertEqual(ThreadListSort.list.url.absoluteString,
                       "https://img.2chan.net/b/futaba.php?mode=cat")
        XCTAssertEqual(ThreadListSort.mostReplies.url.absoluteString,
                       "https://img.2chan.net/b/futaba.php?mode=cat&sort=3")
    }

    func testListParserPreservesOrderLimitsItemsAndUsesHTTPS() {
        let cells = (1...35).map { number in
            """
            <td><a href='res/\(1000 + number).htm' target='_blank'>
            <img src='http://img.2chan.net/b/cat/\(number)s.jpg'></a>
            <br><font size=2>\(number * 2)</font></td>
            """
        }.joined(separator: "\n")
        let html = "<html><table id='cattable'><tr>\(cells)</tr></table></html>"

        let items = ThreadListService.parseListHTML(
            html,
            baseURL: ThreadListSort.momentum.url,
            limit: 30
        )

        XCTAssertEqual(items.count, 30)
        XCTAssertEqual(items.first?.id, "1001")
        XCTAssertEqual(items.last?.id, "1030")
        XCTAssertEqual(items.first?.threadURL.absoluteString,
                       "https://img.2chan.net/b/res/1001.htm")
        XCTAssertEqual(items.first?.thumbnailURL.scheme, "https")
        XCTAssertEqual(items.first?.replyCount, 2)
    }

    func testListParserRejectsForeignURLs() {
        let html = """
        <table id="cattable"><tr><td>
        <a href="https://example.com/res/123.htm"><img src="https://example.com/a.jpg"></a>
        <font>5</font></td></tr></table>
        """
        XCTAssertTrue(ThreadListService.parseListHTML(
            html,
            baseURL: ThreadListSort.list.url
        ).isEmpty)
    }

    func testOpenerParserConvertsBreaksLinksAndEntities() {
        let html = """
        <html><div class="thre" data-res="123">
        metadata<a href="/b/src/a.jpg"><img src="a.jpg"></a>
        <blockquote>一行目<br><a href="/jump">リンク</a>&amp;&#12316;</blockquote>
        <table><blockquote>他ユーザー</blockquote></table></div></html>
        """
        XCTAssertEqual(ThreadListService.parseOpenerHTML(html), "一行目 リンク&〜")
    }

    func testOpenerParserReturnsPlaceholderForEmptyBody() {
        let html = #"<div class="thre"><blockquote></blockquote></div>"#
        XCTAssertEqual(ThreadListService.parseOpenerHTML(html), "本文なし")
    }

    func testOpenerParserRejectsIncompleteHTML() {
        let html = #"<div class="thre"><blockquote>途中"#
        XCTAssertNil(ThreadListService.parseOpenerHTML(html))
    }

    func testOpenerRequestUsesBoundedRange() {
        let url = URL(string: "https://img.2chan.net/b/res/123.htm")!
        let request = ThreadListService.makeOpenerRequest(for: url)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Range"), "bytes=0-32767")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-Encoding"), "identity")
        XCTAssertEqual(request.timeoutInterval, 15)
    }

    func testShiftJISDecoder() throws {
        let original = "対象ページ"
        let data = try XCTUnwrap(original.data(using: .shiftJIS))
        XCTAssertEqual(ThreadListService.decodeShiftJIS(data), original)
    }
}
