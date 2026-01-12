//
//  AppDelegate.swift
//  Pet Match
//
//  Created by Ava Pan on 11/4/25.
//

import UIKit
import CoreData
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
                
        checkLoginStatus()
        
        return true
    }
    
    func checkLoginStatus() {
        let isLoggedIn = UserDefaults.standard.string(forKey: "currentUserId") != nil
        
        if isLoggedIn {
            navigateToMainTabBar()
            }
    }
    
    func navigateToMainTabBar() {
           
       let storyboard = UIStoryboard(name: "Main", bundle: nil)
       
       guard let tabBarController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController else {
           return
       }
       
       FirebaseManager.shared.fetchPets { result in
           DispatchQueue.main.async {
               switch result {
               case .success(let pets):
                   
                   if let navController = tabBarController.viewControllers?.first as? UINavigationController {
                       
                       if let petInfoVC = navController.viewControllers.first as? PetInfoViewController {
                        
                           print("Already set up \(pets.count) of pet data")
                       }
                   }
                   self.setRootViewController(tabBarController)
                   
               case .failure(let error):
                   self.setRootViewController(tabBarController)
               }
           }
       }
   }
       
    private func setRootViewController(_ viewController: UIViewController) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            
            window.rootViewController = viewController
            window.makeKeyAndVisible()
            
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
        }
    }
        
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}



