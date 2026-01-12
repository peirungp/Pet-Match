//
//  AddEditPetViewController.swift
//  Pet Match
//
//  Created by Ava Pan on 11/14/25.
//

import UIKit

class AddEditPetViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var isEditMode = false
    var petToEdit: PetData?
    var selectedImage: UIImage?

    @IBOutlet weak var petImageView: UIImageView!
    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var ageTextField: UITextField!
    @IBOutlet weak var animalTypeTextField: UITextField!
    @IBOutlet weak var sexTextField: UITextField!
    @IBOutlet weak var sizeTextField: UITextField!
    @IBOutlet weak var breedTextField: UITextField!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var specialNeedsTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var shelterNameTextField: UITextField!
    @IBOutlet weak var shelterPhoneTextField: UITextField!
    @IBOutlet weak var shelterAddressTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        switchMode()
        setupBackgroundImageViewController()
    }
    
    func switchMode() {
        if isEditMode {
            loadPetData()
            title = "Edit Pet Information"
            imageButton.setTitle("Update Pet", for: .normal)
            idTextField.isEnabled = false
            idTextField.backgroundColor = .systemGray6
       } else {
            title = "Add Pet Information"
            imageButton.setTitle("Add Pet", for: .normal)
            petImageView.image = UIImage(systemName: "photo.fill")
            petImageView.tintColor = .systemGray3
            idTextField.isEnabled = false
            idTextField.backgroundColor = .systemGray6
            idTextField.text = "Auto-generated"
       }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let button = UIBarButtonItem()
        onAddClicked(button)
        textField.resignFirstResponder()
        return true
    }
    
    private func loadPetData() {
       guard let pet = petToEdit else { return }
       
       idTextField.text = pet.id
       nameTextField.text = pet.name
       ageTextField.text = pet.age
       sexTextField.text = pet.sex
       animalTypeTextField.text = pet.animalType

       breedTextField.text = pet.breed
       locationTextField.text = pet.location
       sizeTextField.text = pet.size
       specialNeedsTextField.text = pet.specialNeeds
       descriptionTextView.text = pet.description
       shelterNameTextField.text = pet.shelterName
       shelterPhoneTextField.text = pet.shelterPhone
       shelterAddressTextField.text = pet.shelterAddress
       
       if let imageUrl = pet.imageUrl {
           FirebaseManager.shared.downloadImage(from: imageUrl) { [weak self] image in
               DispatchQueue.main.async {
                   self?.petImageView.image = image ?? UIImage(systemName: "photo.fill")
                   if image == nil {
                       self?.petImageView.tintColor = .systemGray3
                   }
               }
           }
       }
    }
    
    @IBAction func onImageButtonClicked(_ sender: UIButton) {
        let alert = UIAlertController(title: "Select Image", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
                self.openImagePicker(sourceType: .camera)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
            self.openImagePicker(sourceType: .photoLibrary)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
        
    private func openImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.allowsEditing = true
        present(picker, animated: true)
    }
        
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImage = editedImage
            petImageView.image = editedImage
            petImageView.tintColor = nil
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImage = originalImage
            petImageView.image = originalImage
            petImageView.tintColor = nil
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    @IBAction func onAddClicked(_ sender: UIBarButtonItem) {
        guard validateFields() else { return }
        
        if isEditMode {
            updatePet()
        } else {
            addPet()
        }
    }
    
    private func validateFields() -> Bool {
        guard let name = nameTextField.text, !name.isEmpty else {
            displayMessage("Error", "Pet name is required.")
            return false
        }
       
        guard let age = ageTextField.text, !age.isEmpty else {
            displayMessage("Error", "Age is required.")
            return false
        }
       
        guard let sex = sexTextField.text, !sex.isEmpty else {
            displayMessage("Error", "Sex is required.")
            return false
        }
       
        guard let animalType = animalTypeTextField.text, !animalType.isEmpty else {
            displayMessage("Error", "Animal type is required.")
            return false
        }
       
        guard let breed = breedTextField.text, !breed.isEmpty else {
            displayMessage("Error", "Breed is required.")
            return false
        }
       
        guard let size = sizeTextField.text, !size.isEmpty else {
            displayMessage("Error", "Size is required.")
            return false
        }
       
        guard let location = locationTextField.text, !location.isEmpty else {
            displayMessage("Error", "Location is required.")
            return false
        }
       
       guard let shelterName = shelterNameTextField.text, !shelterName.isEmpty else {
           displayMessage("Error", "Shelter name is required.")
           return false
       }
       
       guard let shelterPhone = shelterPhoneTextField.text, !shelterPhone.isEmpty else {
           displayMessage("Error", "Shelter phone is required.")
           return false
       }
       
       guard let shelterAddress = shelterAddressTextField.text, !shelterAddress.isEmpty else {
           displayMessage("Error", "Shelter address is required.")
           return false
       }
       
       return true
    }
    
    private func addPet() {
        let loadingAlert = showLoading("Adding pet...")
        
        AuthManager.shared.getCurrentUserShelterId { [weak self] shelterId in
            guard let self = self else { return }
            
            FirebaseManager.shared.addPet(
                name: nameTextField.text!,
                age: ageTextField.text!,
                sex: sexTextField.text!,
                location: locationTextField.text!,
                animalType: animalTypeTextField.text!,
                breed: breedTextField.text!,
                size: sizeTextField.text!,
                specialNeeds: specialNeedsTextField.text ?? "None",
                description: descriptionTextView.text ?? "",
                shelterName: shelterNameTextField.text!,
                shelterPhone: shelterPhoneTextField.text!,
                shelterAddress: shelterAddressTextField.text!,
                isAdopted: false,
                shelterId: shelterId,
                image: selectedImage
            ) { [weak self] result in
                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true) {
                        switch result {
                        case .success:
                            self?.showSuccessAndDismiss("Pet added successfully!")
                        case .failure(let error):
                            self?.displayMessage("Error", "Failed to add pet: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
        
    private func updatePet() {
        guard let petId = petToEdit?.id else { return }
        
        let loadingAlert = showLoading("Updating pet...")
        
        AuthManager.shared.getCurrentUserShelterId { [weak self] shelterId in
            guard let self = self else { return }
            
            FirebaseManager.shared.updatePet(
                petId: petId,
                name: nameTextField.text!,
                age: ageTextField.text!,
                sex: sexTextField.text!,
                location: locationTextField.text!,
                animalType: animalTypeTextField.text!,
                breed: breedTextField.text!,
                size: sizeTextField.text!,
                specialNeeds: specialNeedsTextField.text ?? "None",
                description: descriptionTextView.text ?? "",
                shelterName: shelterNameTextField.text!,
                shelterPhone: shelterPhoneTextField.text!,
                shelterAddress: shelterAddressTextField.text!,
                shelterId: shelterId,
                newImage: selectedImage
            ) { [weak self] result in
                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true) {
                        switch result {
                        case .success:
                            self?.showSuccessAndDismiss("Pet updated successfully!")
                        case .failure(let error):
                            self?.displayMessage("Error", "Failed to update pet: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    
    private func showLoading(_ message: String) -> UIAlertController {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        alert.view.addSubview(indicator)
        
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: alert.view.centerYAnchor, constant: -10)
        ])
        
        present(alert, animated: true)
        return alert
    }
    
    private func showSuccessAndDismiss(_ message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
    
    func displayMessage(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
