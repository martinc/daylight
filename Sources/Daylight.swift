//
//  Daylight.swift
//
//  Created by Martin Ceperley on 3/24/17.
//  Copyright © 2017 Emergence Studios LLC. All rights reserved.
//

import Foundation
import CoreLocation

public enum SolarEventError: Error {
    case neverRise
    case neverSet
}

public enum SolarEvent {
    case sunrise
    case noon
    case sunset
    case civilDawn
    case civilDusk
    case nauticalDawn
    case nauticalDusk
    case astronomicalDawn
    case astronomicalDusk

    internal var elevation: SolarElevation {
        switch self {
        case .astronomicalDawn, .astronomicalDusk:
            return .astronomicalDawnDusk
        case .nauticalDawn, .nauticalDusk:
            return .nauticalDawnDusk
        case .civilDawn, .civilDusk:
            return .civilDawnDusk
        case .sunrise, .sunset, .noon:
            return .sunriseSunset
        }
    }
}

internal enum SolarElevation: Float64 {
    case astronomicalDawnDusk = -18.0
    case nauticalDawnDusk =     -12.0
    case civilDawnDusk =        -6.0
    case sunriseSunset =        0.0
}

public struct Location {
    public let tz: TimeZone
    public let coords: CLLocationCoordinate2D
    
    public init(tz: TimeZone, coords: CLLocationCoordinate2D) {
        self.tz = tz
        self.coords = coords
    }
}

public struct Day {
    public let year: Int, month: Int, day: Int
    
    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public func timeOf(_ solarEvent: SolarEvent, at location: Location) throws -> Date {
        let components = DateComponents(year: year, month: month, day: day)
        let calendar = Calendar.with(tz: location.tz)
        let inputDate = calendar.date(from: components)!
        return try inputDate.timeOf(solarEvent, at: location)
    }
}

public extension Date {

    public func timeOf(_ solarEvent: SolarEvent, at location: Location) throws -> Date {
        switch solarEvent {
        case .sunrise, .civilDawn, .nauticalDawn, .astronomicalDawn:
            return try calculateDawn(location: location.coords,
                                 solarElevation: solarEvent.elevation.rawValue,
                                 timezone: location.tz)
        case .sunset, .civilDusk, .nauticalDusk, .astronomicalDusk:
            return try calculateDusk(location: location.coords,
                                 solarElevation: solarEvent.elevation.rawValue,
                                 timezone: location.tz)
        case .noon:
            return try calculateNoon(location: location.coords,
                                 timezone: location.tz)
        }
    }

    public func timeOfNext(_ solarEvent: SolarEvent, at location: Location) throws -> Date {
        var time = try timeOf(solarEvent, at: location)
        if self >= time {
            time = try dayAfter.timeOf(solarEvent, at: location)
        }
        return time
    }

    private func calculateDawn(location: CLLocationCoordinate2D,
                               solarElevation: Float64,
                               timezone: TimeZone) throws -> Date {

        let midnight = self.atMidnight(timeZone: timezone)
        let julianDate = midnight.julianTz(timezone)
        let sunriseUTCMins = try julianDate.sunriseUTC(location: location, solarElevation: solarElevation)

        return self.dateFromTimeUTC(timeUTCMins: sunriseUTCMins, timezone: timezone)
    }

    private func calculateDusk(location: CLLocationCoordinate2D,
                               solarElevation: Float64,
                               timezone: TimeZone) throws -> Date {

        let midnight = self.atMidnight(timeZone: timezone)
        let julianDate = midnight.julianTz(timezone)
        let duskUTCMins = try julianDate.sunsetUTC(location: location, solarElevation: solarElevation)

        return self.dateFromTimeUTC(timeUTCMins: duskUTCMins, timezone: timezone)
    }

    private func calculateNoon(location: CLLocationCoordinate2D,
                               timezone: TimeZone) throws -> Date {
        let sunrise = try calculateDawn(location: location,
                                    solarElevation: SolarEvent.sunrise.elevation.rawValue,
                                    timezone: timezone)
        let sunset = try calculateDusk(location: location,
                                   solarElevation: SolarEvent.sunset.elevation.rawValue,
                                   timezone: timezone)
        let dayLength = sunset.timeIntervalSince(sunrise)
        return sunrise + (dayLength / 2.0)
    }

}
