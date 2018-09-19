

import UIKit
import GoogleMaps
import GooglePlaces

 

import CoreLocation



import SQLite
import SQLite3


struct Novella {
    let id:Int
    let name: String
    let lat: Double
    let lon: Double
    let detail: String
    let count: String
    let ap: String
    let finished:Bool
}


struct Novellas {
    let novellas: [Novella]
}


struct NovellasIterator: IteratorProtocol {
    
    private var current = 0
    private let novellas: [Novella]
    
    init(novellas: [Novella]) {
        self.novellas = novellas
    }
    
    
    mutating func next() -> Novella? {
        defer {
            current += 1  
        }
       
        return novellas.count > current ? novellas[current] : nil
    }
}

//将小说集合遵循Swift序列协议
extension Novellas: Sequence {
    //实现协议方法(制作一个小说迭代器)
    func makeIterator() -> NovellasIterator {
        return NovellasIterator(novellas: novellas)
    }
}



let greatNovellas = Novellas(novellas:)


 

import UIKit
import GoogleMaps
import GooglePlaces
import CoreLocation
import Alamofire

class MapViewController: UIViewController,GMSMapViewDelegate {
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var mapView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var zoomLevel: Float = 15.0
    
    // An array to hold the list of likely places.
    var likelyPlaces: [GMSPlace] = []
    
    // The currently selected place.
    var selectedPlace: GMSPlace?
    
    // A default location to use when location permission is not granted.
    let defaultLocation = CLLocation(latitude: -33.869405, longitude: 151.199)
    
   
    var gameTimer: Timer!
    
    var addresses = [String]()
    
    let path = GMSMutablePath()
    
    let timeInterval:Float=5
    
    var lastLat:Double=0
    var lastLog:Double=0
    
    
    let customMarkerWidth: Int = 50
    let customMarkerHeight: Int = 50
    
    var database: Connection!
    
    let usersTable = Table("location")
    let lat = Expression<String>("lat")
    let lon = Expression<String>("lon")
    let itime = Expression<String>("itime")
    
 
    
    
    // Update the map once the user has made their selection.
    @IBAction func unwindToMain(segue: UIStoryboardSegue) {
        // Clear the map.
        mapView.clear()
        
        // Add a marker to the map.
        if selectedPlace != nil {
            let marker = GMSMarker(position: (self.selectedPlace?.coordinate)!)
            marker.title = selectedPlace?.name
            marker.snippet = selectedPlace?.formattedAddress
            marker.map = mapView
        }
        
        //listLikelyPlaces(marker)
    }
    
