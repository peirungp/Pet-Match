//
//  AuthManager.swift
//  Pet Match
//
//  Created by Ava Pan on 11/10/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit

class AuthManager {
    
    static let shared = AuthManager()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    func isAdmin(completion: @escaping (Bool) -> Void) {
        guard let userId = getCurrentUserId() else {
            completion(false)
            return
        }
        
        getUserProfile(userId: userId) { result in
            if case .success(let userData) = result {
                let role = userData["role"] as? String ?? "user"
                completion(role == "admin" || role == "shelter_admin")
            } else {
                completion(false)
            }
        }
    }
    
    func getCurrentUserShelterId(completion: @escaping (String?) -> Void) {
        guard let userId = getCurrentUserId() else {
            completion(nil)
            return
        }
        
        getUserProfile(userId: userId) { result in
            if case .success(let userData) = result {
                let shelterId = userData["shelterId"] as? String
                completion(shelterId)
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let userId = authResult?.user.uid else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
                return
            }
            completion(.success(userId))
        }
    }
    
    // MARK: - Register
    func register(
        firstName: String,
        lastName: String,
        email: String,
        password: String,
        phoneNumber: String,
        homeAddress: String,
        dateOfBirth: Date,
        hadPets: Bool,
        profileImage: UIImage?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let userId = authResult?.user.uid else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create user"])))
                return
            }
            
            let age = self.calculateAge(from: dateOfBirth)
            
            var userData: [String: Any] = [
                "id": userId,
                "firstName": firstName,
                "lastName": lastName,
                "email": email,
                "phoneNumber": phoneNumber,
                "homeAddress": homeAddress,
                "dateOfBirth": dateOfBirth,
                "age": age,
                "hadPets": hadPets,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            if let profileImage = profileImage {
                self.uploadProfileImage(profileImage, userId: userId) { result in
                    switch result {
                    case .success(let imageUrl):
                        var updatedData = userData
                        updatedData["profileImageUrl"] = imageUrl
                        self.saveUserProfile(userId: userId, userData: updatedData, completion: completion)
                        
                    case .failure:
                        self.saveUserProfile(userId: userId, userData: userData, completion: completion)
                    }
                }
            } else {
                self.saveUserProfile(userId: userId, userData: userData, completion: completion)
            }
        }
    }
    
    func updateProfile(
        firstName: String,
        lastName: String,
        email: String,
        phoneNumber: String,
        homeAddress: String,
        currentPassword: String? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let userId = getCurrentUserId() else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
            return
        }
       
        let updatedData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "phoneNumber": phoneNumber,
            "homeAddress": homeAddress,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(userId).updateData(updatedData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                print("Firestore: Profile updated")
                completion(.success(()))
            }
        }
    }
       
    // MARK: - Get User Profile
    func getUserProfile(userId: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data() else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])))
                return
            }
            
            completion(.success(data))
        }
    }
    
    // MARK: - Sign Out
    func signOut() throws {
        try Auth.auth().signOut()
        UserDefaults.standard.removeObject(forKey: "currentUserId")
        print("User signed out")
    }
    
    // MARK: - Get Current User
    func getCurrentUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    func isLoggedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
    
    
    private func saveUserProfile(userId: String, userData: [String: Any], completion: @escaping (Result<String, Error>) -> Void) {
        db.collection("users").document(userId).setData(userData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                print("Firestore: User profile saved")
                completion(.success(userId))
            }
        }
    }
    
    private func uploadProfileImage(_ image: UIImage, userId: String, completion: @escaping (Result<String, Error>) -> Void) {

        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"])))
            return
        }
        

        
        let imageRef = storage.reference().child("profile_images/\(userId).jpg")

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
    
    private func calculateAge(from date: Date) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: date, to: Date())
        return ageComponents.year ?? 0
    }
}
