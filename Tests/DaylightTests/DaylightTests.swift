import Foundation
import XCTest

@testable import Daylight

class DaylightTests: XCTestCase {

    func testJulianGMT() {
        let calendar = Calendar.gmt
        let components = DateComponents(calendar: calendar, year: 2000, month: 1, day: 1, hour: 0, minute: 0, second: 0, nanosecond: 0)
        let date = calendar.date(from: components)!
        let julian = date.julian
        XCTAssert(julian == 2451544.5)
    }
    
    func testJulianTimezone() {
        var calendar = Calendar(identifier: .gregorian)
        let tz = TimeZone(abbreviation: "EST")!
        calendar.timeZone = tz
        let components = DateComponents(calendar: calendar, timeZone: tz, year: 2000, month: 1, day: 1, hour: 12, minute: 0, second: 0, nanosecond: 0)
        let date = calendar.date(from: components)!
        let julian = date.julian
        let rounded = round(julian * 1000.0)/1000.0
        XCTAssert(rounded == 2451545.208)
    }
    
    static var allTests : [(String, (DaylightTests) -> () throws -> Void)] {
        return [
            ("testJulianGMT", testJulianGMT),
            ("testJulianTimezone", testJulianTimezone),
        ]
    }
}
