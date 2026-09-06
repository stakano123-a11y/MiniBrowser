import Foundation
import XCTest
@testable import MiniBrowser

final class IPAddressServiceTests: XCTestCase {
    func testIPv4Validation() {
        XCTAssertTrue(IPAddressService.isIPv4("106.72.10.15"))
        XCTAssertTrue(IPAddressService.isIPv4("0.0.0.0"))
        XCTAssertFalse(IPAddressService.isIPv4("256.1.1.1"))
        XCTAssertFalse(IPAddressService.isIPv4("2001:db8::1"))
        XCTAssertFalse(IPAddressService.isIPv4("01.2.3.4"))
    }

    func testRequestUsesProvidedUserAgent() {
        let userAgent = BrowserUserAgent.all[5].value
        let request = IPAddressService.makeRequest(
            endpoint: URL(string: "https://example.com/ip")!,
            timeout: 8,
            userAgent: userAgent
        )
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), userAgent)
        XCTAssertEqual(request.cachePolicy, .reloadIgnoringLocalAndRemoteCacheData)
    }
}
