//
//  ViewController.swift
//  MobycyTask
//
//  Created by gaurav on 15/05/19.
//  Copyright © 2019 gaurav. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    let locationManager = CLLocationManager()
    let regionInMetre: Double = 1000
    var previousLocation: CLLocationCoordinate2D?
    var lastLocation : CLLocationCoordinate2D?
    var directionsArray : [MKDirections] = []
    var places = [Place]()
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.isHidden = true
        checkLoactionServices()
        let place1 = Place(title: "Pin: 122002", coordinate: CLLocationCoordinate2D(latitude: 28.474680, longitude: 77.104897))
        let place2 = Place(title: "Pin: 122003", coordinate: CLLocationCoordinate2DMake(28.442125, 77.065201))
        let place3 = Place(title: "Pin: 122005",coordinate: CLLocationCoordinate2D(latitude: 28.436226, longitude: 77.030540))
        let place4 = Place(title: "Pin: 122008", coordinate: CLLocationCoordinate2D(latitude: 28.480770, longitude: 77.085892))
        places = [place1,place2,place3,place4]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        checkLoactionServices()
    }
    
    @IBAction func startButtonPressed(_ sender: Any) {
        locationManager.startUpdatingLocation()
        previousLocation = locationManager.location?.coordinate
    }
    
    @IBAction func stopButtonPressed(_ sender: Any) {
        locationManager.stopUpdatingLocation()
        getTotalDistanceCovered()
    }
    
    func getTotalDistanceCovered()
    {
        guard let prevLocation = previousLocation else {return}
        guard let lasLocation = lastLocation else {return}
        let request = createDirectionRequest(previousLocation: prevLocation, lastLocation: lasLocation)
        let direction = MKDirections(request: request)
        direction.calculate { [unowned self](response, error) in
            guard let response = response else {return}
            
            for route in response.routes
            {
                let distance = route.distance
                self.showAlert(title: "Congrats", message: "Total Distance covered is:\(distance) meters")
            }
        }
    }
    
    func addPolygon()
    {
        var locations = places.map { $0.coordinate }
        let polygon = MKPolygon(coordinates: &locations, count: locations.count)
        mapView?.addOverlay(polygon)
    }
    
    func getDirections()
    {
        guard let prevLocation = previousLocation else {return}
        guard let lasLocation = lastLocation else {return}
        let request = createDirectionRequest(previousLocation: prevLocation, lastLocation: lasLocation)
        let direction = MKDirections(request: request)
        direction.calculate { [unowned self](response, error) in
            guard let response = response else {return}
            
            for route in response.routes
            {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
        
    }
    
    func createDirectionRequest(previousLocation : CLLocationCoordinate2D,lastLocation : CLLocationCoordinate2D) -> MKDirections.Request
    {
        let startLocation = MKPlacemark(coordinate: previousLocation)
        let destination = MKPlacemark(coordinate: lastLocation)
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        return request
        
        
    }
    
    func resetMapView(withNew direction: MKDirections)
    {
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(direction)
        let _ = directionsArray.map { $0.cancel() }
        directionsArray.removeAll()
    
    }
    
    func centreViewOnUserLocation()
    {
        if let location = locationManager.location?.coordinate
        {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMetre, longitudinalMeters: regionInMetre)
            mapView.setRegion(region, animated: true)
        }
        addPolygon()
    }
    
    func setUpLocationManager()
    {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func showAlert(title:String,message : String)
    {
        let Alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        Alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        DispatchQueue.main.async {
            self.present(Alert, animated: true, completion: nil)
        }
    }
    
    func checkLocationAuthorization()
    {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            centreViewOnUserLocation()
            break
        case .denied:
            showAlert(title: "OOPS", message: "Please enable your location from setting")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            showAlert(title: "OOPS", message: "Locations is restricted")
        case .authorizedAlways:
            break
        default:
            break
        }
    }
    
    func checkLoactionServices()
    {
        if CLLocationManager.locationServicesEnabled()
        {
            setUpLocationManager()
            checkLocationAuthorization()
        }
        else
        {
            showAlert(title: "OOPS", message: "Please enable your location from setting")
        }
    }
    
}

extension ViewController : CLLocationManagerDelegate
{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else { return }
        let centre = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion.init(center: centre, latitudinalMeters: regionInMetre, longitudinalMeters: regionInMetre)
        mapView.setRegion(region, animated: true)
        lastLocation = locationManager.location?.coordinate
        getDirections()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
    
}

extension ViewController : MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is MKPolyline
        {
            let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
            renderer.strokeColor = .blue
            return renderer
        }
        else if overlay is MKPolygon
        {
            let renderer = MKPolygonRenderer(overlay: overlay as! MKPolygon)
            renderer.strokeColor = UIColor.orange
            renderer.fillColor = UIColor.black.withAlphaComponent(0.5)
            renderer.lineWidth = 2
            return renderer
        }
        return MKOverlayRenderer()
    }
}

class Place: NSObject {
    var title: String?
    var coordinate: CLLocationCoordinate2D
    
    init(title: String?, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.coordinate = coordinate
}
}
