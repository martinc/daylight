//
//  DaylightUtilities.swift
//  Daylight
//
//  Created by Martin Ceperley on 4/9/17.
//
//

import Foundation

// Time zone utilities

internal extension Calendar {

    /// A gregorian calendar with the GMT (UTC) timezone
    static var gmt: Calendar {
        let tz = TimeZone(abbreviation: "GMT")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz
        return calendar
    }

    /// A gregorian calendar with the given timezone
    static func with(tz: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz
        return calendar
    }
}

// Date manipulation utilities

internal extension Date {
    var dayBefore: Date {
        return addDays(-1)
    }

    var dayAfter: Date {
        return addDays(1)
    }

    private func addDays(_ days: Int) -> Date {
        return Calendar.gmt.date(byAdding: DateComponents(day: days), to: self)!
    }
    
    func atMidnight(timeZone: TimeZone) -> Date {
        let calendar = Calendar.with(tz: timeZone)
        let components = calendar.dateComponents(Set([.day, .month, .year]), from: self)
        return calendar.date(from: components)!
    }
}

// Julian Date utilities

internal extension Date {

    /// Converts the date to a julian date at the GMT timezone
    var julian: JulianDate {
        return julianTz(TimeZone(abbreviation: "GMT")!)
    }

    /// Converts the date to a julian date at the given timezone
    func julianTz(_ tz: TimeZone) -> JulianDate {

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz
        let comps = Set<Calendar.Component>([.year, .month, .day, .hour, .minute, .second, .nanosecond])
        let c = calendar.dateComponents(comps, from: self)
        guard let y = c.year, let m = c.month, let d = c.day,
            let hh = c.hour, let mm = c.minute, let ss = c.second, let ns = c.nanosecond else {
                fatalError("DateComponents are missing")
        }
        let ms = ns * 1000

        // Calc integer part (days)
        let jday: Int64 =
            (1461*(Int64(y)+4800+(Int64(m)-14)/12))/4 +
                (367*(Int64(m)-2-12*((Int64(m)-14)/12)))/12 -
                (3*((Int64(y)+4900+(Int64(m)-14)/12)/100))/4 +
                Int64(d) - 32075

        // Calc floating point part (fraction of a day)
        let jdatetime: Float64 =
            Float64(jday) +
                (Float64(hh)-12.0)/24.0 +
                (Float64(mm) / 1440.0) +
                (Float64(ss) / 86400.0) +
                (Float64(ms) / 86400000.0)

        // Timezone offset
        let zoneOffset = calendar.timeZone.secondsFromGMT(for: self)
        let out = jdatetime + Float64(zoneOffset)/86400.0
        return out
    }
}

// Julian Date to Julian Century conversion

internal extension JulianDate {

    ///convert Julian Day to centuries since J2000.0.
    var centuries: JulianCenturies {
        return (self - 2451545.0) / 36525.0
    }

    ///convert Julian Centuries to Julian Date
    static func from(centuries: JulianCenturies) -> JulianDate {
        return centuries*36525.0 + 2451545.0
    }
}

internal extension FloatingPoint {
    var degToRad: Self { return self * .pi / 180 }
    var radToDeg: Self { return self * 180 / .pi }

}

// Trig utilities

internal func sinDeg(_ x: Float64) -> Float64 { return sin( x.degToRad ) }
internal func cosDeg(_ x: Float64) -> Float64 { return cos( x.degToRad ) }
internal func tanDeg(_ x: Float64) -> Float64 { return tan( x.degToRad ) }
