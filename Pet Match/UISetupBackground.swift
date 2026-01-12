//
//  UISetupBackground.swift
//  Pet Match
//
//  Created by Pei-Rung Pan on 11/24/25.
//

import UIKit

extension UITableViewCell {
    
    func setupBackgroundImage() {
        guard let backgroundImage = UIImage(named: "pawprint_background") else {
            return
        }
        
        let backgroundImageView = UIImageView(image: backgroundImage)
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.frame = contentView.bounds
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        contentView.insertSubview(backgroundImageView, at: 0)
    }
}

extension UIViewController {
    
    func setupBackgroundImageViewController() {
        guard let backgroundImage = UIImage(named: "pawprint_background") else {
            print("Falied to laod image")
            return
        }
        
        let backgroundImageView = UIImageView(image: backgroundImage)
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.frame = view.bounds
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(backgroundImageView, at: 0)
        view.backgroundColor = .clear
    }
}

extension UITableViewController {
    
    func setupBackgroundImageTableViewController() {
        guard let backgroundImage = UIImage(named: "pawprint_background") else {
            return
        }
        
        let backgroundImageView = UIImageView(image: backgroundImage)
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        tableView.backgroundView = backgroundImageView
        tableView.backgroundColor = .clear
    }
}