    func createTable() {
        print("CREATE TAPPED")
        
        let createTable = self.usersTable.create { (table) in
            table.column(self.lat)
            table.column(self.lon)
            table.column(self.itime, unique: true)
        }
        
        do {
            try self.database.run(createTable)
            print("Created Table")
        } catch {
            print(error)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileUrl = documentDirectory.appendingPathComponent("users").appendingPathExtension("sqlite3")
            let database = try Connection(fileUrl.path)
            self.database = database
            let table=Table("")
            
        } catch {
            print(error)
        }
        do {
            try database.scalar(usersTable.exists)
        } catch{
            createTable()
        }
        
        let users = try! database.prepare(usersTable.select(lat,lon).order(itime.asc))
        for user in  users{
            //print("id: \(user[self.lat]), name: \(user[self.lon])")
            path.add(CLLocationCoordinate2D(latitude: Double(user[lat])!, longitude: Double(user[lon])!))
            let polyline = GMSPolyline(path: path)
            polyline.map = mapView
            
        }
        
        
        print("haha")
        gameTimer = Timer.scheduledTimer(timeInterval: TimeInterval(timeInterval), target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)
        
      
        
        
        // Initialize the location manager.
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        //locationManager.startUpdatingLocation()
        
        locationManager.delegate = self
        
        placesClient = GMSPlacesClient.shared()
        
        // Create a map.
        let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude,
                                              longitude: defaultLocation.coordinate.longitude,
                                              zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        mapView.settings.rotateGestures=false
        
        // Add the map to the view, hide it until we've got a location update.
        view.addSubview(mapView)
        mapView.isHidden = true
        
        
        if mapView.isHidden {
            mapView.isHidden = false
            mapView.camera = camera
        } else {
            mapView.animate(to: camera)
        }
        
        mapView.delegate = self
        
        // Creates a marker in the center of the map.
        for novella in greatNovellas {
            print("I 've read: \(novella)")
            
            let marker = GMSMarker()
            let customMarker = CustomMarkerView(frame: CGRect(x: 0, y: 0, width: customMarkerWidth, height: customMarkerHeight), image: #imageLiteral(resourceName: "map_Pin"), borderColor: UIColor.darkGray, pc: novella.name,s1:novella.count,s2:novella.ap)
            marker.iconView=customMarker
            marker.position = CLLocationCoordinate2D(latitude:novella.lat , longitude: novella.lon)
            
            marker.title = novella.name
            marker.snippet = novella.detail
            marker.map = mapView
            //marker.icon = GMSMarker.markerImage(with: .black)
            print("a")
        }
        print("a")
        //listLikelyPlaces(marker)
    }
    
    // Populate the array with the list of likely places.
    func listLikelyPlaces(marker: GMSMarker) {
        
        print(type(of:marker.snippet))
        print(marker.snippet ?? "")
        //let str = "Andrew, Ben, John, Paul, Peter, Laura"
       
        let str = marker.snippet as! String
        addresses = str.components(separatedBy: ",")
        print(addresses)
        // Clean up from previous sessions.
        likelyPlaces.removeAll()
        
        placesClient.currentPlace(callback: { (placeLikelihoods, error) -> Void in
            if let error = error {
                // TODO: Handle the error.
                print("Current Place error: \(error.localizedDescription)")
                return
            }
            
            // Get likely places and add to the list.
            if let likelihoodList = placeLikelihoods {
                for likelihood in likelihoodList.likelihoods {
                    let place = likelihood.place
                    self.likelyPlaces.append(place)
                }
            }
        })
    }
    
    // Prepare the segue.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToSelect" {
            if let nextViewController = segue.destination as? PlacesViewController {
                nextViewController.likelyPlaces = likelyPlaces
                nextViewController.addresses = addresses
            }
        }
    }
    func buttonAction(_ sender:UIButton!)
    {
        print("Button tapped")
    }
    func runTimedCode()
    {
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        
        
        locationManager.delegate = self
        
        locationManager.startUpdatingLocation()
      
        
        
    }
    
    
   func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        print("aa tapped")
      
    
    
        // tap event handled by delegate
        return false
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        print("infowindow tapped")
   
       
        listLikelyPlaces(marker: marker)
        
        //let vc = PlacesViewController()
        //vc.addresses = addresses
        
        //navigationController?.pushViewController(vc, animated: true)
        performSegue(withIdentifier: "segueToSelect", sender: self)
    }
    
   
    
   
}



// Delegates to handle events for the location manager.
extension MapViewController: CLLocationManagerDelegate {
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        let lat6=round(location.coordinate.latitude*1000000)/1000000
        let lon6=round(location.coordinate.longitude*1000000)/1000000
        print("Location: \(lat6) \(lon6) ,Distance")
        
        
        let coordinate0 = CLLocation(latitude: lastLat, longitude: lastLog)
        let coordinate1 = CLLocation(latitude:lat6, longitude:lon6)
        let distanceInMeters = coordinate0.distance(from: coordinate1)
        
        print("Location: \(lat6) \(lon6) ,Distance: \(distanceInMeters) ")
        
        if ((Float(distanceInMeters)/timeInterval)<10  ||  lastLat==0.0 ){
            path.add(CLLocationCoordinate2D(latitude: lat6, longitude: lon6))
            let polyline = GMSPolyline(path: path)
            polyline.map = mapView
            let date = Date()
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "yyy-MM-dd' 'HH:mm:ss.SSS"
            let strNowTime = timeFormatter.string(from: date) as String
            
            
            
            let insert=usersTable.insert(lat <- String(lat6), lon <- String(lon6), itime <- strNowTime)
            let rowid = try? database.run(insert)
        }
        lastLat=lat6
        lastLog=lon6
        
        //let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,longitude: location.coordinate.longitude,zoom: zoomLevel)
        
        //if mapView.isHidden {
        //    mapView.isHidden = false
        //    mapView.camera = camera
        //} else {
        //    mapView.animate(to: camera)
        //}
        
        
        
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
}

