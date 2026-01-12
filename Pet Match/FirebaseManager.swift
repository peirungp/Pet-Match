//
//  FirebaseManager.swift
//  Pet Match
//
//  Created by Ava Pan on 11/9/25.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import UIKit

class FirebaseManager {
    
    static let shared = FirebaseManager()

    private var imageLoading = NSCache<NSString, UIImage>()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    func fetchPets(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        db.collection("pets")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let pets = snapshot?.documents.map { doc -> [String: Any] in
                    var data = doc.data()
                    data["id"] = doc.documentID
                    return data
                } ?? []
                
                completion(.success(pets))
            }
    }
    
    func addPet(
        name: String,
        age: String,
        sex: String,
        location: String,
        image: UIImage? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        
        var petData: [String: Any] = [
            "name": name,
            "age": age,
            "sex": sex,
            "location": location,
            "animalType": "Dog",
            "breed": "Mixed",
            "size": "Medium",
            "specialNeeds": "None",
            "description": "",
            "isAdopted": false,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        let docRef = db.collection("pets").document()
        
        if let image = image {
            uploadPetImage(image, petId: docRef.documentID) { result in
                if case .success(let imageUrl) = result {
                    petData["imageUrl"] = imageUrl
                }
                
                docRef.setData(petData) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(docRef.documentID))
                    }
                }
            }
        } else {
            docRef.setData(petData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(docRef.documentID))
                }
            }
        }
    }
    
    func addPet(
        name: String,
        age: String,
        sex: String,
        location: String,
        animalType: String,
        breed: String,
        size: String,
        specialNeeds: String,
        description: String,
        shelterName: String,
        shelterPhone: String,
        shelterAddress: String,
        isAdopted: Bool,
        shelterId: String? = nil,
        image: UIImage? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        
        var petData: [String: Any] = [
            "name": name,
            "age": age,
            "sex": sex,
            "location": location,
            "animalType": animalType,
            "breed": breed,
            "size": size,
            "specialNeeds": specialNeeds,
            "description": description,
            "shelterName": shelterName,
            "shelterPhone": shelterPhone,
            "shelterAddress": shelterAddress,
            "isAdopted": false,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        if let shelterId = shelterId {
            petData["shelterId"] = shelterId
        }
        
        let docRef = db.collection("pets").document()
        
        if let image = image {
            uploadPetImage(image, petId: docRef.documentID) { result in
                if case .success(let imageUrl) = result {
                    petData["imageUrl"] = imageUrl
                }
                
                docRef.setData(petData) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(docRef.documentID))
                    }
                }
            }
        } else {
            docRef.setData(petData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(docRef.documentID))
                }
            }
        }
    }
    
    func updatePet(
        petId: String,
        name: String,
        age: String,
        sex: String,
        location: String,
        animalType: String,
        breed: String,
        size: String,
        specialNeeds: String,
        description: String,
        shelterName: String,
        shelterPhone: String,
        shelterAddress: String,
        shelterId: String? = nil,
        newImage: UIImage? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        var petData: [String: Any] = [
            "name": name,
            "age": age,
            "sex": sex,
            "location": location,
            "animalType": animalType,
            "breed": breed,
            "size": size,
            "specialNeeds": specialNeeds,
            "description": description,
            "shelterName": shelterName,
            "shelterPhone": shelterPhone,
            "shelterAddress": shelterAddress,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if let shelterId = shelterId {
            petData["shelterId"] = shelterId
        }
        
        if let newImage = newImage {
            uploadPetImage(newImage, petId: petId) { result in
                switch result {
                case .success(let imageUrl):
                    petData["imageUrl"] = imageUrl
                    self.updatePetData(petId: petId, data: petData, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            updatePetData(petId: petId, data: petData, completion: completion)
        }
    }

    private func updatePetData(petId: String, data: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("pets").document(petId).updateData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func getPet(petId: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        db.collection("pets").document(petId).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists,
                  var data = document.data() else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Pet not found"])))
                return
            }
            
            data["id"] = document.documentID
            completion(.success(data))
        }
    }
    
    
    func downloadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        
        if let cachedImage = imageLoading.object(forKey: urlString as NSString) {
            completion(cachedImage)
            return
        }
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            if let data = data, let image = UIImage(data: data) {
                self?.imageLoading.setObject(image, forKey: urlString as NSString)
                completion(image)
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    func deletePet(petId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        deletePetImage(petId: petId) { _ in }
        
        db.collection("pets").document(petId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    private func uploadPetImage(_ image: UIImage, petId: String, completion: @escaping (Result<String, Error>) -> Void) {
         guard let imageData = image.jpegData(compressionQuality: 0.7) else {
             completion(.failure(NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"])))
             return
         }
         
         let imageRef = storage.reference().child("pet_images/\(petId).jpg")
         
         imageRef.putData(imageData, metadata: nil) { _, error in
             if let error = error {
                 completion(.failure(error))
                 return
             }
             
             imageRef.downloadURL { url, error in
                 if let error = error {
                     completion(.failure(error))
                 } else if let url = url {
                     completion(.success(url.absoluteString))
                 }
             }
         }
     }
     
    
    private func deletePetImage(petId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let imageRef = storage.reference().child("pet_images/\(petId).jpg")
        
        imageRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func addFavorites(userId: String, petId: String, completion: @escaping((Result<Void, Error>) -> Void)) {
        let favorites: [String: Any] = [
            "userId": userId,
            "petId": petId,
        ]
        
        let id = "\(userId)_\(petId)"
        
        db.collection("favorites").document(id).setData(favorites) {
            error in if let error = error {
                completion(.failure(error))
            }else {
                completion(.success(()))
            }
        }
    }
    
    func getFavorites(userId: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        db.collection("favorites").whereField("userId", isEqualTo: userId).getDocuments { [self] result, error in if let error = error {
            completion(.failure(error))
            return
        }
        var petIds: [String] = []
        for doc in result?.documents ?? [] {
            if let petId = doc.data()["petId"] as? String {
                petIds.append(petId)
            }
        }
            
        if petIds.isEmpty {
            completion(.success([]))
            return
        }

        db.collection("pets")
            .whereField(FieldPath.documentID(), in: petIds)
            .getDocuments { petsSnapshot, petsError in
                if let petsError = petsError {
                    completion(.failure(petsError))
                    return
                }
                var pets: [[String: Any]] = []
                for doc in petsSnapshot?.documents ?? [] {
                    var petData = doc.data()
                    petData["id"] = doc.documentID 
                    pets.append(petData)
                }
                completion(.success(pets))
                }
        }
    }
    
    func removeFavorite(userId: String, petId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let id = "\(userId)_\(petId)"
        
        db.collection("favorites").document(id).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func getUniqueAnimalTypes(completion: @escaping ([String]) -> Void) {
        db.collection("pets").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            
           let types = Set(documents.compactMap { doc -> String? in
               guard let type = doc.data()["animalType"] as? String else { return nil }
               return type.lowercased()
           })
           
           let sortedTypes = types.sorted().map { $0.capitalized }
           completion(sortedTypes)
        }
    }

    func getUniqueSexOptions(completion: @escaping ([String]) -> Void) {
        db.collection("pets").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            
            let sexes = Set(documents.compactMap { doc -> String? in
                guard let sex = doc.data()["sex"] as? String else { return nil }
                return sex.lowercased()
            })
            
            let sortedSexes = sexes.sorted().map { $0.capitalized }
            completion(sortedSexes)
        }
    }

    func getUniqueSizeOptions(completion: @escaping ([String]) -> Void) {
        db.collection("pets").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            
            let sizes = Set(documents.compactMap { doc -> String? in
                guard let size = doc.data()["size"] as? String else { return nil }
                return size.lowercased()
            })
            
            let sortedSizes = sizes.sorted().map { $0.capitalized }
            completion(sortedSizes)
        }
    }

    func getUniqueLocations(completion: @escaping ([String]) -> Void) {
        db.collection("pets").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            
            let locations = Set(documents.compactMap { $0.data()["location"] as? String })
            let sortedLocations = locations.sorted()
            completion(sortedLocations)
        }
    }
    
    func fetchEvents(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        db.collection("events")
            .order(by: "postDate", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let events = documents.map { doc -> [String: Any] in
                    var data = doc.data()
                    data["id"] = doc.documentID
                    return data
                }
                
                print("Fetched \(events.count) events from Firestore")
                completion(.success(events))
            }
    }

    func likeEvent(userId: String, eventId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let batch = db.batch()
        
        let userLike = db.collection("users").document(userId).collection("likedEvents").document(eventId)
        batch.setData(["likedAt": FieldValue.serverTimestamp()], forDocument: userLike)
        
        let event = db.collection("events").document(eventId)
        batch.updateData(["likeCount": FieldValue.increment(Int64(1))], forDocument: event)
        
        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                print("Event liked successfully")
                completion(.success(()))
            }
        }
    }

    func unlikeEvent(userId: String, eventId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let batch = db.batch()
        
        let userLike = db.collection("users").document(userId).collection("likedEvents").document(eventId)
        batch.deleteDocument(userLike)
        
        let event = db.collection("events").document(eventId)
        batch.updateData(["likeCount": FieldValue.increment(Int64(-1))], forDocument: event)
        
        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                print("Event unliked successfully")
                completion(.success(()))
            }
        }
    }

    func getUserLikedEvents(userId: String, completion: @escaping (Result<[String], Error>) -> Void) {
        db.collection("users").document(userId).collection("likedEvents")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let eventIds = snapshot?.documents.map { $0.documentID } ?? []
                completion(.success(eventIds))
            }
    }

    func addEvent(
        title: String,
        description: String,
        postDate: String,
        location: String,
        images: [UIImage],
        shelterId: String? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let userId = AuthManager.shared.getCurrentUserId() else {
                completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
                return
            }
        var eventData: [String: Any] = [
            "title": title,
            "description": description,
            "postDate": postDate,
            "location": location,
            "userId": userId,
            "likeCount": 0,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        if let shelterId = shelterId {
            eventData["shelterId"] = shelterId
        }
        
        let docRef = db.collection("events").document()
        
        if !images.isEmpty {
                uploadMultipleEventImages(images, eventId: docRef.documentID) { [weak self] imageUrls in
                    eventData["imageUrls"] = imageUrls
                    
                    docRef.setData(eventData) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(docRef.documentID))
                        }
                    }
                }
        } else {

            eventData["imageUrls"] = []
            docRef.setData(eventData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(docRef.documentID))
                }
            }
        }
    }
    
    private func uploadMultipleEventImages(_ images: [UIImage], eventId: String, completion: @escaping ([String]) -> Void) {
        guard !images.isEmpty else {
            completion([])
            return
        }
        
        var imageUrls: [String] = []
        let group = DispatchGroup()
                
        for (index, image) in images.enumerated() {
            group.enter()
            
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                group.leave()
                continue
            }
            
            let imageName = "\(eventId)_\(index).jpg"
            let storageRef = storage.reference().child("event_images/\(imageName)")
            
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    group.leave()
                    return
                }
                
                storageRef.downloadURL { url, error in
                    defer { group.leave() }
                    
                    if let error = error {
                        print("Failed to get URL for image \(index): \(error.localizedDescription)")
                    } else if let url = url {
                        imageUrls.append(url.absoluteString)
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(imageUrls)
        }
    }

    private func uploadEventImage(_ image: UIImage, eventId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            completion(.failure(NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"])))
            return
        }
        
        let imageRef = storage.reference().child("event_images/\(eventId).jpg")
        
        imageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                }
            }
        }
    }
    
    func updateEvent(
        eventId: String,
        title: String,
        description: String,
        postDate: String,
        location: String,
        newImages: [UIImage],
        shelterId: String? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        var eventData: [String: Any] = [
            "title": title,
            "description": description,
            "postDate": postDate,
            "location": location,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if let shelterId = shelterId {
            eventData["shelterId"] = shelterId
        }
        
        if !newImages.isEmpty {
            deleteEventImages(eventId: eventId) { _ in }
            
            uploadMultipleEventImages(newImages, eventId: eventId) { [weak self] imageUrls in
                eventData["imageUrls"] = imageUrls
                self?.updateEventData(eventId: eventId, data: eventData, completion: completion)
            }
        } else {
            updateEventData(eventId: eventId, data: eventData, completion: completion)
        }
    }

    private func updateEventData(eventId: String, data: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("events").document(eventId).updateData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func deleteEvent(eventId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        deleteEventImages(eventId: eventId) { _ in }
        
        db.collection("events").document(eventId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    private func deleteEventImages(eventId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let folderRef = storage.reference().child("event_images")
        
        folderRef.listAll { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let items = result?.items else {
                completion(.success(()))
                return
            }
            
            let eventImages = items.filter { $0.name.starts(with: "\(eventId)_") }
            
            guard !eventImages.isEmpty else {
                completion(.success(()))
                return
            }
            
            let group = DispatchGroup()
            var deleteErrors: [Error] = []
            
            for imageRef in eventImages {
                group.enter()
                
                imageRef.delete { error in
                    defer { group.leave() }
                    
                    if let error = error {
                        deleteErrors.append(error)
                    } else {
                        print("Deleted image: \(imageRef.name)")
                    }
                }
            }
            
            group.notify(queue: .main) {
                if deleteErrors.isEmpty {
                    completion(.success(()))
                } else {
                    completion(.failure(deleteErrors.first!))
                }
            }
        }
    }
}
