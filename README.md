🍽️ Yaammy – Restaurant Partner App
The Yaammy Restaurant Partner App is a powerful Flutter-based application that enables restaurant owners to manage orders, inventory, business hours, and promotions, all within an intuitive, real-time interface integrated with Firebase.

🚀 Key Features
🔐 Authentication & Onboarding
Secure login/signup via phone OTP and Google Sign-In using Firebase Authentication.

Step-by-step onboarding flow to collect owner details, restaurant info, and document uploads (e.g., Aadhaar).

Firestore-based user management with collections like RestaurantUsers, Restaurants, and OwnerDetails.

🧾 Order Management
Real-time order tracking via home_screen.dart — sections for Pending, Preparing, and Ready orders.

Comprehensive Order_History.dart view with date filtering, showing order details like items, total amount, and pickup time.

📦 Inventory Management
Add/manage food items with images, price, stock quantity, and availability toggle (inventoryItems.dart).

Real-time updates and image storage via Firebase Storage and Firestore.

Inventory analytics: view total, available, and unavailable items instantly.

🛠️ Business Settings
Set business hours using multi-slot time selection (operating_hours_page.dart) with Cupertino-style time pickers.

Update payout details (UPI/bank) in payout_settings_screen.dart, fully integrated with Firestore for validation and storage.

📞 Contact & Support
ContactUsPage.dart: Call or email support using url_launcher.

Displays support hours for transparency.

🎁 Promotions & Discounts
Create, manage, and validate custom discount codes (PromotionAndDiscountScreen.dart) with:

Percentage discount

Max discount limit

Minimum order value

🧱 Tech Stack
Layer	Tech Used
Frontend	Flutter (Dart), Material Design
Backend	Firebase Auth, Firestore, Firebase Storage, Firebase Cloud Messaging
Fonts/UI	Google Fonts (Poppins, BAUHAUSM), Custom Widgets
Packages	cloud_firestore, firebase_auth, google_sign_in, intl, url_launcher, cached_network_image, loading_animation_widget

🗂️ Project Structure
plaintext
Copy
Edit
lib/
│
├── main.dart                     # Entry point with Firebase initialization
├── login.dart                    # Phone/Google sign-in logic
├── otp_verification_screen.dart  # OTP input and verification
├── owner_details.dart            # Restaurant owner info input
├── document_upload_page.dart     # KYC and restaurant document upload
│
├── home_screen.dart              # Real-time order dashboard
├── Order_History.dart            # Order history with filters
│
├── inventoryItems.dart           # Inventory control screen
├── add_menu_item_screen.dart     # Add new food items
│
├── operating_hours_page.dart     # Set business hours
├── payout_settings_screen.dart   # Add/update bank or UPI details
│
├── PromotionAndDiscountScreen.dart # Discount management
├── ContactUsPage.dart            # Contact support
│
├── settings_screen.dart          # Account preferences
├── errormessage.dart             # Centralized error mapping
🔐 Firestore Structure
plaintext
Copy
Edit
RestaurantUsers/{uid}/...     → Per-user data: orders, inventory, documents
Restaurants                   → General restaurant info
UserRestaurantMapping         → Links users to restaurant profiles
UploadedDocuments             → Stores uploaded images (Aadhaar, license, etc.)
🧰 Setup Instructions
✅ Prerequisites
Flutter SDK (latest stable)

Firebase project with:

Authentication

Firestore

Cloud Storage

Cloud Messaging

🛠 Installation
bash
Copy
Edit
git clone https://github.com/username/yaammy-restaurant-app.git
cd yaammy-restaurant-app
flutter pub get
Add google-services.json (Android) and GoogleService-Info.plist (iOS) to appropriate directories.

Run the app:

bash
Copy
Edit
flutter run
🔒 Firestore Security Rules
plaintext
Copy
Edit
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /RestaurantUsers/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
📈 Future Enhancements
📊 Analytics: Add charts for order trends, inventory usage

🔍 Search & Filtering: Filter orders and inventory by status or item name

⏳ Pagination: Lazy load for large order/inventory lists

📆 Weekly Scheduling: Extend operating_hours_page.dart to support full-week scheduling

🔔 Notifications: Expand FCM integration for order updates, low stock alerts

🤝 Contributing
We welcome contributions!
To contribute:

Fork the repository

Create a new branch:
git checkout -b feature/your-feature-name

Make changes and commit:
git commit -m "Add your feature"

Push your branch:
git push origin feature/your-feature-name

Open a Pull Request 🚀

📄 License
This project is licensed under the MIT License.
See the LICENSE file for details.

📬 Contact
📧 Email: yaammyfood@gmail.com
📞 Phone: +91 84360 89071
