import Foundation
import XCTest
import CoreLocation

@testable import Daylight

typealias Coords = CLLocationCoordinate2D

struct Time {
    let h: Int, m: Int
}

struct LocationSample {
    let location: Location
    let date: Day
    let sunrise: Time, sunset: Time, dawn: Time, dusk: Time
    let eot: Double
    let declination: Double

    var dateAtMidnight: Date {
        let cal = Calendar.with(tz: location.tz)
        let components = DateComponents(calendar: cal, timeZone: cal.timeZone,
                                        year: date.year, month: date.month, day: date.day)
        return cal.date(from: components)!
    }
}

class DaylightTests: XCTestCase {

    lazy var sampleData: [LocationSample] = {

        let sydney = Location(tz: TimeZone(identifier: "Australia/Sydney")!,
                              coords: Coords(latitude: -33.86, longitude: 151.20))
        let stockholm = Location(tz: TimeZone(identifier: "Europe/Stockholm")!,
                        coords: Coords(latitude: 59.33, longitude: 18.067))
        let newyork = Location(tz: TimeZone(identifier: "America/New_York")!,
                              coords: Coords(latitude: 40.642, longitude: -74.017))

        let november = Day(year: 2014, month: 11, day: 1)
        let july = Day(year: 2015, month: 7, day: 1)

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

    func checkTimesMatch(date: Date, time: Time, timezone: TimeZone) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone
        let computedHour = calendar.component(.hour, from: date)
        let computedMinute = calendar.component(.minute, from: date)

        let computedMinutes = Float((computedHour * 60) + computedMinute)
        let targetMinutes = Float((time.h * 60) + time.m)

        XCTAssertEqualWithAccuracy(computedMinutes, targetMinutes, accuracy: 1.0, "Times need to be within 1 minute")
    }

    func testDateInterface() {
        for sample in sampleData {
            let timezone = sample.location.tz

            let sunrise = sample.dateAtMidnight.timeOf(.sunrise, at: sample.location)
            let sunset = sample.dateAtMidnight.timeOf(.sunset, at: sample.location)
            let dawn = sample.dateAtMidnight.timeOf(.civilDawn, at: sample.location)
            let dusk = sample.dateAtMidnight.timeOf(.civilDusk, at: sample.location)

            checkTimesMatch(date: sunrise, time: sample.sunrise, timezone: timezone)
            checkTimesMatch(date: sunset, time: sample.sunset, timezone: timezone)
            checkTimesMatch(date: dawn, time: sample.dawn, timezone: timezone)
            checkTimesMatch(date: dusk, time: sample.dusk, timezone: timezone)
        }
    }

    func testDayInterface() {
        for sample in sampleData {
            let sunrise = sample.date.timeOf(.sunrise, at: sample.location)
            let sunset = sample.date.timeOf(.sunset, at: sample.location)
            let dawn = sample.date.timeOf(.civilDawn, at: sample.location)
            let dusk = sample.date.timeOf(.civilDusk, at: sample.location)

            let timezone = sample.location.tz

            checkTimesMatch(date: sunrise, time: sample.sunrise, timezone: timezone)
            checkTimesMatch(date: sunset, time: sample.sunset, timezone: timezone)
            checkTimesMatch(date: dawn, time: sample.dawn, timezone: timezone)
            checkTimesMatch(date: dusk, time: sample.dusk, timezone: timezone)
        }
    }

    static var allTests: [(String, (DaylightTests) -> () throws -> Void)] {
        return [
            ("testDateInterface", testDateInterface),
            ("testDayInterface", testDayInterface)
        ]
    }
}
