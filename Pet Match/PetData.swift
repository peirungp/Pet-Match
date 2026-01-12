//
//  PetData.swift
//  Pet Match
//
//  Created by Pei-Rung Pan on 11/12/25.
//

import Foundation
import UIKit

struct PetData {
    let id: String
    let name: String
    let age: String
    let sex: String
    let location: String
    let animalType: String
    let breed: String
    let size: String
    let specialNeeds: String
    let description: String
    let imageUrl: String?
    var image: UIImage? {
        return nil
    }
    
    let shelterName: String
    let shelterPhone: String
    let shelterAddress: String
    
    let shelterId: String?
    
    init(from dict: [String: Any]) {
        self.id = dict["id"] as? String ?? ""
        self.name = dict["name"] as? String ?? "Unknown"
        self.age = dict["age"] as? String ?? ""
        self.sex = dict["sex"] as? String ?? ""
        self.location = dict["location"] as? String ?? ""
        self.animalType = dict["animalType"] as? String ?? ""
        self.breed = dict["breed"] as? String ?? ""
        self.size = dict["size"] as? String ?? ""
        self.specialNeeds = dict["specialNeeds"] as? String ?? ""
        self.description = dict["description"] as? String ?? ""
        self.imageUrl = dict["imageUrl"] as? String
        
        self.shelterName = dict["shelterName"] as? String ?? "Unknown Shelter"
        self.shelterPhone = dict["shelterPhone"] as? String ?? "No phone"
        self.shelterAddress = dict["shelterAddress"] as? String ?? "self.location"
        
        self.shelterId = dict["shelterId"] as? String
        
    }
}
