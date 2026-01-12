//
//  MapInfoViewController.swift
//  Pet Match
//
//  Created by Pei-Rung Pan on 11/5/25.
//

import UIKit
import MapKit
import CoreLocation

class MapInfoViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var shelterNameLabel: UILabel!
    @IBOutlet weak var shelterAddressLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var directionsButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    
    var petName: String?
    var petLocation: String?
    var shelterName: String?
    var shelterPhone: String?
    var shelterAddress: String?

    private let geocoder = CLGeocoder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = petName ?? "Location"
    
        map()
        displayShelterInfo()
        setupBackgroundImageViewController()
    }
    
    
    @IBAction func onDirections(_ sender: UIButton) {

        guard let address = shelterAddress else {
            return displayMessage("Error", "No address available.")
        }

        openDirectionsMaps(address: address)
    }
    
    private func map() {
        
     if mapView == nil {
         displayMessage("Error", "Map loading failed.")
         return
     }
                         
     if let location = petLocation {
         showLocation(address: location)
     } else {
         displayMessage("Error", "No address available")
     }
    }
    
    private func openDirectionsMaps(address: String) {
        geocoder.geocodeAddressString(address) { [weak self] placemarks, error in
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                return
            }
 
            let coordinate = location.coordinate

            let map = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
            map.name = self?.shelterName ?? "Shelter"
        
            let launchOptions =  [ MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        
            map.openInMaps(launchOptions: launchOptions)

        }
    }
    
    
    @IBAction func onCall(_ sender: UIButton) {
        guard let phoneNum = shelterPhone else {
            return displayMessage("Error", "No phone number available.")
        }
        openPhoneOptions(phoneNumber: phoneNum)
    
    }
    
    private func openPhoneOptions(phoneNumber: String) {
        let alert = UIAlertController(
            title: shelterName ?? "Shelter",
            message: phoneNumber,
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Call \(phoneNumber)", style: .default) { [weak self] _ in self?.openPhone(phoneNumber: phoneNumber)
            
        })
        
        alert.addAction(UIAlertAction(title: "Copy Number", style: .default) { _ in UIPasteboard.general.string = phoneNumber
            self.displayMessage("Success", "Phone number copied.")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func openPhone(phoneNumber: String) {
        let onlyNum = phoneNumber.filter { $0.isNumber }
        guard !onlyNum.isEmpty else {
            return displayMessage("Error", "Invalid phone number.")
        }
        
        guard let url = URL(string: "telprompt://\(onlyNum)") else {
            return displayMessage("Error", "Invalid phone number.")
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:])
        } else {
            displayMessage("Error", "Failed to open phone.")
        }
    }
    
    
    private func displayShelterInfo() {
        shelterNameLabel?.text = "🏠 Shelter: \(shelterName ?? "Unknown Shelter")"
        phoneLabel?.text = "📞 Phone: \(shelterPhone ?? "No phone available")"
        shelterAddressLabel?.text = "📍 Address: \(shelterAddress ?? "No address available")"
    }
    
    private func showLocation(address: String) {
          
          geocoder.geocodeAddressString(address) { [weak self] placemarks, error in
              if let error = error {
                  self?.displayMessage("Error", "No address available")
                  return
              }
              
              guard let placemark = placemarks?.first,
                    let location = placemark.location else {
                  self?.displayMessage("Error", "No address available")
                  return
              }
              
              self?.addAnnotation(at: location.coordinate, title: address)
              self?.centerMap(on: location.coordinate)
          }
    }
      
    private func addAnnotation(at coordinate: CLLocationCoordinate2D, title: String) {
          let annotation = MKPointAnnotation()
          annotation.coordinate = coordinate
          annotation.title = petName ?? "Pet Location"
          annotation.subtitle = title
          mapView.addAnnotation(annotation)
    }
      
    private func centerMap(on coordinate: CLLocationCoordinate2D) {
          let region = MKCoordinateRegion(
              center: coordinate,
              latitudinalMeters: 2000,
              longitudinalMeters: 2000
          )
          mapView.setRegion(region, animated: true)
    }
      
    func displayMessage(_ title: String, _ message: String) {
          let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
              self?.navigationController?.popViewController(animated: true)
          })
          present(alert, animated: true)
    }

}
