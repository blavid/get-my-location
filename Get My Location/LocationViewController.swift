//
//  ViewController.swift
//  Get My Location
//
//  Created by Blake Clough on 10/4/16.
//  Copyright © 2016 Blake Clough. All rights reserved.
//

import UIKit
import CoreLocation
import CoreMotion

class LocationViewController: UIViewController, CLLocationManagerDelegate {
    
    var username: String = ""
    var timeOfLastSample = Date().timeIntervalSince1970
    var sampleInterval: TimeInterval = 5 // seconds
    let format = ".2"
    let locationManager = CLLocationManager()
    var motionManager = CMMotionManager()
    let geoCoder = CLGeocoder()
    var locationUpdatesOn = false
    
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var startLocatingButton: UIButton!
    @IBOutlet weak var accelerationX: UILabel!
    @IBOutlet weak var accelerationY: UILabel!
    @IBOutlet weak var accelerationZ: UILabel!
    @IBOutlet weak var rotationX: UILabel!
    @IBOutlet weak var rotationY: UILabel!
    @IBOutlet weak var rotationZ: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        addressLabel.numberOfLines = 0
        addressLabel.sizeToFit()
        startLocatingButton.layer.cornerRadius = 5
        startLocatingButton.layer.borderWidth = 2
        startLocatingButton.layer.borderColor = webtrendsOrange.cgColor
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func getCurrentLocation(_ sender: AnyObject) {
        self.locationUpdatesOn = !self.locationUpdatesOn
        var buttonTitle: String
        if locationUpdatesOn {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            
            motionManager.accelerometerUpdateInterval = 0.2
            motionManager.gyroUpdateInterval = 0.2
            motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (accelerometerData: CMAccelerometerData?, error: Error?) in
                self.outputAccelerationData(acceleration: (accelerometerData?.acceleration)!)
                if (error != nil) {
                    print(error)
                }
            }
            motionManager.startGyroUpdates(to: OperationQueue.current!) { (gyroData: CMGyroData?, error: Error?) in
                self.outputRotationData(rotation: (gyroData?.rotationRate)!)
                if (error != nil) {
                    print(error)
                }
                
            }
            buttonTitle = "Stop Locating"
        } else {
            locationManager.stopUpdatingLocation()
            motionManager.stopGyroUpdates()
            motionManager.stopAccelerometerUpdates()
            
            buttonTitle = "Start Locating"
            self.latitudeLabel.text = ""
            self.longitudeLabel.text = ""
            self.addressLabel.text = ""
            
        }
        startLocatingButton.setTitle(buttonTitle, for: .normal)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation = locations.last
        latitudeLabel.text = "\(currentLocation!.coordinate.latitude)"
        longitudeLabel.text = "\(currentLocation!.coordinate.longitude)"
        geoCoder.reverseGeocodeLocation(currentLocation!) { (placemarks: [CLPlacemark]?, error:Error?) in
            if error != nil {
                print("Error looking up address of geo location.")
                return
            } else {
                if (placemarks?.count)! > 0 {
                    let placemark = placemarks?.last
                    if let addr1 = placemark?.subThoroughfare,
                        let addr2 = placemark?.thoroughfare,
                        let city = placemark?.locality,
                        let state = placemark?.administrativeArea,
                        let zip = placemark?.postalCode {
                            self.addressLabel.text = "\(addr1) \(addr2)\n\(city), \(state) \(zip) "
                    }
                }
            }
        }
        if timeHasElapsed() {
            // Reset the timer and send a WT event
            self.timeOfLastSample = Date().timeIntervalSince1970
            sendEvent()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error: Unable to determine location")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationManager.startUpdatingLocation()
    }
    
    func sendEvent() {
        // Build and send a custom event
        let customParams = ["username":"\(username)",
            "acceleration.x":"\(accelerationX.text!)",
            "acceleration.y":"\(accelerationY.text!)",
            "acceleration.z":"\(accelerationZ.text!)",
            "rotation.x":"\(rotationX.text!)",
            "rotation.y":"\(rotationY.text!)",
            "rotation.z":"\(rotationZ.text!)"]
        
        let eventMeta = WTEventMeta(eventPath: "LocationDemo/newLocation", description: "A new location was triggered", type: "Location Change", customParams: customParams)
        WTDataCollector.shared().triggerEvent(forCustomEvent: eventMeta)
        
        // Indicate that event was sent by changing color of button
        if startLocatingButton.layer.backgroundColor == UIColor.white.cgColor {
            startLocatingButton.layer.backgroundColor = UIColor.black.cgColor
            startLocatingButton.setTitleColor(UIColor.white, for: .normal)
        } else {
            startLocatingButton.layer.backgroundColor = UIColor.white.cgColor
            startLocatingButton.setTitleColor(UIColor.black, for: .normal)
        }
        
    }
    
    func timeHasElapsed() -> Bool {
        return Date().timeIntervalSince1970 >= (timeOfLastSample + sampleInterval) ? true : false
    }
    
    func outputAccelerationData(acceleration: CMAcceleration) {
        accelerationX.text = "\(acceleration.x.format(f: format))"
        accelerationY.text = "\(acceleration.y.format(f: format))"
        accelerationZ.text = "\(acceleration.z.format(f: format))"
    }
    
    func outputRotationData(rotation: CMRotationRate) {
        rotationX.text = "\(rotation.x.format(f: format))"
        rotationY.text = "\(rotation.y.format(f: format))"
        rotationZ.text = "\(rotation.z.format(f: format))"
    }

}

// Double extension to support returning a double value as a formatted string with a limit on decimal precision
extension Double {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}
