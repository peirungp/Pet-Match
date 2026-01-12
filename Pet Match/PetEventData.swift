//
//  PetEventData.swift
//  Pet Match
//
//  Created by Pei-Rung Pan on 11/21/25.
//

import Foundation

struct EventData {
    let id: String
    let title: String
    let postDate: String
    let location: String
    let description: String
    var likeCount: Int
    var isLiked: Bool
    let imageUrls: [String]?
    let shelterId: String?
    
    init(from dict: [String: Any]) {
        self.id = dict["id"] as? String ?? UUID().uuidString
        self.title = dict["title"] as? String ?? ""
        self.postDate = dict["postDate"] as? String ?? ""
        self.location = dict["location"] as? String ?? ""
        self.description = dict["description"] as? String ?? ""
        self.likeCount = dict["likeCount"] as? Int ?? 0
        self.isLiked = false
    
        if let urls = dict["imageUrls"] as? [String] {
            self.imageUrls = urls
        } else if let singleUrl = dict["imageUrl"] as? String {
            self.imageUrls = [singleUrl]
        } else {
            self.imageUrls = nil
        }
        self.shelterId = dict["shelterId"] as? String
    }
    
    var date: Date? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "en_US")
        if let date = formatter.date(from: postDate) {
            return date
        }
        return nil
    }
}
