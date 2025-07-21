# Restaurant-vendor-App
Yaammy is a Flutter-based restaurant management application designed to streamline operations for restaurant owners. Integrated with Firebase for authentication, real-time data storage, and cloud storage, Yaammy provides a comprehensive solution for managing orders, inventory, payouts, and business settings.



Key Features
Authentication & Onboarding:
Secure login/signup via phone number (OTP) and Google Sign-In using Firebase Authentication.
Step-by-step onboarding for collecting owner details, restaurant information, and document uploads (e.g., Aadhaar card).
Firestore-backed user and restaurant data management with collections like RestaurantUsers, Restaurants, and OwnerDetails.
Order Management:
Real-time order tracking with a clean dashboard (home_screen.dart) displaying pending, preparing, and ready orders.
Order history (Order_History.dart) with date filtering, showing detailed order information (items, total amount, pickup time).
Inventory Management:
Manage food items with quantities, prices, and availability status (inventoryItems.dart).
Features include increment/decrement stock, toggle availability, and display inventory stats (total, available, unavailable).
Supports image uploads to Firebase Storage and real-time updates via Firestore.
Business Settings:
Configure daily business hours with multiple time slots (operating_hours_page.dart) using a Cupertino-style time picker.
Manage payout details (payout_settings_screen.dart) with support for UPI ID or bank account details, validated and stored in Firestore.
Contact & Support:
Contact Us page (ContactUsPage.dart) with phone and email options using url_launcher for direct communication.
Displays support hours for user assistance.
Promotions & Discounts:
Create and manage discount codes (PromotionAndDiscountScreen.dart) with customizable parameters (percentage, max discount, min order value).
Tech Stack
Frontend: Flutter with Material Design, Google Fonts (Poppins, BAUHAUSM), and custom widgets for a consistent UI.
Backend: Firebase Authentication, Firestore for real-time database, Firebase Storage for image uploads, Firebase Cloud Messaging (FCM) for push notifications.
Dependencies:
cloud_firestore, firebase_auth, google_sign_in for authentication and data management.
cached_network_image for efficient image loading.
intl for date and currency formatting.
url_launcher for phone calls and emails.
loading_animation_widget for loading states.
Project Structure
lib/:
main.dart: App entry point with Firebase initialization and navigation to LoginPage.
login.dart, otp_verification_screen.dart, otp_input.dart: Authentication flow.
owner_details.dart, document_upload_page.dart: Onboarding screens.
home_screen.dart: Main dashboard for order management.
Order_History.dart: Order history with date filtering.
inventoryItems.dart: Inventory management with real-time updates.
operating_hours_page.dart: Business hours configuration.
payout_settings_screen.dart: Payout details management.
ContactUsPage.dart: Support contact page.
PromotionAndDiscountScreen.dart: Discount code management.
settings_screen.dart: User account settings (email, phone, Google linking).
errormessage.dart: Centralized error handling for Firebase errors.
Firestore Collections:
RestaurantUsers/{uid}: Stores user data, orders, inventory, and owner details.
Restaurants: Restaurant metadata.
UserRestaurantMapping: Links users to restaurants.
UploadedDocuments: Stores document upload details.
Setup Instructions
Prerequisites:
Flutter SDK (latest stable version).
Firebase project with Authentication, Firestore, Storage, and FCM enabled.
Android/iOS emulator or physical device.
Installation:
Clone the repository: git clone https://github.com/username/yaammy-restaurant-app.git
Install dependencies: flutter pub get
Configure Firebase:
Add google-services.json (Android) and GoogleService-Info.plist (iOS) to the respective directories.
Update Firebase configuration in main.dart.
Run the app: flutter run
Firestore Security Rules:
Ensure rules restrict access to authenticated users for RestaurantUsers/{uid}/*.
Example:
plaintext



rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /RestaurantUsers/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
Future Enhancements
Pagination: Implement lazy loading for order history and inventory lists.
Analytics: Add charts to visualize order trends or inventory stock levels using chartjs.
Multi-Day Scheduling: Extend operating_hours_page.dart to support weekly business hours.
Notifications: Enhance FCM to notify users of order updates or low inventory.
Search Functionality: Add filtering for orders and inventory by name or status.
Contributing
Contributions are welcome! Please:

Fork the repository.
Create a feature branch (git checkout -b feature/new-feature).
Commit changes (git commit -m 'Add new feature').
Push to the branch (git push origin feature/new-feature).
Open a pull request.
License
This project is licensed under the MIT License. See the LICENSE file for details.

Contact: For support, reach out at yaammyfood@gmail.com or +91 84360 89071
