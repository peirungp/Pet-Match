# PetMatch 

## Problem Description & Solution

Problem Description:
  Many animal shelters might struggle to find suitable adopters, while potential pet owners often have difficulty finding pets that match their lifestyle and preferences. This makes the adoption process inefficient and lacks personalized matching, requiring multiple shelter visits and resulting in low adoption rates. As a result, animals face longer stays in shelters, miss opportunities to find their families, and shelters have limited space for incoming stray animals.


Problem Solution:
  The PetMatch application serves as a centralized platform connecting multiple animal shelters and private rescues across different regions. Each shelter and rescuer can independently manage their pet listings through administrator accounts that are set up and approved by a Super Administrator, while users benefit from a unified browsing experience across all participating shelters. Potential adopters can use filters based on their location and preferences to quickly find their ideal companion. 

  Adopters must register an account and provide basic personal information. They can use filters such as shelter location, animal type, and detailed characteristics to find pets that match their preference. Adopters can also view events posted by adoption centers, like, share and save their favorite pet for later visits. A “favorite” feature allows users to bookmark pets they are interested in. In addition, the app includes a map feature so users can locate shelters and use provided shelter information to schedule visits or adoption appointments.

  For shelters and private rescuers, the app makes the process more efficient. Administrators can easily add or update animal profiles and post interactive events to attract more potential adopters.

### Tech Stack
- Frontend: UIKit 
- Backend: Firebase

#### Features
* --User Features--
- Pet Information & Filtering Across Regions
  - Browse pet profiles with photos, detailed information, and location (Built-In MAPKit and CoreLocation)
  - Real-time filter
  - Complete pet stories and descriptions
  
- Favorite List
  - Link to detailed pet profiles and direct map integration showing shelter locations
  - Save favorite pets for later review
  
- Events & Community Connecting Features 
  - View and participate in adoption events
  - Like and share events with friends
  - Multi-image carousel for event galleries
  - Real-time like count updates
  
- Profile Management
  - Upload and manage profile pictures
  - Track favorite pets across sessions
  - Edit contact information

* --Admin Features--
- Super & Sub Admin Controls
  - Role-based access through Firebase Authentication
  - Manage button in profile with dropdown menu
  - Secure edit/delete operations
  - Swipe actions for quick management
  
- Event Management
  - Create adoption events with multiple images
  - Edit event details and schedules
  - Delete past events
  - Support for multi-image event galleries

- Event Management
  - Pet Management
  - Add new pets with comprehensive information
  - Edit existing pet profiles
  - Upload and manage pet photos
  - Delete pets that have been adopted








