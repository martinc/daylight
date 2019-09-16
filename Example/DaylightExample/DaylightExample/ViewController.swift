//
//  ViewController.swift
//  DaylightExample
//
//  Created by Martin Ceperley on 4/19/17.
//  Copyright © 2017 Emergence Studios LLC. All rights reserved.
//

import UIKit
import CoreLocation
import Daylight

class ViewController: UIViewController {
    let locationManager = CLLocationManager()
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView(frame: .zero)
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        return stackView
    }()
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.timeStyle = .long
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        stackView.frame = view.bounds
        view.addSubview(stackView)

        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    func displayTimesAt(_ location: CLLocation) {
        let timeZone = TimeZone.current
        let date = Date()
        let loc = Location(tz: timeZone, coords: location.coordinate)
        
        let sunrise = try? date.timeOf(.sunrise, at: loc)
        let noon = try? date.timeOf(.noon, at: loc)
        let sunset = try? date.timeOf(.sunset, at: loc)
        let nextSunrise = try? date.timeOfNext(.sunrise, at: loc)
        let nextSunset = try? date.timeOfNext(.sunset, at: loc)

        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 3

        let latString = numberFormatter.string(from: NSNumber(value: loc.coords.latitude))!
        let lonString = numberFormatter.string(from: NSNumber(value: loc.coords.longitude))!

        let labelStrings = [
            "Lon: \(latString)º Lat: \(lonString)º",
            "Timezone: \(timeZone.identifier)",
            "Sunrise: \(dateFormatter.string(from: sunrise!))",
            "Solar Noon: \(dateFormatter.string(from: noon!))",
            "Sunset: \(dateFormatter.string(from: sunset!))",
            "Next Sunrise: \(dateFormatter.string(from: nextSunrise!))",
            "Next Sunset: \(dateFormatter.string(from: nextSunset!))"
        ]
        
        for view in stackView.subviews {
            view.removeFromSuperview()
        }

        for text in labelStrings {
            let label = UILabel(frame: .zero)
            label.text = text
            label.font = UIFont.boldSystemFont(ofSize: 24.0)
            label.adjustsFontSizeToFitWidth = true
            stackView.addArrangedSubview(label)
        }
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            displayTimesAt(location)
        }
    }
}
