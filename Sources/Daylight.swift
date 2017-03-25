//
//  Daylight.swift
//
//  Created by Martin Ceperley on 3/24/17.
//  Copyright © 2017 Emergence Studios LLC. All rights reserved.
//

import Foundation

struct Daylight {

    var text = "Hello, World!"
}


public extension Calendar {
    
    static var gmt: Calendar {
        let tz = TimeZone(abbreviation: "GMT")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz
        return calendar
    }
    
}

public extension Date {
    
    public var julian: Double {
        
        let calendar = Calendar.gmt
        let comps = Set<Calendar.Component>([.year, .month, .day, .hour, .minute, .second, .nanosecond])
        let c = calendar.dateComponents(comps, from: self)
        guard let y = c.year, let m = c.month, let d = c.day, let hh = c.hour, let mm = c.minute, let ss = c.second, let ns = c.nanosecond else {
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

        return Double(jdatetime) + Double(zoneOffset)/86400.0
    }
}
