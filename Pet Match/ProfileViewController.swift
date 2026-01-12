//
//  ProfileViewController.swift
//  Pet Match
//
//  Created by Ava Pan on 11/12/25.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class ProfileViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var isEditMode = false
    var currentUserData: [String: Any]?
    var selectedImage: UIImage?
    
    @IBOutlet weak var manageButton: UIBarButtonItem!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var homeAddressTextField: UITextField!
    @IBOutlet weak var editPictureButton: UIButton!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var titleLabel: UILabel!
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "My Profile"
        setupBackgroundImageViewController()
        loadUserProfile()
        setupDelegates()
        switchMode()
        checkAdmin()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !isEditMode {
            loadUserProfile()
        }
    }
    
    func setupDelegates() {
        phoneNumberTextField.delegate = self
        homeAddressTextField.delegate = self
    }
    
    func switchMode() {
        if isEditMode {
            firstNameTextField.isEnabled = false
            firstNameTextField.backgroundColor = UIColor.systemGray6
            lastNameTextField.isEnabled = false
            lastNameTextField.backgroundColor = UIColor.systemGray6
            emailTextField.isEnabled = false
            emailTextField.backgroundColor = UIColor.systemGray6
            phoneNumberTextField.isEnabled = true
            phoneNumberTextField.backgroundColor = .white
            homeAddressTextField.isEnabled = true
            homeAddressTextField.backgroundColor = .white
            editPictureButton.isEnabled = true
            editButton.title = "Save"
            editButton.isEnabled = true
            titleLabel.text = "Edit My Profile"
        } else {
            firstNameTextField.isEnabled = false
            firstNameTextField.backgroundColor = UIColor.systemGray6
            lastNameTextField.isEnabled = false
            lastNameTextField.backgroundColor = UIColor.systemGray6
            emailTextField.isEnabled = false
            emailTextField.backgroundColor = UIColor.systemGray6
            phoneNumberTextField.isEnabled = false
            phoneNumberTextField.backgroundColor = UIColor.systemGray6
            homeAddressTextField.isEnabled = false
            homeAddressTextField.backgroundColor = UIColor.systemGray6
            editPictureButton.isEnabled = false
            editButton.title = "Edit"
            editButton.isEnabled = true
            titleLabel.text = "Profile"
        }
    }
    
    func checkAdmin() {
        manageButton?.isHidden = true
        manageButton?.isEnabled = false
        
        AuthManager.shared.isAdmin { [weak self] isAdmin in
                    DispatchQueue.main.async {
                if isAdmin {
                    self?.setupManageMenu()
                    self?.manageButton?.isHidden = false
                    self?.manageButton?.isEnabled = true
 
                } else {
                    self?.manageButton?.isHidden = true
                    self?.manageButton?.isEnabled = false

                }
            }
        }
    }
    
    private func setupManageMenu() {
        let managePetsAction = UIAction(
            title: "Manage Pets",
            image: UIImage(systemName: "pawprint.fill")
        ) { [weak self] _ in
            self?.performSegue(withIdentifier: "adminSegue", sender: nil)
        }
        
        let manageEventsAction = UIAction(
            title: "Manage Events",
            image: UIImage(systemName: "calendar")
        ) { [weak self] _ in
            self?.performSegue(withIdentifier: "manageEventsSegue", sender: nil)
        }
        
        let menu = UIMenu(children: [managePetsAction, manageEventsAction])
        
        manageButton?.menu = menu
    }
    
    @IBAction func onEditClicked(_ sender: UIBarButtonItem) {
        if isEditMode {
            updateUserProfile()
        } else {
            isEditMode = true
            switchMode()
        }
    }
    
    @IBAction func onLogout(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(
            title: "Logout",
            message: "Are you sure you want to logout?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { [weak self] _ in
            self?.performLogout()
        })
        
        present(alert, animated: true)
    }
    
    @IBAction func onEditPictureClicked(_ sender: UIButton) {
        let alert = UIAlertController(title: "Select Image", message: nil, preferredStyle: .alert)
        
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
    
    func openImagePicker(sourceType: UIImagePickerController.SourceType) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = sourceType
            picker.allowsEditing = true
            present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
           
        if let editedImage = info[.editedImage] as? UIImage {
           selectedImage = editedImage

        } else if let originalImage = info[.originalImage] as? UIImage {
           selectedImage = originalImage
        }
        
        if let image = selectedImage, let jpegData = image.jpegData(compressionQuality: 0.9),
           let normalizedImage = UIImage(data: jpegData) {
               selectedImage = resizeImage(image: normalizedImage, targetSize: CGSize(width: 400, height: 400))
               profileImageView.image = selectedImage
        }
           picker.dismiss(animated: true)
    }
       
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
       picker.dismiss(animated: true)
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let button = UIBarButtonItem()
        onEditClicked(button)
        textField.resignFirstResponder()
        return true
    }
    
    func updateUserProfile() {
        guard let phone = phoneNumberTextField.text, !phone.isEmpty,
                      let address = homeAddressTextField.text, !address.isEmpty else {
                    displayMessage("Error", "Phone and Address are required.")
                    return
                }
        
        let firstName = currentUserData?["firstName"] as? String ?? ""
        let lastName = currentUserData?["lastName"] as? String ?? ""
        let email = currentUserData?["email"] as? String ?? ""
        
        let loadingAlert = showLoading("Updating...")

        AuthManager.shared.updateProfile(
            firstName: firstName,
            lastName: lastName,
            email: email,
            phoneNumber: phone,
            homeAddress: address
        ) { [weak self] result in
            DispatchQueue.main.async {
                loadingAlert.dismiss(animated: true) {
                    switch result {
                    case .success:
                        
                        if let newImage = self?.selectedImage {
                            self?.uploadProfileImage(newImage)
                        } else {
                            self?.showSuccessAndSwitchToView()
                        }
                        
                    case .failure(let error):
                        self?.displayMessage("Update Failed", error.localizedDescription)
                    }
                }
            }
        }
    }
    
    func uploadProfileImage(_ image: UIImage) {
        guard let userId = AuthManager.shared.getCurrentUserId() else { return }
                
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            showSuccessAndSwitchToView()
            return
        }
        
        let storage = Storage.storage()
        let imageRef = storage.reference().child("profile_images/\(userId).jpg")
        
        imageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("upload error: \(error)")
                self.showSuccessAndSwitchToView()
                return
            }
            
            imageRef.downloadURL { url, error in
                if let url = url {
                    
                    let db = Firestore.firestore()
                    db.collection("users").document(userId).updateData([
                        "profileImageUrl": url.absoluteString
                    ]) { error in
                        if error == nil {
                        }
                        
                        DispatchQueue.main.async {
                            self.showSuccessAndSwitchToView()
                        }
                    }
                } else {
                    self.showSuccessAndSwitchToView()
                }
            }
        }
    }
    
    func showSuccessAndSwitchToView() {
        displayMessage("Success", "Profile updated successfully!")
        isEditMode = false
        selectedImage = nil
        switchMode()
        loadUserProfile()
    }
        
    func loadUserProfile() {
        guard let userId = AuthManager.shared.getCurrentUserId() else {
            return
        }
        
        AuthManager.shared.getUserProfile(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let userData):
                    self?.currentUserData = userData
                    self?.viewUserProfile(userData)
                case .failure(let error):
                    print("load error: \(error)")
                    self?.displayMessage("Error", "Failed to load profile")
                }
            }
        }
    }
        
    func viewUserProfile (_ userData: [String: Any]) {
        firstNameTextField.text = userData["firstName"] as? String ?? "Unknown"
        lastNameTextField.text = userData["lastName"] as? String ?? ""
        emailTextField.text = userData["email"] as? String ?? ""
        phoneNumberTextField.text = userData["phoneNumber"] as? String ?? ""
        homeAddressTextField.text = userData["homeAddress"] as? String ?? ""
        
        if let imageUrl = userData["profileImageUrl"] as? String {
            FirebaseManager.shared.downloadImage(from: imageUrl) { [weak self] image in
                DispatchQueue.main.async {
                    self?.profileImageView.image = image ?? UIImage(systemName: "person.circle.fill")
                }
            }
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .systemBlue
        }
    }
        
    func performLogout() {
        do {
            try AuthManager.shared.signOut()
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController = loginVC
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
                }
            }
        } catch {
            displayMessage("Error", "Failed to logout: \(error.localizedDescription)")
        }
    }
    
    func showLoading(_ message: String) -> UIAlertController {
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
    
    func displayMessage(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @IBAction func onDeleteAccountClicked(_ sender: UIButton) {
        let alert = UIAlertController(
               title: "⚠️ Delete Account",
               message: "This will permanently delete your account. This action cannot be undone.",
               preferredStyle: .alert
           )
           
           alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
           alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
               self?.deleteAccount()
           })
           
           present(alert, animated: true)
    }

    func deleteAccount() {
        guard let userId = AuthManager.shared.getCurrentUserId(),
            let currentUser = Auth.auth().currentUser else {
                return
            }
       
        Firestore.firestore().collection("users").document(userId).delete { error in
            if let error = error {
                print("Delete Firestore failed: \(error)")
            }
        }
       
        let imageRef = Storage.storage().reference().child("profile_images/\(userId).jpg")
        imageRef.delete { error in
            if let error = error {
                print("Delete picture failed: \(error)")
            }
        }
       
        currentUser.delete { [weak self] error in
            if let error = error {
                self?.displayMessage("Error", "Failed to delete account: \(error.localizedDescription)")
            } else {
                self?.performLogout()
            }
        }
    }
}
