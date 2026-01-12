//
//  PetFilterViewController.swift
//  Pet Match
//
//  Created by Ava Pan on 11/16/25.
//

import UIKit

class PetFilterViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var onApplyFilters: ((String?, String?, String?, String?, String?) -> Void)?

    var selectedAnimalType: String?
    var selectedSex: String?
    var selectedSize: String?
    var selectedLocation: String?
    var selectedAge: String?

    @IBOutlet weak var animalTypeTextField: UITextField!
    @IBOutlet weak var sexTextField: UITextField!
    @IBOutlet weak var sizeTextField: UITextField!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var ageTextField: UITextField!
    
    private var animalTypes: [String] = ["Any"]
    private var sexOptions: [String] = ["Any"]
    private var sizeOptions: [String] = ["Any"]
    private var locationOptions: [String] = ["Any"]
    private let ageOptions = ["Any", "Puppy/Kitten (< 1.5 years old)", "Young (1.5 - 4 years old)", "Adult (4 - 8 years old)", "Senior (8 years old and above)"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Pet Filter"
        setupPickers()
        loadFilterOptions()
        setupBackgroundImageViewController()
    }
    
    private func loadFilterOptions() {
        
        let group = DispatchGroup()
        
        group.enter()
        FirebaseManager.shared.getUniqueAnimalTypes { [weak self] types in
            DispatchQueue.main.async {
                self?.animalTypes = ["Any"] + types
                group.leave()
            }
        }
        
        group.enter()
        FirebaseManager.shared.getUniqueSexOptions { [weak self] sexes in
            DispatchQueue.main.async {
                self?.sexOptions = ["Any"] + sexes
                group.leave()
            }
        }
        
        group.enter()
        FirebaseManager.shared.getUniqueSizeOptions { [weak self] sizes in
            DispatchQueue.main.async {
                self?.sizeOptions = ["Any"] + sizes
                group.leave()
            }
        }
        
        group.enter()
        FirebaseManager.shared.getUniqueLocations { [weak self] locations in
            DispatchQueue.main.async {
                self?.locationOptions = ["Any"] + locations
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.setupPickers()
        }
    }
    
    private func setupPickers() {
        setupPickerFor(textField: animalTypeTextField, data: animalTypes)
        setupPickerFor(textField: sexTextField, data: sexOptions)
        setupPickerFor(textField: sizeTextField, data: sizeOptions)
        setupPickerFor(textField: locationTextField, data: locationOptions)
        setupPickerFor(textField: ageTextField, data: ageOptions)
    }
    
    private func setupPickerFor(textField: UITextField, data: [String]) {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        picker.tag = getPickerTag(for: textField)
        textField.inputView = picker
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissPicker))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flexSpace, doneButton], animated: false)
        textField.inputAccessoryView = toolbar
    }
    
    private func getPickerTag(for textField: UITextField) -> Int {
        switch textField {
        case animalTypeTextField: return 1
        case sexTextField: return 2
        case sizeTextField: return 3
        case locationTextField: return 4
        case ageTextField: return 5
        default: return 0
        }
    }
    
    @objc private func dismissPicker() {
        view.endEditing(true)
    }
    
    private func loadCurrentSelections() {
       animalTypeTextField.text = selectedAnimalType ?? "Any"
       sexTextField.text = selectedSex ?? "Any"
       sizeTextField.text = selectedSize ?? "Any"
       locationTextField.text = selectedLocation ?? "Any"
       ageTextField.text = selectedAge ?? "Any"
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
       return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 1: return animalTypes.count
        case 2: return sexOptions.count
        case 3: return sizeOptions.count
        case 4: return locationOptions.count
        case 5: return ageOptions.count
        default: return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case 1: return animalTypes[row]
        case 2: return sexOptions[row]
        case 3: return sizeOptions[row]
        case 4: return locationOptions[row]
        case 5: return ageOptions[row]
        default: return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 1:
            animalTypeTextField.text = animalTypes[row]
            selectedAnimalType = animalTypes[row] == "Any" ? nil : animalTypes[row]
        case 2:
            sexTextField.text = sexOptions[row]
            selectedSex = sexOptions[row] == "Any" ? nil : sexOptions[row]
        case 3:
            sizeTextField.text = sizeOptions[row]
            selectedSize = sizeOptions[row] == "Any" ? nil : sizeOptions[row]
        case 4:
            locationTextField.text = locationOptions[row]
            selectedLocation = locationOptions[row] == "Any" ? nil : locationOptions[row]
        case 5:
            ageTextField.text = ageOptions[row]
            selectedAge = ageOptions[row] == "Any" ? nil : ageOptions[row]
        default:
            break
        }
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return textField.inputView != nil
    }
    
    @IBAction func onApplyClicked(_ sender: UIBarButtonItem) {
        let animalType = animalTypeTextField.text == "Any" || animalTypeTextField.text?.isEmpty == true ? nil : animalTypeTextField.text
        let sex = sexTextField.text == "Any" || sexTextField.text?.isEmpty == true ? nil : sexTextField.text
        let size = sizeTextField.text == "Any" || sizeTextField.text?.isEmpty == true ? nil : sizeTextField.text
        let location = locationTextField.text == "Any" || locationTextField.text?.isEmpty == true ? nil : locationTextField.text
        let age = ageTextField.text == "Any" || ageTextField.text?.isEmpty == true ? nil : ageTextField.text
      
        onApplyFilters?(animalType, sex, size, location, age)
        
        dismiss(animated: true)
    }
    
    @IBAction func onResetClicked(_ sender: UIBarButtonItem) {
        selectedAnimalType = nil
        selectedSex = nil
        selectedSize = nil
        selectedLocation = nil
        selectedAge = nil
        
        animalTypeTextField.text = "Any"
        sexTextField.text = "Any"
        sizeTextField.text = "Any"
        locationTextField.text = "Any"
        ageTextField.text = "Any"
        
        onApplyFilters?(nil, nil, nil, nil, nil)
        dismiss(animated: true)
    }
    
    @IBAction func onCancelClicked(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let button = UIBarButtonItem()
        onApplyClicked(button)
        textField.resignFirstResponder()
        return true
    }
}
