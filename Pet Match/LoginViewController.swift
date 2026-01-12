//
//  LoginViewController.swift
//  Pet Match
//
//  Created by Ava Pan on 11/8/25.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UserDefaults.standard.set(false, forKey: "hasAddedCompletePets")
        setupBackgroundImageViewController()
        setupPassword(for: passwordTextField)
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
        guard let textField = passwordTextField else { return }
        sender.isSelected.toggle()
        textField.isSecureTextEntry.toggle()
    }
    
    @IBAction func onSignInClicked(_ sender: UIButton) {
        
        guard let email = emailTextField.text, !email.isEmpty,
                     let password = passwordTextField.text, !password.isEmpty else {
            displayMessage("Error", "Please enter email and password.")
                   return
               }
        
        guard isValidEmail(email) else {
            displayMessage("Error", "Please enter a valid email address.")
                    return
                }
        
        AuthManager.shared.signIn(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let userId):
                    self?.navigateToMain(userId: userId)
                case .failure(let error):
                    self?.displayMessage("Login Failed", error.localizedDescription)
                }
            }
        }
    }
        
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let button = UIButton()
        onSignInClicked(button)
        textField.resignFirstResponder()
        return true
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    @IBAction func onRegisterClicked(_ sender: UIButton) {
        performSegue(withIdentifier: "registerSegue", sender: nil)
    }
    
    func navigateToMain(userId: String) {
           
       UserDefaults.standard.set(userId, forKey: "currentUserId")
       
       if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
           appDelegate.navigateToMainTabBar()
       }
    }
    
    func displayMessage(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
