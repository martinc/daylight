# daylight
A swift package that provides NOAA astrological algorithms for sunrise and sunset times

A port of the go library [astrotime](https://github.com/cpucycle/astrotime)

You can either use the interface with a Day struct containing the calendar date of interest, or use the interface of a Date object.

Note that using the Date object's interface will use the calendar date at the timezone of the Location.

The `SolarEvent` enum is used to specify the event of interest.

Example

```swift

let julyFirst = Day(year: 2015, month: 7, day: 1)
let newyork = Location(tz: TimeZone(identifier: "America/New_York")!,
                       coords: Coords(latitude: 40.642, longitude: -74.017))
let sunrise = julyFirst.timeOf(.sunrise, at: newyork)

//Format it to display in location's timezone
let dateFormatter = DateFormatter()
dateFormatter.timeZone = newyork.tz
dateFormatter.dateStyle = .long
dateFormatter.timeStyle = .long
print("Sunrise: \(dateFormatter.string(from: sunrise))")
```

Interface

```swift

public enum SolarEvent {
    case sunrise
    case sunset
    case civilDawn
    case civilDusk
    case nauticalDawn
    case nauticalDusk
    case astronomicalDawn
    case astronomicalDusk
}

public struct Location {
    public let tz: TimeZone
    public let coords: CLLocationCoordinate2D
}

public struct Day {
    public let year: Int, month: Int, day: Int
    public func timeOf(_ solarEvent: SolarEvent, at location: Location) -> Date
}

public extension Date {
    public func timeOf(_ solarEvent: SolarEvent, at location: Location) -> Date
    public func timeOfNext(_ solarEvent: SolarEvent, at location: Location) -> Date
}

```

