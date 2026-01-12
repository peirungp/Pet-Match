//
//  PetTableView.swift
//  Pet Match
//
//  Created by Pei-Rung Pan on 11/12/25.
//

import Foundation
import UIKit

class PetTableView: UITableViewCell {
    
    @IBOutlet weak var petImage: UIImageView!
    @IBOutlet weak var nameButton: UIButton!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    
    var onNameButton: (() -> Void)?
    var onMapButton: (() -> Void)?
    var onFavoriteButton: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupBackgroundImage()
        setupUI()
        setFavoriteButton()
    }
    
    private func setupUI() {
        petImage?.layer.cornerRadius = 12
        petImage?.clipsToBounds = true
        petImage?.contentMode = .scaleAspectFit
        petImage?.backgroundColor = .clear
        
        nameButton?.addTarget(self, action: #selector(nameButtonTapped), for: .touchUpInside)
        mapButton?.addTarget(self, action: #selector(mapButtonTapped), for: .touchUpInside)

    }
    
    private func setFavoriteButton() {
        favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
        favoriteButton.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        favoriteButton.tintColor = .systemRed
        favoriteButton.backgroundColor = .clear
        favoriteButton.layer.cornerRadius = 15
        favoriteButton.clipsToBounds = true
        favoriteButton.addTarget(self, action: #selector(onFavorite), for: .touchUpInside)
    }
    
    @objc private func onFavorite() {
        onFavoriteButton?()
    }
    
    @objc private func nameButtonTapped() {
        onNameButton?()
    }
    
    @objc private func mapButtonTapped() {
        onMapButton?()
        
    }
    
    func configure(with pet: PetData) {
        nameButton?.setTitle("\(pet.name)", for: .normal)
        mapButton?.setTitle("\(pet.location)", for: .normal)
        
        if let imageUrl = pet.imageUrl, let url = URL(string: imageUrl) {
            loadImage(from: url)
        } else {
            petImage?.image = UIImage(systemName: "photo")
        }
    }
    
    private func loadImage(from url: URL) {
        petImage?.image = nil

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            
            if let error = error {
                return
            }
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.petImage?.image = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: .up)

                }
            }
        }.resume()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        petImage?.image = nil
        nameButton?.setTitle("", for: .normal)
        mapButton?.setTitle("", for: .normal)
        
        favoriteButton.isSelected = false
        
        onNameButton = nil
        onMapButton = nil
        onFavoriteButton = nil
    }
}
