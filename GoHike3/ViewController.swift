//
//  ViewController.swift
//  GoHike
//
//  Created by James Chen on 5/8/17.
//  Copyright © 2017 jmchen. All rights reserved.
//
//  This is the Final Version of GoHike as of 6/21/17

// Comments to Fix
/*
 1. The 3Dview button doesn't do anything if the app is in Hybrid or Standard mode.  Perhaps a better approach would be to use a UISegmentedControl.  Probably you should have four options:  Standard, 3D, Satellite, and Hybrid.  One advantage of using a UISegmentedControl is that it would make it obvious which option is currently selected, which your current approach doesn't really do.
 
 2. Your app should be able to handle a situation where a user does not allow the app to use its location.  Right now, the app just keeps trying as if everything is fine.  If the user does not allow the app to access the device's location, you should make it clear that the user must go to settings to allow this.  This is low priority until you have more of your features done, but this is going to be important for your finished app.
 */



import UIKit
import CoreLocation
import MapKit


class ViewController: UIViewController,CLLocationManagerDelegate,MKMapViewDelegate {
    
    // constants below are the camera settings
    let distance: CLLocationDistance = 400
    let pitch: CGFloat = 60
    let heading = 90.0
    
    
    var sourceLocation: CLLocationCoordinate2D!
    var destinationLocation: CLLocationCoordinate2D!
    var mapViewType = "Standard"
    var manager = CLLocationManager()
    var totalDistanceMeters2:Double = 0.0
    var preTimeInterval = 0.0
    var startLocation: CLLocation!
    var lastLocation: CLLocation!
    var updateCount = 0
    var runSpeed: Double = 0.000
    
    // Label for OpenWeatherMap data:
    @IBOutlet weak var citiName: UILabel!
    @IBOutlet weak var tempurature: UILabel!
    @IBOutlet weak var weatherType: UILabel!
    
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
        
        // use Timer to try to allow for drawing a circular route where coord(i) == coord(f)
        /*
        Timer.scheduledTimer(withTimeInterval: <#T##TimeInterval#>, repeats: <#T##Bool#>) { (<#Timer#>) in
            <#code#>
        }
        */
    }
    
    // use the start and final coords for plotting the route
    @IBAction func endDrawPath(_ sender: Any) {
        
        drawMapPath()
        
    }
    
    // using Progress View for speedBar Display:
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressViewDist: UIProgressView!
    @IBOutlet weak var mapView: MKMapView!
    
    // setting for the 2D button
    @IBAction func changeMapType(_ sender: UIButton) {
        
        mapViewType = "Standard"
        
        if let coord = manager.location?.coordinate {
            let region = MKCoordinateRegionMakeWithDistance(coord, 1000, 1000)
            mapView.setRegion(region, animated: true)
        }
        
        let title = sender.titleLabel?.text
        
        switch title!{
        case "Satellite":
            mapView.mapType = .satellite
            sender.setTitle("Hybrid", for: .normal)
        case "Hybrid":
            mapView.mapType = .hybrid
            sender.setTitle("Standard", for: .normal)
        case "Standard":
            mapView.mapType = .standard
            sender.setTitle("Satellite", for: .normal)
        default:
            mapView.mapType = .standard
            sender.setTitle("Sat Fly", for: .normal)
            
        }
    }
    // setting for the 3D button
    @IBAction func flyoverMap(_ sender: UIButton) {
        
        let title = sender.titleLabel?.text
        
        switch title!{
        case "Satellite3D":
            let camera = MKMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: distance, pitch: pitch, heading: heading)
            mapView.mapType = .satelliteFlyover
            mapView.showsBuildings = true
            mapView.setCamera(camera, animated: true)
            mapViewType = "SatelliteFlyover"
            sender.setTitle("Hybrid3D", for: .normal)
            break
        case "Hybrid3D":
            let camera = MKMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: distance, pitch: pitch, heading: heading)
            mapView.mapType = .hybridFlyover
            mapView.showsBuildings = true
            mapViewType = "HybridFlyover"
            mapView.setCamera(camera, animated: true)
            sender.setTitle("Standard3D", for: .normal)
            break
        case "Standard3D":
            let camera = MKMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: distance, pitch: pitch, heading: heading)
            mapView.mapType = .standard
            mapView.showsBuildings = true
            mapView.setCamera(camera, animated: true)
            mapViewType = "StandardFlyover"
            sender.setTitle("Satellite3D", for: .normal)
            break
        default:
            mapView.mapType = .standard
            sender.setTitle("Sat Fly", for: .normal)
            break
        }
        
    }
    
    // Button for centering the user location
    @IBAction func centerLocation(_ sender: UIButton) {
        
        if let coord = manager.location?.coordinate {
            //
            switch mapViewType {
            case "Standard":
                let region = MKCoordinateRegionMakeWithDistance(coord, 1000, 1000)
                mapView.setRegion(region, animated: true)
            case "StandardFlyover":
                let camera = MKMapCamera(lookingAtCenter: coord, fromDistance: distance, pitch: pitch, heading: heading)
                mapView.showsBuildings = true
                mapView.setCamera(camera, animated: true)
                mapView.mapType = .standard
            case "SatelliteFlyover":
                let camera = MKMapCamera(lookingAtCenter: coord, fromDistance: distance, pitch: pitch, heading: heading)
                mapView.showsBuildings = true
                mapView.setCamera(camera, animated: true)
                mapView.mapType = .satelliteFlyover
            case "HybridFlyover":
                let camera = MKMapCamera(lookingAtCenter: coord, fromDistance: distance, pitch: pitch, heading: heading)
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
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.requestWhenInUseAuthorization()
            //manager.requestAlwaysAuthorization()
            manager.startUpdatingLocation()
            
            mapView.showsUserLocation = true
            mapView.showsCompass = true
            mapView.showsScale = true
            mapView.showsBuildings = true
            mapView.showsPointsOfInterest = true
            
            // Makes the progressView Bar thicker
            self.progressView.transform = CGAffineTransform(scaleX: 1.0, y: 6.0)
            self.progressViewDist.transform = CGAffineTransform(scaleX: 1.0, y: 6.0)
            
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
        self.mapView.showAnnotations([sourceAnnotation,destinationAnnotation], animated: false )
        
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
            
            let region = MKCoordinateRegionMakeWithDistance(self.sourceLocation, 2000, 2000)
            self.mapView.setRegion(region, animated: true)
            
            //let rect = route.polyline.boundingMapRect
            //self.mapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
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
            let region = MKCoordinateRegionMakeWithDistance((manager.location?.coordinate)!, 1000, 1000)
            mapView.setRegion(region, animated: false)
            updateCount += 1
            
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
                //self.totalDistMiles2.text = String(format: "%.4f",(totalDistanceMeters2 * 0.0006214))
                progressBarPercent = ((totalDistanceMeters2 * 0.0006214)/10)
                progressViewDist.setProgress(Float(progressBarPercent), animated: true)
                
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
