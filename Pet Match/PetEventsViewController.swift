//
//  PetEventsViewController.swift
//  Pet Match
//
//  Created by Pei-Rung Pan on 11/21/25.
//

import UIKit

class PetEventsViewController: UITableViewController {
    
    private var events: [EventData] = []
    private var userLikedEvents: Set<String> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Events"
        loadEvents()
        loadUserLikes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadEvents() 
        loadUserLikes()
    }
    
    private func setupTableView() {
        tableView.backgroundColor = .systemGroupedBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 550
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }
    
    @objc private func refreshData() {
        loadEvents()
        loadUserLikes()
    }
    
    private func loadEvents() {
        FirebaseManager.shared.fetchEvents { [weak self] result in
            DispatchQueue.main.async {
                self?.refreshControl?.endRefreshing()
                
                switch result {
                case .success(let eventsData):
                    
                    self?.events = eventsData.map { eventDict in
                        var event = EventData(from: eventDict)
                        if let userId = AuthManager.shared.getCurrentUserId() {
                            event.isLiked = self?.userLikedEvents.contains(event.id) ?? false
                        }
                        return event
                    }
                    
                    self?.events.sort {
                        ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast)
                    }
                    self?.tableView.reloadData()
                    
                    if self?.events.isEmpty == true {
                        self?.displayMessage("Notice", "No events available at this time.")
                    }
                    
                case .failure(let error):
                    self?.displayMessage("Error", "Failed to load events: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loadUserLikes() {
        guard let userId = AuthManager.shared.getCurrentUserId() else {
            return
        }
        
        FirebaseManager.shared.getUserLikedEvents(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let likedEventIds):
                    self?.userLikedEvents = Set(likedEventIds)
                    self?.tableView.reloadData()
                    
                case .failure(let error):
                    print("Failed to load user likes: \(error)")
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
        
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "EventCell",
            for: indexPath
        ) as? PetEventTableView else {
            return UITableViewCell()
        }
                
        let event = events[indexPath.row]
        
        cell.configure(with: event)
        cell.selectionStyle = .none
        
        cell.onLikeButton = { [weak self] in
            self?.handleLike(for: event, at: indexPath, cell: cell)
        }
        
        cell.onShareButton = { [weak self] in
            self?.handleShare(for: event)
        }
        
        return cell
    }
        
    private func handleLike(for event: EventData, at indexPath: IndexPath, cell: PetEventTableView) {
        guard let userId = AuthManager.shared.getCurrentUserId() else {
            displayMessage("Error", "Please log in to like events.")
            return
        }
        
        let currentEvent = events[indexPath.row]
        let isCurrentlyLiked = userLikedEvents.contains(currentEvent.id)
        
        let newLikeCount: Int
        if isCurrentlyLiked {
            newLikeCount = max(0, currentEvent.likeCount - 1)
        } else {
            newLikeCount = currentEvent.likeCount + 1
        }
        
        if isCurrentlyLiked {
            FirebaseManager.shared.unlikeEvent(userId: userId, eventId: event.id) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.userLikedEvents.remove(event.id)
                        self?.events[indexPath.row].likeCount = newLikeCount
                        self?.events[indexPath.row].isLiked = false
                        cell.updateLikeCount(newLikeCount, isLiked: false)
                        
                    case .failure(let error):
                        self?.displayMessage("Error", "Failed to unlike event.")
                    }
                }
            }
        } else {
            FirebaseManager.shared.likeEvent(userId: userId, eventId: event.id) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.userLikedEvents.insert(event.id)
                        self?.events[indexPath.row].likeCount = newLikeCount
                        self?.events[indexPath.row].isLiked = true
                        cell.updateLikeCount(newLikeCount, isLiked: true)
                        
                    case .failure(let error):
                        self?.displayMessage("Error", "Failed to like event.")
                    }
                }
            }
        }
    }
        
    private func handleShare(for event: EventData) {
        let shareText = """
        Check out this event! 🎉
        
        \(event.title)
        📅 \(event.postDate)
        📍 \(event.location)
        
        \(event.description)
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(
                x: self.view.bounds.midX,
                y: self.view.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }
        
        present(activityVC, animated: true)
    }
    
    func displayMessage(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
