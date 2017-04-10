//
//  DaylightAstronomy.swift
//  Daylight
//
//  Created by Martin Ceperley on 4/9/17.
//
//

import Foundation
import CoreLocation

// Astronomical methods

internal typealias JulianDate = Float64
internal typealias JulianCenturies = Float64

private extension JulianCenturies {

    ///calculate the Geometric Mean Longitude of the Sun
    var geometricMeanLonSun: Float64 {
        var lon: Float64 = 280.46646 + self*(36000.76983+0.0003032*self)
        while lon > 360.0 { lon -= 360.0 }
        while lon < 0.0 { lon += 360.0 }
        return lon
    }

    ///calculate the mean obliquity of the ecliptic
    var meanObliquityOfEcliptic: Float64 {
        let seconds = 21.448 - self*(46.8150+self*(0.00059-self*(0.001813)))
        return 23.0 + (26.0+(seconds/60.0))/60.0
    }

    ///calculate the corrected obliquity of the ecliptic
    var obliquityCorrection: Float64 {
        let e0 = meanObliquityOfEcliptic
        let omega = 125.04 - 1934.136*self
        return e0 + 0.00256*cos(omega.degToRad)
    }

    ///calculate the eccentricity of earth's orbit
    var eccentricityEarthOrbit: Float64 {
        return 0.016708634 - self*(0.000042037+0.0000001267*self)
    }

    ///calculate the Geometric Mean Anomaly of the Sun
    var geometricMeanAnomalySun: Float64 {
        return 357.52911 + self*(35999.05029-0.0001537*self)
    }

    ///calculate the difference between true solar time and mean
    /// - returns: equation of time in minutes of time
    var equationOfTime: Float64 {

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
    var centerOfSun: Float64 {
        let rad = geometricMeanAnomalySun
        //let mrad = rad.degToRad
        let sinm = sinDeg(rad)
        let sin2m = sinDeg(2 * rad)
        let sin3m = sinDeg(3 * rad)

        return sinm*(1.914602-self*(0.004817+0.000014*self)) + sin2m*(0.019993-0.000101*self) + sin3m*0.000289
    }

    ///calculate the true longitude of the sun
    /// - returns: sun's true longitude in degrees
    var trueLonOfSun: Float64 {
        return geometricMeanLonSun + centerOfSun
    }

    ///calculate the apparent longitude of the sun
    /// - returns: sun's apparent longitude in degrees
    var apparentLonOfSun: Float64 {
        let o = trueLonOfSun
        let omega = 125.04 - 1934.136*self
        return o - 0.00569 - 0.00478*sinDeg(omega)
    }

    ///calculate the declination of the sun
    /// - returns: sun's declination in degrees
    var declinationOfSun: Float64 {
        let e = obliquityCorrection
        let lambda = apparentLonOfSun
        let sint = sinDeg(e) * sinDeg(lambda)
        return asin(sint).radToDeg
    }

    ///calculate the Universal Coordinated Time (UTC) of solar
    ///		noon for the given day at the given location on earth
    /// - returns: time in minutes from zero Z
    func solarNoonUTC(longitude: Float64) -> Float64 {
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

internal extension JulianDate {

    private typealias HourAngleFunction = (
        _ latitude: Float64,
        _ solarDeclination: Float64,
        _ solarElevation: Float64) -> Float64

    // Purpose: calculate the Universal Coordinated Time (UTC) of the given solar position
    //			for the given day at the given location on earth
    // Return value:
    //   time in minutes from zero Z

    private func calculateTimeUTCatHourAngle(location: CLLocationCoordinate2D,
                                             solarElevation: Float64,
                                             hourAngleFunction: @escaping HourAngleFunction ) -> Float64 {

        let longitude = location.longitude * -1

        func calculateTime(from centuries: JulianCenturies) -> Float64 {
            let eqTime = centuries.equationOfTime
            let declination = centuries.declinationOfSun
            let hourAngle = hourAngleFunction(location.latitude, declination, solarElevation)
            let delta = longitude - hourAngle.radToDeg
            let timeDiff = delta * 4.0
            return 720.0 + timeDiff - eqTime
        }

        let centuries = self.centuries
        let noonMinutes = centuries.solarNoonUTC(longitude: longitude)
        let noonTime = (self + (noonMinutes/1440.0)).centuries

        // First Pass

        let timeUTC = calculateTime(from: noonTime)

        // Second Pass

        let newTime = (JulianDate.from(centuries: centuries) + (timeUTC/1440.0)).centuries
        let finalTimeUTC = calculateTime(from: newTime)
        return finalTimeUTC
    }

    func sunriseUTC(location: CLLocationCoordinate2D, solarElevation: Float64) -> Float64 {
        return calculateTimeUTCatHourAngle(location: location,
                                           solarElevation: solarElevation,
                                           hourAngleFunction: hourAngleOfSunrise)
    }

    func sunsetUTC(location: CLLocationCoordinate2D, solarElevation: Float64) -> Float64 {
        return calculateTimeUTCatHourAngle(location: location,
                                           solarElevation: solarElevation,
                                           hourAngleFunction: hourAngleOfSunset)
    }

}

// Conversion from a date with a UTC minute component at a given timezone to a new date time

internal extension Date {

    internal func dateFromTimeUTC(timeUTCMins: Float64, timezone: TimeZone) -> Date {

        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = timezone
        let localDay = localCalendar.component(.day, from: self)
        let localMonth = localCalendar.component(.month, from: self)
        let localYear = localCalendar.component(.year, from: self)

        let gmtCalendar = Calendar.gmt
        let comps = DateComponents(year: localYear, month: localMonth, day: localDay)
        let midnight = gmtCalendar.date(from: comps)!

        let timeUTCSecs = floor(timeUTCMins * 60.0)

        return gmtCalendar.date(byAdding: .second, value: Int(timeUTCSecs), to: midnight)!
    }
}

/// Calculates the refractive correction for the specified solar elevation.
/// The refractive correction only applies at sunrise and sunset (solarElevation == 0).
/// Otherwise the correction is simply the negative of the solarElevation
private func refractiveCorrection(solarElevation: Float64) -> Float64 {
    if solarElevation == 0 {
        return 0.833
    } else {
        return -solarElevation
    }
}

private func hourAngleOfSunrise(latitude: Float64, solarDeclination: Float64, solarElevation: Float64) -> Float64 {

    let latRad = latitude.degToRad
    let sdRad = solarDeclination.degToRad
    let correction = refractiveCorrection(solarElevation: solarElevation)

    return (acos(cos((90+correction).degToRad)/(cos(latRad)*cos(sdRad)) - tan(latRad)*tan(sdRad)))
}

private func hourAngleOfSunset(latitude: Float64, solarDeclination: Float64, solarElevation: Float64) -> Float64 {

    let latRad = latitude.degToRad
    let sdRad = solarDeclination.degToRad
    let correction = refractiveCorrection(solarElevation: solarElevation)

    let hourAngle = acos(
        cos((90.0 + correction).degToRad) /
            (cos(latRad) * cos(sdRad)) -
            (tan(latRad) * tan(sdRad))
    )

    return -hourAngle
}
