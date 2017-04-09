//
//  Daylight.swift
//
//  Created by Martin Ceperley on 3/24/17.
//  Copyright © 2017 Emergence Studios LLC. All rights reserved.
//

import Foundation
import CoreLocation

struct Daylight {

    var text = "Hello, World!"
}

enum SolarElevations: Float64 {
    case astronomicalDawnDusk = -18.0
    case nauticalDawnDusk =     -12.0
    case civilDawnDusk =        -6.0
    case sunriseSunset =        0.0
}

public typealias JulianDate = Float64
public typealias JulianCenturies = Float64

public extension Calendar {

    /// A gregorian calendar with the GMT (UTC) timezone
    static var gmt: Calendar {
        let tz = TimeZone(abbreviation: "GMT")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz
        return calendar
    }

    /// A gregorian calendar with the given timezone name
    static func with(timezone: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timezone)!
        return calendar
    }
}

public extension Date {

    /// Converts the date to a julian date at the GMT timezone
    public var julian: JulianDate {
        return julianTz(TimeZone(abbreviation: "GMT")!)
    }

    /// Converts the date to a julian date at the given timezone
    public func julianTz(_ tz: TimeZone) -> JulianDate {

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

public extension JulianDate {

    ///convert Julian Day to centuries since J2000.0.
    public var centuries: JulianCenturies {
        return (self - 2451545.0) / 36525.0
    }

    ///convert Julian Centuries to Julian Date
    public static func from(centuries: JulianCenturies) -> JulianDate {
        return centuries*36525.0 + 2451545.0
    }
}

private extension FloatingPoint {
    var degToRad: Self { return self * .pi / 180 }
    var radToDeg: Self { return self * 180 / .pi }

}

private func sinDeg(_ x: Float64) -> Float64 { return sin( x.degToRad ) }
private func cosDeg(_ x: Float64) -> Float64 { return cos( x.degToRad ) }
private func tanDeg(_ x: Float64) -> Float64 { return tan( x.degToRad ) }

public extension JulianCenturies {

    ///calculate the Geometric Mean Longitude of the Sun
    public var geometricMeanLonSun: Float64 {
        var lon: Float64 = 280.46646 + self*(36000.76983+0.0003032*self)
        while lon > 360.0 { lon -= 360.0 }
        while lon < 0.0 { lon += 360.0 }
        return lon
    }

    ///calculate the mean obliquity of the ecliptic
    public var meanObliquityOfEcliptic: Float64 {
        let seconds = 21.448 - self*(46.8150+self*(0.00059-self*(0.001813)))
        return 23.0 + (26.0+(seconds/60.0))/60.0
    }

    ///calculate the corrected obliquity of the ecliptic
    public var obliquityCorrection: Float64 {
        let e0 = meanObliquityOfEcliptic
        let omega = 125.04 - 1934.136*self
        return e0 + 0.00256*cos(omega.degToRad)
    }

    ///calculate the eccentricity of earth's orbit
    public var eccentricityEarthOrbit: Float64 {
        return 0.016708634 - self*(0.000042037+0.0000001267*self)
    }

    ///calculate the Geometric Mean Anomaly of the Sun
    public var geometricMeanAnomalySun: Float64 {
        return 357.52911 + self*(35999.05029-0.0001537*self)
    }

    ///calculate the difference between true solar time and mean
    /// - returns: equation of time in minutes of time
    public var equationOfTime: Float64 {

        let epsilon = obliquityCorrection
        let l0 = geometricMeanLonSun
        let e = eccentricityEarthOrbit
        let m = geometricMeanAnomalySun

        //print("Epsilon: \(epsilon) l0: \(l0) e: \(e) m: \(m)")

        var y = tanDeg(epsilon/2.0)
        y *= y

        let sin2l0 = sinDeg(2.0 * l0)
        let sinm = sinDeg(m)
        let cos2l0 = cosDeg(2.0 * l0)
        let sin4l0 = sinDeg(4.0 * l0)
        let sin2m = sinDeg(2.0 * m)

        let eTime = y*sin2l0 - 2.0*e*sinm + 4.0*e*y*sinm*cos2l0 - 0.5*y*y*sin4l0 - 1.25*e*e*sin2m

        let out = (eTime * 4.0).radToDeg

        //print("Equation of time INPUT: \(self) OUTPUT: \(out)")

        return out
    }

    ///calculate the equation of center for the sun
    public var centerOfSun: Float64 {
        let rad = geometricMeanAnomalySun
        //let mrad = rad.degToRad
        let sinm = sinDeg(rad)
        let sin2m = sinDeg(2 * rad)
        let sin3m = sinDeg(3 * rad)

        return sinm*(1.914602-self*(0.004817+0.000014*self)) + sin2m*(0.019993-0.000101*self) + sin3m*0.000289
    }

    ///calculate the true longitude of the sun
    /// - returns: sun's true longitude in degrees
    public var trueLonOfSun: Float64 {
        return geometricMeanLonSun + centerOfSun
    }

    ///calculate the apparent longitude of the sun
    /// - returns: sun's apparent longitude in degrees
    public var apparentLonOfSun: Float64 {
        let o = trueLonOfSun
        let omega = 125.04 - 1934.136*self
        return o - 0.00569 - 0.00478*sinDeg(omega)
    }

    ///calculate the declination of the sun
    /// - returns: sun's declination in degrees
    public var declinationOfSun: Float64 {
        let e = obliquityCorrection
        let lambda = apparentLonOfSun
        let sint = sinDeg(e) * sinDeg(lambda)
        return asin(sint).radToDeg
    }

    ///calculate the Universal Coordinated Time (UTC) of solar
    ///		noon for the given day at the given location on earth
    /// - returns: time in minutes from zero Z
    public func solarNoonUTC(longitude: Float64) -> Float64 {
        let jdate = JulianDate.from(centuries: self) + longitude/360.0
        let tnoon = jdate.centuries
        let eqTime = tnoon.equationOfTime
        let solNoonUTC = 720 + (longitude * 4) - eqTime

        let newtDay = JulianDate.from(centuries: self) - 0.5 + solNoonUTC/1440.0
        let newt = newtDay.centuries
        let eqTimeNew = newt.equationOfTime
        let out = 720 + (longitude * 4) - eqTimeNew

        return out
    }

}

public extension JulianDate {

    // Purpose: calculate the Universal Coordinated Time (UTC) of sunrise
    //			for the given day at the given location on earth
    // Return value:
    //   time in minutes from zero Z
    public func sunriseUTC(location: CLLocationCoordinate2D, solarElevation: Float64) -> Float64 {
        let longitude = location.longitude * -1
        let centuries = self.centuries
        let noonMinutes = centuries.solarNoonUTC(longitude: longitude)
        let noonTime = (self + (noonMinutes/1440.0)).centuries

        // First Pass

        var eqTime = noonTime.equationOfTime
        var declination = noonTime.declinationOfSun
        var hourAngle = hourAngleOfSunrise(latitude: location.latitude,
                                           solarDeclination: declination,
                                           solarElevation: solarElevation)

        var delta = longitude - hourAngle.radToDeg
        var timeDiff = delta * 4.0
        var timeUTC = 720.0 + timeDiff - eqTime

        // Second Pass

        let newTime = (JulianDate.from(centuries: centuries) + (timeUTC/1440.0)).centuries

        eqTime = newTime.equationOfTime
        declination = newTime.declinationOfSun
        hourAngle = hourAngleOfSunrise(latitude: location.latitude,
                                       solarDeclination: declination,
                                       solarElevation: solarElevation)

        delta = longitude - hourAngle.radToDeg
        timeDiff = delta * 4.0
        timeUTC = 720.0 + timeDiff - eqTime

        return timeUTC
    }

}

public extension Date {

    public func calculateDawn(location: CLLocationCoordinate2D,
                              solarElevation: Float64 = SolarElevations.civilDawnDusk.rawValue,
                              timezone: TimeZone) -> Date {
        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = timezone

        let localDay = localCalendar.component(.day, from: self)
        let localMonth = localCalendar.component(.month, from: self)
        let localYear = localCalendar.component(.year, from: self)

        let julianDate = self.julianTz(timezone)

        let sunriseUTCMins = julianDate.sunriseUTC(location: location, solarElevation: solarElevation)
        let sunriseUTCSecs = floor(sunriseUTCMins * 60.0)

        let gmtCalendar = Calendar.gmt
        let comps = DateComponents(year: localYear, month: localMonth, day: localDay)
        let midnight = gmtCalendar.date(from: comps)!

        return gmtCalendar.date(byAdding: .second, value: Int(sunriseUTCSecs), to: midnight)!
    }

    public func calculateSunrise(location: CLLocationCoordinate2D, timezone: TimeZone) -> Date {
        return self.calculateDawn(location: location,
                                  solarElevation: SolarElevations.sunriseSunset.rawValue,
                                  timezone: timezone)
    }

}

/// Calculates the refractive correction for the specified solar elevation.
/// The refractive correction only applies at sunrise and sunset (solarElevation == 0).
/// Otherwise the correction is simply the negative of the solarElevation
func refractiveCorrection(solarElevation: Float64) -> Float64 {
    if solarElevation == 0 {
        return 0.833
    } else {
        return -solarElevation
    }
}

func hourAngleOfSunrise(latitude: Float64, solarDeclination: Float64, solarElevation: Float64) -> Float64 {

    let latRad = latitude.degToRad
    let sdRad = solarDeclination.degToRad
    let correction = refractiveCorrection(solarElevation: solarElevation)

    return (acos(cos((90+correction).degToRad)/(cos(latRad)*cos(sdRad)) - tan(latRad)*tan(sdRad)))
}
