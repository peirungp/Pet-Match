//
//  AddEditUserViewController.swift
//  Pet Match
//
//  Created by Pei-Rung Pan on 11/4/25.
//

import UIKit
import FirebaseAuth

class AddEditUserViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var selectedImage: UIImage?

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewBtn: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var dateOfBirth: UIDatePicker!
    @IBOutlet weak var ageTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var homeAddressTextField: UITextField!
    @IBOutlet weak var hadPetsSwitch: UISwitch!
    @IBOutlet weak var registerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackgroundImageViewController()
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .systemGray

        dateOfBirth.maximumDate = Date()
        dateOfBirth.addTarget(self, action: #selector(dateOfBirthChanged), for: .valueChanged)
        
        ageTextField.isUserInteractionEnabled = false
        ageTextField.backgroundColor = .systemGray6
        setupBackgroundImageViewController()
        setupPassword(for: passwordTextField)
        setupPassword(for: confirmPasswordTextField)
    }
    
    func setupPassword(for textField: UITextField) {
        let password = UIButton(type: .custom)
        password.setImage(UIImage(systemName: "eye"), for: .normal)
        password.setImage(UIImage(systemName: "eye.slash"), for: .selected)
        password.tintColor = .gray
        password.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        password.addTarget(self, action: #selector(passwordVisibility(_:)), for: .touchUpInside)
        textField.rightView = password
        textField.rightViewMode = .always
        textField.textContentType = .oneTimeCode
    }
    
    @objc func passwordVisibility(_ sender: UIButton) {
        guard let textField = [passwordTextField, confirmPasswordTextField].first(where: { $0.rightView == sender }) else { return }
        sender.isSelected.toggle()
        textField.isSecureTextEntry.toggle()
    }
 
    @IBAction func onSignInClicked(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func imageViewBtn(_ sender: UIButton) {
        let imageBtn = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imageBtn.addAction(UIAlertAction(title: "Camera", style: .default) { _ in self.presentImagePicker(sourceType: .camera)
            })
        }
        
        imageBtn.addAction(UIAlertAction(title: "photo library", style: .default) {_ in self.presentImagePicker(sourceType: .photoLibrary)
            
        })
        
        imageBtn.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(imageBtn, animated: true)
    }
    
    func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
    @IBAction func onRegisterClicked(_ sender: UIButton) {
        
        guard let firstName = firstNameTextField.text, !firstName.isEmpty,
              let lastName = lastNameTextField.text, !lastName.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty,
              let phone = phoneNumberTextField.text, !phone.isEmpty,
              let homeAddress = homeAddressTextField.text, !homeAddress.isEmpty else {
            displayMessage("Error", "Please fill in all required fields.")
            return
        }
        
        guard password == confirmPassword else {
            displayMessage("Error", "Passwords do not match.")
            return
        }
        
        guard password.count >= 6 else {
            displayMessage("Error", "Password must be at least 6 characters.")
            return
        }
        
        guard isValidEmail(email) else {
            displayMessage("Error", "Please enter a valid email address.")
            return
        }
        
        guard let profileImage = selectedImage else {
             displayMessage("Error", "Please select a profile image.")
             return
        }
        
        let hadPets = hadPetsSwitch.isOn
        
            
            AuthManager.shared.register(
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password,
                phoneNumber: phone,
                homeAddress: homeAddress,
                dateOfBirth: dateOfBirth.date,
                hadPets: hadPets,
                profileImage: selectedImage
            ) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let userId):
                        self?.showSuccessAndDismiss()
                        
                    case .failure(let error):
                        self?.displayMessage("Registration Failed", error.localizedDescription)
                }
            }
        }
    }
    
    @objc func dateOfBirthChanged() {
        let age = calculateAge(from: dateOfBirth.date)
        ageTextField.text = "\(age)"
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImage = editedImage
            imageView.image = editedImage
            imageView.tintColor = nil
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImage = originalImage
            imageView.image = originalImage
            imageView.tintColor = nil
        }
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    func calculateAge(from date: Date) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: date, to: Date())
        return ageComponents.year ?? 0
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func showSuccessAndDismiss() {
        let alert = UIAlertController(
            title: "Success! 🎉",
            message: "Registration successful! Please sign in with your new account.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        })
        present(alert, animated: true)
    }

    
    func displayMessage(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
