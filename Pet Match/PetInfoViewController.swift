//
//  PetInfoViewController.swift
//  Pet Match
//
//  Created by Pei-Rung Pan on 11/5/25.
//

import UIKit

class PetInfoViewController: UITableViewController {
    
    private var pets: [PetData] = []
    private var isFiltering = false
    private var currentAnimalType: String?
    private var currentSex: String?
    private var currentSize: String?
    private var currentLocation: String?
    private var currentAge: String?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Pet Information"
        
        setUpTableView()
        loadPets()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 350
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateFavorites()
        
        if isFiltering {
           applyFilters()
       } else {
           loadPets()
       }
    }
    
    private func updateFavorites() {
        guard let userId = AuthManager.shared.getCurrentUserId() else { return }
        FirebaseManager.shared.getFavorites(userId: userId) { [weak self] result in DispatchQueue.main.async {
            guard let self = self else { return }
            
            switch result {
            case .success(let favoritePets):
                let favoriteId = Set(favoritePets.compactMap{ $0["id"] as? String })
                self.tableView.visibleCells.forEach {
                    cell in if let petCell = cell as? PetTableView, let indexPath = self.tableView.indexPath(for: cell), indexPath.row < self.pets.count {
                        let pet = self.pets[indexPath.row]
                        let isFavorite = favoriteId.contains(pet.id)
                        petCell.favoriteButton.isSelected = isFavorite
                    }
                }
            case.failure(let error):
                self.displayMessage("Error", "Failed to update \(error)")
            }
          }
        }
    }
    
    private func setUpTableView() {
        tableView.backgroundColor = .systemGroupedBackground
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }
    
    @IBAction func onFilterClicked(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "filterSegue", sender: nil)
    }
    
    @objc private func refreshData() {
        if isFiltering {
            applyFilters()
        } else {
            loadPets()
        }
    }

    private func loadPets() {
        
        FirebaseManager.shared.fetchPets { [weak self] result in
            DispatchQueue.main.async {
                self?.refreshControl?.endRefreshing()
                
                switch result {
                case .success(let petsData):
                    self?.pets = petsData.map { PetData(from: $0) }
                    self?.tableView.reloadData()
                    
                    if self?.pets.isEmpty == true {
                        self?.displayMessage("Alert", "No pets available.")
                    }
                    
                case .failure(let error):
                    self?.displayMessage("Error", "Data loading falied.")
                    print("load failed: \(error)")
                }
            }
        }
    }
    
    private func applyFilters() {
        isFiltering = true
        updateTitle()
  
        FirebaseManager.shared.fetchPets { [weak self] result in
            DispatchQueue.main.async {
                self?.refreshControl?.endRefreshing()
                  
                switch result {
                case .success(let petsData):
                    var filteredPets = petsData

                    if let animalType = self?.currentAnimalType {
                        filteredPets = filteredPets.filter { pet in
                            let petType = (pet["animalType"] as? String ?? "").lowercased()
                            let searchType = animalType.lowercased()
                            return petType == searchType
                        }
                      }
                      
                    if let sex = self?.currentSex {
                        filteredPets = filteredPets.filter { pet in
                            let petSex = (pet["sex"] as? String ?? "").lowercased()
                            let searchSex = sex.lowercased()
                            return petSex == searchSex
                        }
                    }
                      
                    if let size = self?.currentSize {
                        filteredPets = filteredPets.filter { pet in
                            let petSize = (pet["size"] as? String ?? "").lowercased()
                            let searchSize = size.lowercased()
                            return petSize == searchSize
                        }
                    }
                      
                    if let location = self?.currentLocation {
                        filteredPets = filteredPets.filter { pet in
                            let petLocation = pet["location"] as? String ?? ""
                            return petLocation == location
                        }
                    }
                      
                    if let age = self?.currentAge {
                        filteredPets = filteredPets.filter { pet in
                            guard let ageString = pet["age"] as? String,
                                let petAgeInMonths = Int(ageString) else {
                                return false
                            }
                              
                            switch age {
                            case "Puppy/Kitten (< 1.5 years old)":
                                return petAgeInMonths <= 18
                            case "Young (1.5 - 4 years old)":
                                return petAgeInMonths > 18 && petAgeInMonths <= 48
                            case "Adult (4 - 8 years old)":
                                return petAgeInMonths > 48 && petAgeInMonths <= 96
                            case "Senior (8 years old and above)":
                                return petAgeInMonths > 96
                            default:
                                return true
                            }
                        }
                    }
                      
                    self?.pets = filteredPets.map { PetData(from: $0) }
                    self?.tableView.reloadData()
                                            
                    if filteredPets.isEmpty {
                        self?.displayMessage("No Results", "No pets match your filters. Try adjusting your criteria.")
                      }
                      
                case .failure(let error):
                    self?.displayMessage("Error", "Failed to load pets.")
                }
            }
        }
    }
        
    private func updateTitle() {
        if isFiltering {
            navigationItem.rightBarButtonItem?.tintColor = .systemOrange
        } else {
            navigationItem.rightBarButtonItem?.tintColor = .systemBlue
        }
    }
        
    func didApplyFilters(animalType: String?, sex: String?, size: String?, location: String?, age: String?) {
        currentAnimalType = animalType
        currentSex = sex
        currentSize = size
        currentLocation = location
        currentAge = age
       
        let hasFilters = animalType != nil || sex != nil || size != nil || location != nil || age != nil
   
        isFiltering = hasFilters
     
        if hasFilters {
            applyFilters()
        } else {
            loadPets()
        }
    }
    
    // MARK: - Table View Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pets.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
           withIdentifier: "PetCell",
           for: indexPath
       ) as? PetTableView else {
           return UITableViewCell()
       }
       
       let pet = pets[indexPath.row]
       cell.configure(with: pet)
       cell.selectionStyle = .none
       
       cell.onNameButton = { [weak self] in
           self?.performSegue(withIdentifier: "petDetailSegue", sender: pet)
       }
       
       cell.onMapButton = { [weak self] in
           self?.performSegue(withIdentifier: "mapSegue", sender: pet)
       }
    
       cell.onFavoriteButton = { [weak self] in
         self?.handleFavorite(for: pet, cell: cell)
       }
       
        return cell
    }
    
    private func handleFavorite(for pet: PetData, cell: PetTableView) {
        guard let userId = AuthManager.shared.getCurrentUserId() else { return }
        
        let isFavorite = cell.favoriteButton.isSelected
        
        if isFavorite {
            FirebaseManager.shared.removeFavorite(userId: userId, petId: pet.id) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        cell.favoriteButton.isSelected = false
                        self?.displayMessage("Success", "Removed from favorites")
                        
                    case .failure:
                        self?.displayMessage("Error", "Failed to remove from favorites")
                    }
                }
            }
        } else {
            FirebaseManager.shared.addFavorites(userId: userId, petId: pet.id) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        cell.favoriteButton.isSelected = true
                        self?.displayMessage("Success", "Added to favorites")
                        
                    case .failure:
                        self?.displayMessage("Error", "Failed to add favorites")
                    }
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "filterSegue" {
            if let navController = segue.destination as? UINavigationController,
               let filterVC = navController.viewControllers.first as? PetFilterViewController {
                
                filterVC.selectedAnimalType = currentAnimalType
                filterVC.selectedSex = currentSex
                filterVC.selectedSize = currentSize
                filterVC.selectedLocation = currentLocation
                filterVC.selectedAge = currentAge
                
                filterVC.onApplyFilters = { [weak self] animalType, sex, size, location, age in
                    
                    self?.currentAnimalType = animalType
                    self?.currentSex = sex
                    self?.currentSize = size
                    self?.currentLocation = location
                    self?.currentAge = age
                    
                    let hasFilters = animalType != nil || sex != nil || size != nil || location != nil || age != nil
                    
                    self?.isFiltering = hasFilters
                    self?.updateTitle()
                    
                    if hasFilters {
                        self?.applyFilters()
                    } else {
                        self?.loadPets()
                    }
                }
            }
            return
        }
        
        guard let pet = sender as? PetData else {
            return
        }
        
        if segue.identifier == "petDetailSegue" {
            if let detailVC = segue.destination as? PetDetailViewController {
                detailVC.title = "Pet details"
                detailVC.petData = pet
            }
            
        } else if segue.identifier == "mapSegue" {
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
    

