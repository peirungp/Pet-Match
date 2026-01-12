//
//  FavoritePetListController.swift
//  Pet Match
//
//  Created by Pei-Rung Pan on 11/14/25.
//

import UIKit

class MyFavoritePetListController: UITableViewController {
    
    private var favoritePets: [PetData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "My Favorite List"
        
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFavorites()
    }
    
    private func setupTableView() {
        tableView.estimatedRowHeight = 100

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(loadFavorites), for: .valueChanged)
    }
    
    @objc  func loadFavorites() {
        guard let userId = AuthManager.shared.getCurrentUserId() else {
            displayMessage("Error", "Please log in to view favorites")
            refreshControl?.endRefreshing()
            return
        }
        
        FirebaseManager.shared.getFavorites(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.refreshControl?.endRefreshing()
                
                switch result {
                case .success(let petsData):
                    self?.favoritePets = petsData.map { PetData(from: $0) }
                    self?.tableView.reloadData()
                                        
                    if petsData.isEmpty {
                        self?.displayMessage("Info", "No favorite pets yet. Add some from Pet Information!")
                    }
                    
                case .failure(let error):
                    self?.displayMessage("Error", "Failed to load favorites: \(error.localizedDescription)")
                }
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoritePets.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "FavoriteCell",
            for: indexPath
        ) as? PetTableView else {
            return UITableViewCell()
        }
        
        let pet = favoritePets[indexPath.row]
        cell.configure(with: pet)
        cell.selectionStyle = .none
        
        cell.onNameButton = { [weak self] in
            self?.performSegue(withIdentifier: "favoriteToPetDetailSegue", sender: pet)
        }
        
        cell.onMapButton = { [weak self] in
            self?.performSegue(withIdentifier: "favoriteToMapSegue", sender: pet)
        }
        
        cell.onFavoriteButton = { [weak self] in
            self?.handleUnfavorite(for: pet, at: indexPath)
        }
        
        cell.favoriteButton.isSelected = true
        
        return cell
    }
    
    private func handleUnfavorite(for pet: PetData, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "Remove from Favorites",
            message: "Remove \(pet.name) from your favorites?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            self?.removeFavorite(pet: pet, at: indexPath)
        })
        
        present(alert, animated: true)
    }
    
    private func removeFavorite(pet: PetData, at indexPath: IndexPath) {
        guard let userId = AuthManager.shared.getCurrentUserId() else { return }
       
        FirebaseManager.shared.removeFavorite(userId: userId, petId: pet.id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.favoritePets.remove(at: indexPath.row)
                    self?.tableView.deleteRows(at: [indexPath], with: .automatic)
                    self?.displayMessage("Success", "Removed from favorites")
                   
                case .failure(let error):
                    self?.displayMessage("Error", "Failed to remove: \(error.localizedDescription)")
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let pet = sender as? PetData else {
            return
        }
       
        if segue.identifier == "favoriteToPetDetailSegue" {
            if let detailVC = segue.destination as? PetDetailViewController {
                detailVC.title = "Pet Details"
                detailVC.petData = pet
            }
           
        } else if segue.identifier == "favoriteToMapSegue" {
            if let mapVC = segue.destination as? MapInfoViewController {
                mapVC.petLocation = pet.location
                mapVC.petName = pet.name
                mapVC.shelterName = pet.shelterName
                mapVC.shelterPhone = pet.shelterPhone
                mapVC.shelterAddress = pet.shelterAddress
            }
        }
    }
    
    func displayMessage(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
