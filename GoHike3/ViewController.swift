//
//  ViewController.swift
//  GoHike
//
//  Created by James Chen on 5/8/17.
//  Copyright © 2017 jmchen. All rights reserved.
//
//  This is the Final Version of GoHike as of 6/21/17


import UIKit
import CoreLocation
import MapKit


class ViewController: UIViewController,CLLocationManagerDelegate,MKMapViewDelegate {
    
    // constants below are the camera settings for overhead views(2D like)
    let distance1: CLLocationDistance = 2000
    let distance3: CLLocationDistance = 6000 // used for drawMapPath() 2D view distance height
    let pitch1: CGFloat = 0.0
    let heading1 = 0.0
    
    // constants below are the camera settings for flyover views(3D like)
    let distance2: CLLocationDistance = 500
    let pitch2: CGFloat = 60.0
    let heading2 = 30.0
    
    
    var sourceLocation: CLLocationCoordinate2D!
    var destinationLocation: CLLocationCoordinate2D!
    var mapViewType = "SatelliteFlyover"
    var manager = CLLocationManager()
    var totalDistanceMeters2:Double = 0.0
    var mapDrawingDistance:Double = 0.0 // distance counter used for Timer function in drawing route
    var preTimeInterval = 0.0
    var startLocation: CLLocation!
    var lastLocation: CLLocation!
    var updateCount = 0
    var runSpeed: Double = 0.000
    
