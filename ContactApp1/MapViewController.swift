import UIKit
import MapKit
import CoreLocation
import CoreData

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    var locationManager: CLLocationManager!
    
    @IBOutlet weak var mapView: MKMapView!
    var contacts: [Contact] = []
    
    @IBOutlet weak var sgmtMapType: UISegmentedControl!
    
    @IBAction func mapTypeChanged(_ sender: UISegmentedControl) {
        switch sgmtMapType.selectedSegmentIndex {
        case 0:
            mapView.mapType = .standard
        case 1:
            mapView.mapType = .hybrid
        case 2:
            mapView.mapType = .satellite
        default:
            break
        }
    }
    func processAddressResponse(_ contact: Contact, withPlacemarks placemarks: [CLPlacemark]?, error: Error?) {
        if let error = error {
            print("Geocoding error: \(error.localizedDescription)")
            return
        }
        
        guard let placemarks = placemarks, let location = placemarks.first?.location else {
            print("No location found for contact: \(contact.streetAddress ?? "unknown")")
            return
        }
        
        let mp = MapPoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        mp.title = "\(contact.contactName ?? "")"
        mp.subtitle = "\(contact.streetAddress ?? ""), \(contact.city ?? "") \(contact.state ?? "") \(contact.email ?? "")"
        
        DispatchQueue.main.async {
            self.mapView.addAnnotation(mp)
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest<NSManagedObject>(entityName: "Contact")
        var fetchedObjects: [NSManagedObject] = []
        do {
            fetchedObjects = try context.fetch(request)
        } catch let error as NSError {
            print("Could not fetch: \(error)")
        }
        
        contacts = fetchedObjects as! [Contact]
        self.mapView.removeAnnotations(self.mapView.annotations)
        for contact in contacts {
            let address = "\(contact.streetAddress!), \(contact.city!) \(contact.state!)"
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(address) { (placemarks, error) in
                self.processAddressResponse(contact, withPlacemarks: placemarks, error: error)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        mapView.delegate = self  //
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(.follow, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            print("Permission Granted")
        } else {
            print("Permission NOT granted")
        }
    }
    
    private var hasZoomedToUser = false

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if !hasZoomedToUser {
            let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
            let viewRegion = MKCoordinateRegion(center: userLocation.coordinate, span: span)
            mapView.setRegion(viewRegion, animated: true)
            hasZoomedToUser = true
        }

        let mp = MapPoint(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        mp.title = "You"
        mp.subtitle = "Are Here"
        mapView.addAnnotation(mp)
    }
    }

