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
    let buttonColor = UIColor(red: (226/255), green: (89/255), blue: (40/255), alpha: 1.0)
    let format = ".2"
    
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
    
    let locationManager = CLLocationManager()
    var motionManager = CMMotionManager()
    let geoCoder = CLGeocoder()
    var locationUpdatesOn = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        addressLabel.numberOfLines = 0
        addressLabel.sizeToFit()
        startLocatingButton.layer.cornerRadius = 5
        startLocatingButton.layer.borderWidth = 2
        startLocatingButton.layer.borderColor = buttonColor.cgColor
        
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
                    
                    self.addressLabel.text = "\(placemark!.subThoroughfare!) \(placemark!.thoroughfare!)\n\(placemark!.locality!), \(placemark!.administrativeArea!) \(placemark!.postalCode!) "
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
        print("error")
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
    }
    
    func timeHasElapsed() -> Bool {
        if Date().timeIntervalSince1970 >= (timeOfLastSample + sampleInterval) {
            return true
        } else {
            return false
        }
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

extension UIColor {
    public convenience init?(hexString: String) {
        let r, g, b, a: CGFloat
        
        if hexString.hasPrefix("#") {
            let start = hexString.index(hexString.startIndex, offsetBy: 1)
            let hexColor = hexString.substring(from: start)
            
            if hexColor.characters.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255
                    
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        
        return nil
    }
}


extension Double {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}
