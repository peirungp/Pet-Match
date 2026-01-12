//
//  EventTableViewCell.swift
//  Pet Match
//
//  Created by Pei-Rung Pan on 11/21/25.
//

import Foundation
import UIKit

class PetEventTableView: UITableViewCell {
    
    private var imageViews: [UIImageView] = []
    private var imageUrls: [String] = []
    
    @IBOutlet weak var imageScrollView: UIScrollView!
    @IBOutlet weak var imagePageControl: UIPageControl!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var postDateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var shareButton: UIButton!
    
    var onLikeButton: (() -> Void)?
    var onShareButton: (() -> Void)?
       
    override func awakeFromNib() {
        super.awakeFromNib()
        setupBackgroundImage()
        setupUI()
        setupScrollView()
    }
       
    private func setupUI() {
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel?.numberOfLines = 2
        titleLabel?.textColor = .label
           
        postDateLabel?.font = UIFont.systemFont(ofSize: 14)
        postDateLabel?.textColor = .systemGray
        postDateLabel?.numberOfLines = 1
           
        locationLabel?.font = UIFont.systemFont(ofSize: 14)
        locationLabel?.textColor = .systemGray
        locationLabel?.numberOfLines = 1
           
        descriptionTextView?.font = UIFont.systemFont(ofSize: 14)
        descriptionTextView?.textColor = .label
        descriptionTextView?.isEditable = false
        descriptionTextView?.isScrollEnabled = false
        descriptionTextView?.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        descriptionTextView?.backgroundColor = .systemGray6
        descriptionTextView?.layer.cornerRadius = 8
           
        likeCountLabel?.font = UIFont.systemFont(ofSize: 14)
        likeCountLabel?.textColor = .label
           
        imagePageControl?.currentPageIndicatorTintColor = .systemBlue
        imagePageControl?.pageIndicatorTintColor = .systemGray4
        imagePageControl?.addTarget(self, action: #selector(pageControlChanged), for: .valueChanged)
           
        setupButtons()
    }
       
    private func setupScrollView() {
        imageScrollView?.delegate = self
        imageScrollView?.isPagingEnabled = true
        imageScrollView?.showsHorizontalScrollIndicator = false
        imageScrollView?.showsVerticalScrollIndicator = false
        imageScrollView?.backgroundColor = .systemGray6
        imageScrollView?.layer.cornerRadius = 12
        imageScrollView?.clipsToBounds = true
    }
       
    private func setupButtons() {
        likeButton?.setImage(UIImage(systemName: "hand.thumbsup"), for: .normal)
        likeButton?.setImage(UIImage(systemName: "hand.thumbsup.fill"), for: .selected)
        likeButton?.tintColor = .systemBlue
        likeButton?.backgroundColor = .clear
        likeButton?.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
           
        shareButton?.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButton?.tintColor = .systemBlue
        shareButton?.backgroundColor = .clear
        shareButton?.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
    }
       
    @objc private func likeButtonTapped() {
        onLikeButton?()
    }
       
    @objc private func shareButtonTapped() {
        onShareButton?()
    }
       
    @objc private func pageControlChanged() {
        let pageWidth = imageScrollView.frame.width
        let offset = CGFloat(imagePageControl.currentPage) * pageWidth
        imageScrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: true)
    }
       
    func configure(with event: EventData) {
        titleLabel?.text = event.title
        postDateLabel?.text = "\(event.postDate)"
        locationLabel?.text = "📍 \(event.location)"
        descriptionTextView?.text = event.description
           
        let displayCount = max(0, event.likeCount)
        likeCountLabel?.text = "\(displayCount)"
        likeButton?.isSelected = event.isLiked
                      
        if let imageUrls = event.imageUrls, !imageUrls.isEmpty {
            setupImages(with: imageUrls)
        } else {
            addPlaceholderImage()
        }
    }
       
    private func setupImages(with urls: [String]) {
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()
        imageUrls = urls
           
        guard !urls.isEmpty else {
            addPlaceholderImage()
            return
        }
           
        imagePageControl?.numberOfPages = urls.count
        imagePageControl?.currentPage = 0
        imagePageControl?.isHidden = urls.count <= 1
           
        let scrollViewWidth = imageScrollView.frame.width
        let scrollViewHeight = imageScrollView.frame.height
        imageScrollView.contentSize = CGSize(
            width: scrollViewWidth * CGFloat(urls.count),
            height: scrollViewHeight
        )
           
        for (index, urlString) in urls.enumerated() {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.backgroundColor = .systemGray5
               
            let xPosition = scrollViewWidth * CGFloat(index)
            imageView.frame = CGRect(
                x: xPosition,
                y: 0,
                width: scrollViewWidth,
                height: scrollViewHeight
            )
                              
            imageScrollView.addSubview(imageView)
            imageViews.append(imageView)
               
            loadImageFromFirebase(urlString: urlString, into: imageView, at: index)
        }
    }
       
    private func addPlaceholderImage() {
        imagePageControl?.numberOfPages = 1
        imagePageControl?.currentPage = 0
        imagePageControl?.isHidden = true
           
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .systemGray3
        imageView.backgroundColor = .systemGray5
        imageView.frame = imageScrollView.bounds
           
        imageScrollView.addSubview(imageView)
        imageViews.append(imageView)
        imageScrollView.contentSize = imageScrollView.bounds.size
    }
       
    private func loadImageFromFirebase(urlString: String, into imageView: UIImageView, at index: Int) {
         let activityIndicator = UIActivityIndicatorView(style: .medium)
         activityIndicator.center = CGPoint(
             x: imageView.bounds.width / 2,
             y: imageView.bounds.height / 2
         )
         activityIndicator.startAnimating()
         imageView.addSubview(activityIndicator)
                  
         FirebaseManager.shared.downloadImage(from: urlString) { image in
             DispatchQueue.main.async {
                 activityIndicator.stopAnimating()
                 activityIndicator.removeFromSuperview()
                 
                 if let image = image {
                     imageView.image = image
                     imageView.contentMode = .scaleAspectFill
                 } else {
                     imageView.image = UIImage(systemName: "photo")
                     imageView.tintColor = .systemGray3
                     imageView.contentMode = .scaleAspectFit
                 }
             }
         }
     }
       
    func updateLikeCount(_ count: Int, isLiked: Bool) {
        likeCountLabel?.text = "\(count)"
        likeButton?.isSelected = isLiked
           
        UIView.animate(withDuration: 0.2, animations: {
            self.likeButton?.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.likeButton?.transform = .identity
            }
        }
    }
       
    override func prepareForReuse() {
        super.prepareForReuse()
           
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()
        imageUrls.removeAll()
           
        imageScrollView?.contentOffset = .zero
        imageScrollView?.contentSize = .zero
           
        titleLabel?.text = ""
        postDateLabel?.text = ""
        locationLabel?.text = ""
        descriptionTextView?.text = ""
        likeCountLabel?.text = "0"
        likeButton?.isSelected = false
        imagePageControl?.numberOfPages = 0
        imagePageControl?.currentPage = 0
           
        onLikeButton = nil
        onShareButton = nil
    }
}

// MARK: - UIScrollViewDelegate
extension PetEventTableView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.width
        let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)
       
        if currentPage >= 0 && currentPage < imagePageControl.numberOfPages {
            imagePageControl.currentPage = currentPage
        }
    }
}
