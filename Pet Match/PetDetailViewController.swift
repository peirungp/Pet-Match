//
//  PetDetailViewController.swift
//  Pet Match
//
//  Created by Pei-Rung Pan on 11/12/25.
//

import Foundation
import UIKit

class PetDetailViewController: UIViewController {
    
    var petData: PetData?
    var petId: String?
    var shelterName: String?
    var shelterPhone: String?
    var shelterAddress: String?
    
    @IBOutlet weak var petImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var sexLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var specialNeedsLabel: UILabel!
    @IBOutlet weak var petStoryTextView: UITextView!
    @IBOutlet weak var shelterNameLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackgroundImageViewController()
        loadPetData()
        setupUI()        
    }
    
    private func setupUI() {
        petImageView.layer.cornerRadius = 12
        petImageView.clipsToBounds = true
        petImageView.contentMode = .scaleAspectFit
        petImageView.backgroundColor = .clear
       
        [ageLabel, sexLabel, sizeLabel, specialNeedsLabel].forEach { label in
            label?.layer.cornerRadius = 8
            label?.backgroundColor = .systemGray5
            label?.textAlignment = .center
            label?.clipsToBounds = true
        }
       
        petStoryTextView.layer.cornerRadius = 8
        petStoryTextView.layer.borderWidth = 1
        petStoryTextView.layer.borderColor = UIColor.systemGray4.cgColor
        petStoryTextView.isEditable = false
        petStoryTextView.isScrollEnabled = true
        petStoryTextView.font = UIFont.systemFont(ofSize: 16)
        petStoryTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    }
    
    private func loadPetData() {
        guard let pet = petData else {
            displayMessage("Error", "Pet data not available.")
            return
        }
        
        nameLabel.text = pet.name
        locationLabel.text = "📍 \(pet.location)"
        
        ageLabel.text = "\(pet.age)"
        sexLabel.text = "\(pet.sex)"
        sizeLabel.text = "\(pet.size)"
        specialNeedsLabel.text = pet.specialNeeds.isEmpty ? "No Special Needs" : "\(pet.specialNeeds)"
        
        if pet.description.isEmpty {
            petStoryTextView.text = "No story available for this pet yet."
        } else {
            petStoryTextView.text = pet.description
        }
        
        shelterNameLabel?.text = "🏠 Shelter: \(pet.shelterName)"
        phoneLabel?.text = "📞 Phone: \(pet.shelterPhone)"
        addressLabel?.text = "📍 Address: \(pet.shelterAddress)"
        
        if let imageUrl = pet.imageUrl {
            
            FirebaseManager.shared.downloadImage(from: imageUrl) { [weak self] image in
                DispatchQueue.main.async {
                    self?.petImageView.image = image ?? UIImage(systemName: "photo")

                    if image == nil {
                        self?.petImageView.tintColor = .systemGray3
                    }
                }
            }
        } else {
            petImageView.image = UIImage(systemName: "photo")
            petImageView.tintColor = .systemGray3
        }
    }
        
    func displayMessage(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
  }
