//
//  PostEventsTableViewController.swift
//  Pet Match
//
//  Created by Ava Pan on 11/22/25.
//

import UIKit

class PostEventsTableViewController: UITableViewController {

    private var events: [EventData] = []
       
       override func viewDidLoad() {
           super.viewDidLoad()
           
           title = "Manage Events"
           setupRefreshControl()
           loadEvents()
           setupBackgroundImageTableViewController()
       }
       
       override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)
           loadEvents()
       }
       
       func setupRefreshControl() {
           let refreshControl = UIRefreshControl()
           refreshControl.addTarget(self, action: #selector(loadEvents), for: .valueChanged)
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
       
    @objc func loadEvents() {
        
        guard let userId = AuthManager.shared.getCurrentUserId() else { return }
        
        AuthManager.shared.getUserProfile(userId: userId) { [weak self] result in
            let userShelterId = (try? result.get())?["shelterId"] as? String
            
            FirebaseManager.shared.fetchEvents { [weak self] result in
                DispatchQueue.main.async {
                    self?.tableView.refreshControl?.endRefreshing()
                    
                    switch result {
                    case .success(let eventsData):
                        var displayEvents = eventsData
                        
                        if let shelterId = userShelterId, !shelterId.isEmpty {
                            displayEvents = eventsData.filter { event in
                                event["shelterId"] as? String == shelterId
                            }
                        }
                        
                        self?.events = displayEvents.map { EventData(from: $0) }
                        self?.events.sort { event1, event2 in
                            let date1 = event1.date ?? Date.distantPast
                            let date2 = event2.date ?? Date.distantPast
                            return date1 > date2
                        }
                        self?.tableView.reloadData()
                        
                        if self?.events.isEmpty == true {
                            self?.displayMessage("Info", "No events available.")
                        }
                        
                    case .failure(let error):
                        self?.displayMessage("Error", "Failed to load events: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
       
       // MARK: - Table View Data Source
       
       override func numberOfSections(in tableView: UITableView) -> Int {
           return 1
       }
       
       override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
           return events.count
       }
       
       override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
           let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath)
           let event = events[indexPath.row]
           
           cell.textLabel?.text = event.title
           cell.detailTextLabel?.text = "\(event.postDate) • \(event.location)"
           
           cell.imageView?.image = UIImage(systemName: "phone")
           cell.imageView?.tintColor = .systemGray3
           cell.imageView?.contentMode = .scaleAspectFit
           
           if let firstImageUrl = event.imageUrls?.first {
               FirebaseManager.shared.downloadImage(from: firstImageUrl) { image in
                   DispatchQueue.main.async {
                       
                       guard let updateCell = tableView.cellForRow(at: indexPath) else { return }
                       
                       if let image = image {
                           let resizedImage = self.resizeImageForCell(image: image, targetSize: CGSize(width: 60, height: 60))
                           updateCell.imageView?.image = resizedImage
                           updateCell.imageView?.contentMode = .scaleAspectFill
                           updateCell.imageView?.clipsToBounds = true
                           updateCell.setNeedsLayout()
                           updateCell.layoutIfNeeded()
                       } else {
                           updateCell.imageView?.image = UIImage(systemName: "calendar")
                           updateCell.imageView?.tintColor = .systemGray3
                       }
                   }
               }
           } else {
               cell.imageView?.image = UIImage(systemName: "calendar")
               cell.imageView?.tintColor = .systemBlue
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
       
       override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
           tableView.deselectRow(at: indexPath, animated: true)
           
           guard !tableView.isEditing else {
               return
           }
           
           let event = events[indexPath.row]
           performSegue(withIdentifier: "editSegue", sender: event)
       }
       
       // MARK: - Swipe Actions
       
       override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
           
           guard tableView.isEditing else {
               return nil
           }
           
           let event = events[indexPath.row]
           
           let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
               self?.deleteEvent(event: event, at: indexPath, completionHandler: completionHandler)
           }
           
           deleteAction.image = UIImage(systemName: "trash.fill")
           deleteAction.backgroundColor = .systemRed
           
           let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] (action, view, completionHandler) in
               self?.performSegue(withIdentifier: "editSegue", sender: event)
               completionHandler(true)
           }
           
           editAction.image = UIImage(systemName: "pencil")
           editAction.backgroundColor = .systemBlue
           
           let swipeAction = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
           swipeAction.performsFirstActionWithFullSwipe = false
           
           return swipeAction
       }
       
       func deleteEvent(event: EventData, at indexPath: IndexPath, completionHandler: @escaping (Bool) -> Void) {
           FirebaseManager.shared.deleteEvent(eventId: event.id) { [weak self] result in
               DispatchQueue.main.async {
                   switch result {
                   case .success:
                       self?.events.remove(at: indexPath.row)
                       self?.tableView.deleteRows(at: [indexPath], with: .automatic)
                       self?.displayMessage("Success", "Event deleted successfully")
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
               if let addVC = segue.destination as? AddEditPostViewController {
                   addVC.isEditMode = false
               }
               
           } else if id == "editSegue" {
               if let editVC = segue.destination as? AddEditPostViewController,
                  let event = sender as? EventData {
                   editVC.isEditMode = true
                   editVC.eventToEdit = event
               }
               
           }
       }
       
       func displayMessage(_ title: String, _ message: String) {
           let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
           alert.addAction(UIAlertAction(title: "OK", style: .default))
           present(alert, animated: true)
       }
   }