    // Label for OpenWeatherMap data:
    @IBOutlet weak var citiName: UILabel!
    @IBOutlet weak var tempurature: UILabel!
    @IBOutlet weak var weatherType: UILabel!
    
    
    @IBAction func toggleViews(_ sender: UISegmentedControl) {
        
        if sender.selectedSegmentIndex == 0 {
            let camera = MKMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: distance1, pitch: pitch1, heading: heading1)
            mapView.mapType = .standard
            mapView.showsBuildings = true
            mapView.setCamera(camera, animated: true)
            mapViewType = "Standard2D"
            
        } else if sender.selectedSegmentIndex == 1 {
            let camera = MKMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: distance1, pitch: pitch1, heading: heading1)
            mapView.mapType = .satellite
            mapView.showsBuildings = true
            mapView.setCamera(camera, animated: true)
            mapViewType = "Satellite2D"
            
        } else {
            let camera = MKMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: distance1, pitch: pitch1, heading: heading1)
            mapView.mapType = .hybrid
            mapView.showsBuildings = true
            mapView.setCamera(camera, animated: true)
            mapViewType = "Hybrid2D"
            
        }
        
    }
    
    @IBAction func toggleView3D(_ sender: UISegmentedControl) {
        
        if sender.selectedSegmentIndex == 0 {
            let camera = MKMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: distance2, pitch: pitch2, heading: heading2)
            mapView.mapType = .standard
            mapView.showsBuildings = true
            mapView.setCamera(camera, animated: true)
            mapViewType = "StandardFlyover"
            
        } else if sender.selectedSegmentIndex == 1 {
            let camera = MKMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: distance2, pitch: pitch2, heading: heading2)
            mapView.mapType = .satelliteFlyover
            mapView.showsBuildings = true
            mapView.setCamera(camera, animated: true)
            mapViewType = "SatelliteFlyover"
            
        } else {
            
            let camera = MKMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: distance2, pitch: pitch2, heading: heading2)
            mapView.mapType = .hybridFlyover
            mapView.showsBuildings = true
            mapView.setCamera(camera, animated: true)
            mapViewType = "HybridFlyover"
        }
        
    }
    
    // Start Button for drawing the route
    @IBAction func Reset(_ sender: Any) {
        // This is the start-button and also stores the starting point coordinates:
        refreshView()
        // Mark the Starting Location for App:
        if let sourceCoord = manager.location?.coordinate {
            let lat = sourceCoord.latitude
            let long = sourceCoord.longitude
            sourceLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
        }
        
    }
    
    // use the start and final coords for plotting the route
    @IBAction func endDrawPath(_ sender: Any) {
        
        drawMapPath()
        
    }
    
    // using Progress View for speedBar Display:
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressViewDist: UIProgressView!
    @IBOutlet weak var mapView: MKMapView!
    
    
    
    // Button for centering the user location
    @IBAction func centerLocation(_ sender: UIButton) {
        
        if let coord = manager.location?.coordinate {
            //
            switch mapViewType {
            case "Standard2D":
                let camera = MKMapCamera(lookingAtCenter: coord, fromDistance: distance1, pitch: pitch1, heading: heading1)
                mapView.mapType = .standard
                mapView.showsBuildings = true
                mapView.setCamera(camera, animated: true)
            case "Satellite2D":
                let camera = MKMapCamera(lookingAtCenter: coord, fromDistance: distance1, pitch: pitch1, heading: heading1)
                mapView.mapType = .satellite
                mapView.showsBuildings = true
                mapView.setCamera(camera, animated: true)
            case "Hybrid2D":
                let camera = MKMapCamera(lookingAtCenter: coord, fromDistance: distance1, pitch: pitch1, heading: heading1)
                mapView.mapType = .hybrid
                mapView.showsBuildings = true
                mapView.setCamera(camera, animated: true)
            case "StandardFlyover":
                let camera = MKMapCamera(lookingAtCenter: coord, fromDistance: distance2, pitch: pitch2, heading: heading2)
                mapView.showsBuildings = true
                mapView.setCamera(camera, animated: true)
                mapView.mapType = .standard
            case "SatelliteFlyover":
                let camera = MKMapCamera(lookingAtCenter: coord, fromDistance: distance2, pitch: pitch2, heading: heading2)
                mapView.showsBuildings = true
                mapView.setCamera(camera, animated: true)
                mapView.mapType = .satelliteFlyover
            case "HybridFlyover":
                let camera = MKMapCamera(lookingAtCenter: coord, fromDistance: distance2, pitch: pitch2, heading: heading2)
                mapView.showsBuildings = true
                mapView.setCamera(camera, animated: true)
                mapView.mapType = .hybridFlyover
            default:
                print("No selection")
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup CLLocationManager:
        
        manager.delegate = self
        mapView.delegate = self
        
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        //manager.requestAlwaysAuthorization()
        manager.allowsBackgroundLocationUpdates = true
        //manager.startUpdatingLocation()
        /*
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.requestWhenInUseAuthorization()
            //manager.requestAlwaysAuthorization()
            manager.allowsBackgroundLocationUpdates = true
            manager.startUpdatingLocation()
            
            mapView.showsUserLocation = true
            mapView.showsCompass = true
            mapView.showsScale = true
            mapView.showsBuildings = true
            mapView.showsPointsOfInterest = true
            
            
        } else {
            
            manager.requestWhenInUseAuthorization()
            
        }
        */
        // Makes the progressView Bar thicker
        self.progressView.transform = CGAffineTransform(scaleX: 1.0, y: 6.0)
        self.progressViewDist.transform = CGAffineTransform(scaleX: 1.0, y: 6.0)
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        locationAuthStatus()
        
    }
    
    func locationAuthStatus() {
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            
            manager.startUpdatingLocation()
            mapView.showsUserLocation = true
            
            let alertController = UIAlertController (title: "Title", message: "GoHike is Using your GPS Location. Go to Settings to Turn Off and Exit GoHike?", preferredStyle: .alert)
            
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                    return
                }
                
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        print("Settings opened: \(success)") // Prints true
                    })
                }
            }
            alertController.addAction(settingsAction)
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true, completion: nil)
            
        } else {
            
            let alertController = UIAlertController (title: "Title", message: "GoHike Needs to Know your GPS Location. Go to Settings to Turn On?", preferredStyle: .alert)
            
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                    return
                }
                
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        print("Settings opened: \(success)") // Prints true
                    })
                }
            }
            alertController.addAction(settingsAction)
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true, completion: nil)
            
            
            manager.requestWhenInUseAuthorization()
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == .authorizedWhenInUse {
            
            mapView.showsUserLocation = true
            mapView.showsCompass = true
            mapView.showsScale = true
            mapView.showsBuildings = true
            mapView.showsPointsOfInterest = true
            
        } else {
            
            manager.requestWhenInUseAuthorization()
            
        }
    }
    
    
    func drawMapPath () {
        
        
        
        // 1. This function will draw the walking path of app.
        
        if let destinationCoord = manager.location?.coordinate {
            let lat = destinationCoord.latitude
            let long = destinationCoord.longitude
            destinationLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
        }
        
        // in case the 'stop' button is pressed first by mistake
        if sourceLocation == nil {
            sourceLocation = destinationLocation
        }
        
        
        // 3.
        let sourcePlacemark = MKPlacemark(coordinate:sourceLocation,addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate:destinationLocation, addressDictionary: nil)
        
        // 4.
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        // 5.
        let sourceAnnotation = MKPointAnnotation()
        sourceAnnotation.title = "Start"
        
        if let location = sourcePlacemark.location {
            sourceAnnotation.coordinate = location.coordinate
        }
        
        
        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.title = "End"
        
        if let location = destinationPlacemark.location {
            destinationAnnotation.coordinate = location.coordinate
        }
        
        // 6.
        self.mapView.addAnnotations([sourceAnnotation,destinationAnnotation])
        //self.mapView.showAnnotations([sourceAnnotation,destinationAnnotation], animated: false )
        
        // 7.
        let directionRequest = MKDirectionsRequest()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        //directionRequest.transportType = .automobile
        //directionRequest.transportType = .any
        directionRequest.transportType = .walking
        // Calculate the direction
        let directions = MKDirections(request: directionRequest)
        
        // 8.
        directions.calculate {
            (response, error) -> Void in
            
            guard let response = response else {
                if let error = error {
                    print("Error: \(error)")
                }
                
                return
            }
            
            let route = response.routes[0]
            self.mapView.add((route.polyline), level: MKOverlayLevel.aboveRoads)
            
            let camera = MKMapCamera(lookingAtCenter: self.destinationLocation, fromDistance: self.distance3, pitch: self.pitch1, heading: self.heading1)
            self.mapView.mapType = .standard
            self.mapView.showsBuildings = true
            self.mapView.setCamera(camera, animated: true)
        }
        
        sourceLocation = destinationLocation
        
    }
    
    // mapView extended function used for drawMapPath() above:
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.red
        renderer.lineWidth = 4.0
        
        return renderer
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        
        // 1. dist method using (speed * time)
        
        let location = locations[0]
        //print("location = \(location)")
        
        if location.speed >= 0.0 {
            
            runSpeed = location.speed*(2.236) // converted to miles/hour
            
            //print("runSpeed = \(runSpeed)")
            // Using iOS Progress View Bar to plot speed instead of CorePlot
            // max speed scale = 12 miles/hr
            progressView.setProgress(Float(runSpeed/10), animated: true)
            
        }
        // set map to center and focus on your location
        // use if loop to update map just 5 times
        
        if updateCount < 10 {
            
            // constants for openweathermap.org to get weather conditions /////////////////
            // call the getWeather function:
            
            let latit = location.coordinate.latitude
            let longit = location.coordinate.longitude
            
            DispatchQueue.main.async {
                self.getWeather(latit: latit, longit: longit)
            }
            
            /////////////////////////////////////////////////////////////
            
            // let nycLocation = CLLocationCoordinate2D(latitude: 40.731302, longitude: -73.997065)
            
            //print("manager.location?.coordinate = \(String(describing: manager.location?.coordinate))")
            /*
            let region = MKCoordinateRegionMakeWithDistance((manager.location?.coordinate)!, 1000, 1000)
            mapView.setRegion(region, animated: false)
 */
            if let coord = manager.location?.coordinate {
                let camera = MKMapCamera(lookingAtCenter: coord, fromDistance: distance2, pitch: pitch2, heading: heading2)
                mapView.mapType = .satelliteFlyover
                mapView.showsBuildings = true
                mapView.setCamera(camera, animated: false)
                
                updateCount += 1
            }
        }
        
        // 2. dist method using distance between two locations
        if startLocation == nil {
            startLocation = locations.first!
            
        } else {
            let lastLocation = locations.last!
            let distance = startLocation.distance(from: lastLocation)
            var progressBarPercent = 0.0
            if distance > 0.0 {
                
                totalDistanceMeters2 += distance
                mapDrawingDistance += distance
                let mapDrawDistanceMiles = mapDrawingDistance * 0.0006214
                //self.totalDistMiles2.text = String(format: "%.4f",(totalDistanceMeters2 * 0.0006214))
                progressBarPercent = ((totalDistanceMeters2 * 0.0006214)/10)
                progressViewDist.setProgress(Float(progressBarPercent), animated: true)
                
                // place a pin every 0.2 miles increment:
                if mapDrawDistanceMiles >= 0.2 {
                    if let coord = self.manager.location?.coordinate {
                        let placeMarker = MKPointAnnotation()
                        placeMarker.coordinate = coord
                        self.mapView.addAnnotation(placeMarker)
                        mapDrawingDistance = 0.0
                    }
                }
                
                
                
                // setup pinning placemarkers along path every 0.2 miles:
                /*
                 // Below code will add a marker at user location every 5 sec.
                 Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { (timer) in
                 if let coord = self.manager.location?.coordinate {
                 let placeMarker = MKPointAnnotation()
                 placeMarker.coordinate = coord
                 self.mapView.addAnnotation(placeMarker)
                 }
                 })
                 */
                
                
            }
            
            startLocation = lastLocation
        }
        
    }
    
    func getWeather(latit:Double,longit:Double) {
        
        // setup url from the latit and longit coordinates
        let url = URL(string: "http://api.openweathermap.org/data/2.5/weather?lat=\(latit)&lon=\(longit)&appid=8c93be12eb4dc96a11f5fffdd66eef37")!
        
        // creating a task from url to get content of url
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            if error != nil {
                
                // all UI updates should run on main-thread
                DispatchQueue.main.async {
                    print(error!)
                }
                
                
            } else {
                
                // check if we can get data
                if let urlContent = data {
                    
                    // all UI updates should run on main-thread
                    DispatchQueue.main.async {
                        do {
                            
                            // if data exist, process with JSON
                            let jsonResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableContainers)
                            
                            // if processing successful, print the swift array with the contents
                            //print(jsonResult)
                            
                            if let cityName = (jsonResult as AnyObject)["name"] {
                                self.citiName.text = " " + (cityName as? String)!
                                //print(cityName!)
                            }
                            
                            
                            if let weatherDict = (jsonResult as AnyObject)["weather"] {
                                // use [AnyObject] Array since it will use subscript [index] = [0]
                                // using just AnyObject will not work, have to define as an array object
                                let weatherCondition = (weatherDict as! [AnyObject])[0]["main"]!!
                                //print(weatherCondition)
                                self.weatherType.text = " " + (weatherCondition as? String)!
                            }
                            
                            
                            // currentTemp: ºF = 1.8 x (K - 273) + 32.
                            
                            if let preTemp = (((jsonResult as AnyObject)["main"]) as! [String:AnyObject])["temp"] {
                                let currentTemp = (1.8 * ((preTemp as! Double) - 273.0)) + 32.0
                                self.tempurature.text = " " + String(format: "%.2f", currentTemp) + " ℉"
                                //print(currentTemp)
                            }
                            
                        } catch {
                            
                            print("JSON Processing Failed")
                            
                        }
                    }
                    
                }
            }
        }
        
        task.resume()
        
    }
    
    func refreshView() ->() {
        
        // Reset to total distance to 0.0 onthe distance-bar
        totalDistanceMeters2 = 0.0
        
    }
    
}
