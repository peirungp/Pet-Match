//
//  AddEditPostViewController.swift
//  Pet Match
//
//  Created by Ava Pan on 11/22/25.
//

import UIKit


class AddEditPostViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var isEditMode = false
    var eventToEdit: EventData?
    var selectedImages: [UIImage] = []
    private var datePicker: UIDatePicker!
       
    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var postDateTextField: UITextField!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
       
    override func viewDidLoad() {
        super.viewDidLoad()
           
        setupDatePicker()
        setupBackgroundImageViewController()
           
        if isEditMode {
            loadEventData()
            title = "Edit Event"
            imageButton.setTitle("Update Picture", for: .normal)
        } else {
            title = "Add Event"
            imageButton.setTitle("Add Picture", for: .normal)
            eventImageView.image = UIImage(systemName: "photo.fill")
            eventImageView.tintColor = .systemGray3
        }
    }
              
    private func setupDatePicker() {
        datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
           
        postDateTextField.inputView = datePicker
           
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissDatePicker))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flexSpace, doneButton], animated: false)
        postDateTextField.inputAccessoryView = toolbar
           
        if !isEditMode {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            postDateTextField.text = formatter.string(from: Date())
        }
    }
       
    @objc private func dateChanged() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        postDateTextField.text = formatter.string(from: datePicker.date)
    }
       
    @objc private func dismissDatePicker() {
        view.endEditing(true)
    }
       
    private func loadEventData() {
        guard let event = eventToEdit else { return }
           
        titleTextField.text = event.title
        postDateTextField.text = event.postDate
        locationTextField.text = event.location
        descriptionTextView.text = event.description
           
        if let firstImageUrl = event.imageUrls?.first {
            FirebaseManager.shared.downloadImage(from: firstImageUrl) { [weak self] image in
                DispatchQueue.main.async {
                    self?.eventImageView.image = image ?? UIImage(systemName: "photo.fill")
                    if image == nil {
                        self?.eventImageView.tintColor = .systemGray3
                    }
                }
            }
        }
    }
       
    // MARK: - Image Picker

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
        
        if !selectedImages.isEmpty {
            alert.addAction(UIAlertAction(title: "View Selected (\(selectedImages.count))", style: .default) { _ in
                self.showSelectedImages()
            })
        }
           
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
            selectedImages.append(editedImage)
            eventImageView.image = editedImage
            eventImageView.tintColor = nil
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImages.append(originalImage)
            eventImageView.image = originalImage
            eventImageView.tintColor = nil
        }
        picker.dismiss(animated: true)
    }
    
    private func updateImageButtonTitle() {
        if selectedImages.isEmpty {
            imageButton.setTitle("Add Picture", for: .normal)
        } else {
            imageButton.setTitle("Add Picture (\(selectedImages.count) selected)", for: .normal)
        }
    }
    
    private func showSelectedImages() {
        let alert = UIAlertController(title: "Selected Images", message: "\(selectedImages.count) image(s) selected", preferredStyle: .actionSheet)
        
        for (index, image) in selectedImages.enumerated() {
            alert.addAction(UIAlertAction(title: "Image \(index + 1)", style: .default) { [weak self] _ in
                self?.showImagePreview(image, at: index)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Clear All", style: .destructive) { [weak self] _ in
            self?.selectedImages.removeAll()
            self?.eventImageView.image = UIImage(systemName: "photo.fill")
            self?.eventImageView.tintColor = .systemGray3
            self?.updateImageButtonTitle()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showImagePreview(_ image: UIImage, at index: Int) {
        let alert = UIAlertController(title: "Image \(index + 1)", message: nil, preferredStyle: .alert)
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        alert.view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 50),
            imageView.widthAnchor.constraint(equalToConstant: 200),
            imageView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        let height = NSLayoutConstraint(item: alert.view!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 320)
        alert.view.addConstraint(height)
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.selectedImages.remove(at: index)
            self?.updateImageButtonTitle()
            
            if self?.selectedImages.isEmpty == true {
                self?.eventImageView.image = UIImage(systemName: "photo.fill")
                self?.eventImageView.tintColor = .systemGray3
            } else {
                self?.eventImageView.image = self?.selectedImages.first
            }
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
       
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
              
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
              
    @IBAction func onAddClicked(_ sender: UIBarButtonItem) {
        guard validateFields() else { return }
        
        if isEditMode {
            updateEvent()
        } else {
            addEvent()
        }
    }
       
    private func validateFields() -> Bool {
        guard let title = titleTextField.text, !title.isEmpty else {
            displayMessage("Error", "Title is required.")
            return false
        }
           
        guard let postDate = postDateTextField.text, !postDate.isEmpty else {
            displayMessage("Error", "Date is required.")
            return false
        }
           
        guard let location = locationTextField.text, !location.isEmpty else {
            displayMessage("Error", "Location is required.")
            return false
        }
           
        guard !descriptionTextView.text.isEmpty else {
            displayMessage("Error", "Description is required.")
            return false
        }
           
        return true
    }
       
    private func addEvent() {
        let loadingAlert = showLoading("Adding event...")
        
        AuthManager.shared.getCurrentUserShelterId { [weak self] shelterId in
            guard let self = self else { return }
            
            FirebaseManager.shared.addEvent(
                title: titleTextField.text!,
                description: descriptionTextView.text!,
                postDate: postDateTextField.text!,
                location: locationTextField.text!,
                images: selectedImages,
                shelterId: shelterId
            ) { [weak self] result in
                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true) {
                        switch result {
                        case .success:
                            self?.showSuccessAndDismiss("Event added successfully!")
                        case .failure(let error):
                            self?.displayMessage("Error", "Failed to add event: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
       
    private func updateEvent() {
        guard let eventId = eventToEdit?.id else { return }
        
        let loadingAlert = showLoading("Updating event...")
        
        AuthManager.shared.getCurrentUserShelterId { [weak self] shelterId in
            guard let self = self else { return }
            
            FirebaseManager.shared.updateEvent(
                eventId: eventId,
                title: titleTextField.text!,
                description: descriptionTextView.text!,
                postDate: postDateTextField.text!,
                location: locationTextField.text!,
                newImages: selectedImages,
                shelterId: shelterId
            ) { [weak self] result in
                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true) {
                        switch result {
                        case .success:
                            self?.showSuccessAndDismiss("Event updated successfully!")
                        case .failure(let error):
                            self?.displayMessage("Error", "Failed to update event: \(error.localizedDescription)")
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
