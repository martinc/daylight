//
//  Daylight.swift
//
//  Created by Martin Ceperley on 3/24/17.
//  Copyright © 2017 Emergence Studios LLC. All rights reserved.
//

import Foundation
import CoreLocation

public enum SolarEvent {
    case sunrise
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
        case .sunrise, .sunset:
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
}

public struct Day {
    public let year: Int, month: Int, day: Int

    public func timeOf(_ solarEvent: SolarEvent, at location: Location) -> Date {
        let components = DateComponents(year: year, month: month, day: day)
        let calendar = Calendar.with(tz: location.tz)
        let inputDate = calendar.date(from: components)!
        return inputDate.timeOf(solarEvent, at: location)
    }
}

public extension Date {

    public func timeOf(_ solarEvent: SolarEvent, at location: Location) -> Date {
        switch solarEvent {
        case .sunrise, .civilDawn, .nauticalDawn, .astronomicalDawn:
            return calculateDawn(location: location.coords,
                                           solarElevation: solarEvent.elevation.rawValue,
                                           timezone: location.tz)
        case .sunset, .civilDusk, .nauticalDusk, .astronomicalDusk:
            return calculateDusk(location: location.coords,
                                           solarElevation: solarEvent.elevation.rawValue,
                                           timezone: location.tz)
        }
    }

    private func calculateDawn(location: CLLocationCoordinate2D,
                               solarElevation: Float64,
                               timezone: TimeZone) -> Date {

        let julianDate = self.julianTz(timezone)
        let sunriseUTCMins = julianDate.sunriseUTC(location: location, solarElevation: solarElevation)

        return self.dateFromTimeUTC(timeUTCMins: sunriseUTCMins, timezone: timezone)
    }

    private func calculateDusk(location: CLLocationCoordinate2D,
                               solarElevation: Float64,
                               timezone: TimeZone) -> Date {

        let julianDate = self.julianTz(timezone)
        let duskUTCMins = julianDate.sunsetUTC(location: location, solarElevation: solarElevation)

        return self.dateFromTimeUTC(timeUTCMins: duskUTCMins, timezone: timezone)
    }

}
