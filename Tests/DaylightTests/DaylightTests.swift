import Foundation
import XCTest
import CoreLocation

@testable import Daylight

typealias Coords = CLLocationCoordinate2D

struct Location {
    let tz: String
    let coords: Coords
}

struct Time {
    let h: Int, m: Int
}

struct Day {
    let y: Int, m: Int, d: Int
}

extension Calendar {
}

struct LocationSample {
    let location: Location
    let date: Day
    let sunrise: Time, sunset: Time, dawn: Time, dusk: Time
    let eot: Double
    let declination: Double

    var dateAtMidnight: Date {
        let cal = Calendar.with(timezone: location.tz)
        let components = DateComponents(calendar: cal, timeZone: cal.timeZone, year: date.y, month: date.m, day: date.d)
        return cal.date(from: components)!
    }
}

class DaylightTests: XCTestCase {

    lazy var sampleData: [LocationSample] = {

        let sydney = Location(tz: "Australia/Sydney",
                              coords: Coords(latitude: -33.86, longitude: 151.20))
        let stockholm = Location(tz: "Europe/Stockholm",
                        coords: Coords(latitude: 59.33, longitude: 18.067))
        let newyork = Location(tz: "America/New_York",
                              coords: Coords(latitude: 40.642, longitude: -74.017))

        let november = Day(y: 2014, m: 11, d: 1)
        let july = Day(y: 2015, m: 7, d: 1)

        return [
            LocationSample(location: sydney, date: november,
                           sunrise: Time(h: 5, m: 55), sunset: Time(h: 19, m: 23),
                           dawn: Time(h: 5, m: 29), dusk: Time(h: 19, m: 49),
                           eot: 16.42, declination: -14.18),

            LocationSample(location: stockholm, date: november,
                           sunrise: Time(h: 7, m: 07), sunset: Time(h: 15, m: 55),
                           dawn: Time(h: 6, m: 23), dusk: Time(h: 16, m: 39),
                           eot: 16.44, declination: -14.32),

            LocationSample(location: newyork, date: november,
                           sunrise: Time(h: 7, m: 26), sunset: Time(h: 17, m: 52),
                           dawn: Time(h: 6, m: 58), dusk: Time(h: 18, m: 21),
                           eot: 16.44, declination: -14.38),

            LocationSample(location: sydney, date: july,
                           sunrise: Time(h: 7, m: 1), sunset: Time(h: 16, m: 57),
                           dawn: Time(h: 6, m: 33), dusk: Time(h: 17, m: 25),
                           eot: -3.63, declination: 23.16),

            LocationSample(location: stockholm, date: july,
                           sunrise: Time(h: 3, m: 37), sunset: Time(h: 22, m: 6),
                           dawn: Time(h: 2, m: 9), dusk: Time(h: 23, m: 33),
                           eot: -3.7, declination: 23.14),

            LocationSample(location: newyork, date: july,
                           sunrise: Time(h: 5, m: 29), sunset: Time(h: 20, m: 31),
                           dawn: Time(h: 4, m: 55), dusk: Time(h: 21, m: 4),
                           eot: -3.75, declination: 23.13)

        ]
    }()

    func testJulianGMT() {
        let calendar = Calendar.gmt
        let components = DateComponents(calendar: calendar, year: 2000, month: 1, day: 1)
        let date = calendar.date(from: components)!
        let julian = date.julian
        XCTAssert(julian == 2451544.5)
    }

    func testJulianTimezone() {
        var calendar = Calendar(identifier: .gregorian)
        let tz = TimeZone(abbreviation: "EST")!
        calendar.timeZone = tz
        let components = DateComponents(calendar: calendar, timeZone: tz, year: 2000, month: 1, day: 1, hour: 12)
        let date = calendar.date(from: components)!
        let julian = date.julianTz(tz)
        XCTAssertEqualWithAccuracy(julian, 2451544.791667, accuracy: 0.005)
    }

    func testSolarDeclination() {
        for data in sampleData {
            let declination = data.dateAtMidnight.julian.centuries.declinationOfSun
            XCTAssertEqualWithAccuracy(declination, data.declination, accuracy: 0.005)
        }
    }

    func testEquationOfTime() {
        for data in sampleData {
            let equationOfTime = data.dateAtMidnight.julian.centuries.equationOfTime
            XCTAssertEqualWithAccuracy(equationOfTime, data.eot, accuracy: 0.005)
        }
    }

    func testSunrise() {

        for sample in sampleData {
            let inputDate = sample.dateAtMidnight

            let timezone = TimeZone(identifier: sample.location.tz)!
            let dawn = inputDate.calculateDawn(location: sample.location.coords,
                                               solarElevation: 0.0,
                                               timezone: timezone)

            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timezone
            let hour = calendar.component(.hour, from: dawn)
            let minute = calendar.component(.minute, from: dawn)

            let actualMinutes = Float((hour * 60) + minute)
            let targetMinutes = Float((sample.sunrise.h * 60) + sample.sunrise.m)

            XCTAssertEqualWithAccuracy(actualMinutes, targetMinutes, accuracy: 1.0, "Times need to be within 1 minute")
        }
    }

    static var allTests: [(String, (DaylightTests) -> () throws -> Void)] {
        return [
            ("testJulianGMT", testJulianGMT),
            ("testJulianTimezone", testJulianTimezone),
            ("testSolarDeclination", testSolarDeclination),
            ("testEquationOfTime", testEquationOfTime),
            ("testSunrise", testSunrise)
        ]
    }
}
