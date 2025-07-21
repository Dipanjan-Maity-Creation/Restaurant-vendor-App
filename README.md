# 🍽️ Yaammy – Restaurant Partner App

**Yaammy Restaurant Partner App** is a full-featured Flutter-based mobile application that empowers restaurant owners to seamlessly manage orders, inventory, working hours, promotions, and more—all in real-time with Firebase integration.

Built for speed, simplicity, and scalability, Yaammy is part of a comprehensive delivery ecosystem that includes customer, delivery partner, and admin apps.

---

## 🚀 Key Features

### 🔐 Authentication & Onboarding
- Secure login/signup via **phone OTP** and **Google Sign-In**
- Step-by-step onboarding to collect owner info, restaurant details, and document uploads
- Firestore collections: `RestaurantUsers`, `Restaurants`, `OwnerDetails`

### 🧾 Order Management
- Real-time order dashboard: **Pending**, **Preparing**, and **Ready**
- Detailed order history with filters, item breakdown, and pickup info

### 📦 Inventory Management
- Add/manage food items with images, pricing, stock, and availability toggle
- Instant updates via **Firestore** and **Firebase Storage**
- Inventory summary: total, available, and out-of-stock items

### 🛠 Business Settings
- Set business hours using Cupertino-style time selectors
- Update payout details (UPI/Bank) directly from the app

### 🎁 Promotions & Discounts
- Create and manage promo codes:
  - Percentage discount
  - Max discount limit
  - Minimum order value validation

### 📞 Contact & Support
- Integrated email and phone support
- Display support hours and info

---

## 🧱 Tech Stack

| Layer      | Technology |
|------------|------------|
| Frontend   | Flutter (Dart), Material Design |
| Backend    | Firebase Auth, Firestore, Firebase Storage, Cloud Messaging |
| Fonts/UI   | Google Fonts (Poppins, BAUHAUSM), Custom Widgets |
| Packages   | `cloud_firestore`, `firebase_auth`, `google_sign_in`, `intl`, `url_launcher`, `cached_network_image`, `loading_animation_widget` |

---

## 🗂️ Project Structure

