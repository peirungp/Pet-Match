//
//  AdminTableViewController.swift
//  Pet Match
//
//  Created by Ava Pan on 11/14/25.
//

import UIKit

class AdminTableViewController: UITableViewController {
    
    private var pets: [PetData] = []
       
    override func viewDidLoad() {
        super.viewDidLoad()
       
        title = "Manage Pets"
        setupRefreshControl()
        loadPets()
        setupBackgroundImageTableViewController()
    }
   
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadPets()
    }
    
    private func setupBackgroundImage() {
        guard let backgroundImage = UIImage(named: "pawprint_background") else {
            return
        }
        
        let backgroundImageView = UIImageView(image: backgroundImage)
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        view.insertSubview(backgroundImageView, at: 0)
    }
   
    func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(loadPets), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @IBAction func onEditClicked(_ sender: UIBarButtonItem) {
        tableView.setEditing(!tableView.isEditing, animated: true)
        
        if tableView.isEditing {
            sender.title = "Done"
        } else {
            sender.title = "Edit"
        }
    }
    
    @objc func loadPets() {
        guard let userId = AuthManager.shared.getCurrentUserId() else {
            self.displayMessage("Error", "Please sign in")
            return
        }
        
        AuthManager.shared.getUserProfile(userId: userId) { [weak self] result in
            guard let self = self else { return }
            
            let userShelterId = (try? result.get())?["shelterId"] as? String
            
            FirebaseManager.shared.fetchPets { [weak self] result in
                DispatchQueue.main.async {
                    self?.tableView.refreshControl?.endRefreshing()
                    
                    switch result {
                    case .success(let petsData):
                        var displayPets = petsData
                        
                        if let shelterId = userShelterId, !shelterId.isEmpty {
                            displayPets = petsData.filter { pet in
                                let petShelterId = pet["shelterId"] as? String
                                return petShelterId == shelterId
                            }
                        }
                        
                        self?.pets = displayPets.map { PetData(from: $0) }
                        self?.tableView.reloadData()
                        
                        if self?.pets.isEmpty == true {
                            self?.displayMessage("Info", "No pets available.")
                        }
                        
                    case .failure(let error):
                        self?.displayMessage("Error", "Failed to load pets: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
       
    // MARK: - Table View
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pets.count
    }
   
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AdminCell", for: indexPath)
        let pet = pets[indexPath.row]
        
        cell.textLabel?.text = pet.name
        cell.detailTextLabel?.text = "\(pet.breed) • \(pet.location) \n\(pet.shelterName)"
        
        cell.imageView?.image = UIImage(systemName: "photo")
        cell.imageView?.tintColor = .systemGray3
        
        if let imageUrl = pet.imageUrl, !imageUrl.isEmpty {
            let url = URL(string: imageUrl)!
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
            
            URLSession.shared.dataTask(with: request) { data, _, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        if cell.textLabel?.text == pet.name {
                            let resizedImage = self.resizeImageForCell(image: image, targetSize: CGSize(width: 60, height: 60))
                            cell.imageView?.image = resizedImage
                            cell.imageView?.tintColor = nil
                            cell.imageView?.contentMode = .scaleAspectFill
                            cell.imageView?.clipsToBounds = true
                            cell.setNeedsLayout()
                        }
                    }
                }
            }.resume()
        }
        
        return cell
    }
    
    func resizeImageForCell(image: UIImage, targetSize: CGSize) -> UIImage {
        let widthRatio = targetSize.width / image.size.width
        let heightRatio = targetSize.height / image.size.height
        let scale = max(widthRatio, heightRatio)
        
        let scaledWidth = image.size.width * scale
        let scaledHeight = image.size.height * scale
        
        let x = (targetSize.width - scaledWidth) / 2
        let y = (targetSize.height - scaledHeight) / 2
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = true
        
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))
            
            context.cgContext.clip(to: CGRect(origin: .zero, size: targetSize))
            
            image.draw(in: CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight))
        }
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        guard tableView.isEditing else {
            return nil
        }
                   
        let pet = pets[indexPath.row]
       
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            guard let self = self else {
                completionHandler(false)
                return
        }
            self.confirmDelete(pet: pet, at: indexPath, completionHandler: completionHandler)
        }
       
        deleteAction.image = UIImage(systemName: "trash.fill")
        deleteAction.backgroundColor = .systemRed
       
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] (action, view, completionHandler) in

            self?.performSegue(withIdentifier: "editSegue", sender: pet)
            completionHandler(true)
        }
       
        editAction.image = UIImage(systemName: "pencil")
        editAction.backgroundColor = .systemBlue
       
        let swipeAction = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        swipeAction.performsFirstActionWithFullSwipe = false
       
        return swipeAction
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard !tableView.isEditing else {
            return
        }
        
        let pet = pets[indexPath.row]
        performSegue(withIdentifier: "showDetailSegue", sender: pet)
    }
   
    func confirmDelete(pet: PetData, at indexPath: IndexPath, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(
            title: "Delete Pet",
            message: "Are you sure you want to delete \(pet.name)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(false)
        })
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deletePet(pet: pet, at: indexPath, completionHandler: completionHandler)
        })
        
        present(alert, animated: true)
    }
        
    func deletePet(pet: PetData, at indexPath: IndexPath, completionHandler: @escaping (Bool) -> Void) {
        FirebaseManager.shared.deletePet(petId: pet.id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.pets.remove(at: indexPath.row)
                    self?.tableView.deleteRows(at: [indexPath], with: .automatic)
                    self?.displayMessage("Success", "Pet deleted successfully")
                    completionHandler(true)
                    
                case .failure(let error):
                    self?.displayMessage("Error", "Failed to delete: \(error.localizedDescription)")
                    completionHandler(false)
                }
            }
        }
    }
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let id = segue.identifier else { return }
        
        if id == "addSegue" {
            if let addVC = segue.destination as? AddEditPetViewController {
                addVC.isEditMode = false
            }
            
        } else if id == "editSegue" {
            if let editVC = segue.destination as? AddEditPetViewController,
               let pet = sender as? PetData {
                editVC.isEditMode = true
                editVC.petToEdit = pet
            }
        } else if id == "showDetailSegue" {
            if let petDetailVC = segue.destination as? PetDetailViewController,
                let pet = sender as? PetData {
                petDetailVC.petData = pet
            }
        }
    }
   
   func displayMessage(_ title: String, _ message: String) {
       let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
       alert.addAction(UIAlertAction(title: "OK", style: .default))
       present(alert, animated: true)
   }
}
