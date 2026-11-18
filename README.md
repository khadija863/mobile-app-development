# 🍲 FoodLink – Food Donation & Sharing Platform

**FoodLink** is a Flutter-based mobile application designed to reduce food waste by connecting food donors with people who need food. It provides a platform where users can donate surplus food, browse available donations, request food, and manage donation activities.

The application uses Firebase for authentication and real-time data management.

## 🎯 Project Objectives

- Reduce food waste by encouraging food sharing.
- Connect food donors with food receivers.
- Make food donation and collection management easier.
- Provide a user-friendly platform for managing food requests.
- Support transparent and organized donation activities.

## ✨ Key Features

- **Firebase Authentication** – Secure user registration and login.
- **Role-Based Dashboards** – Separate dashboards for Admin, Donor, Receiver, and Volunteer.
- **Food Donation Management** – Donors can create and manage food donations.
- **Browse Available Food** – Receivers can explore available food donations.
- **Request Management** – Receivers can request food, while donors can accept or reject requests.
- **Collection Management** – Manage assigned food collections.
- **In-App Notifications** – Receive updates about donation and request activities inside the application.
- **User Profile Management** – View and update user profile information.
- **Admin Dashboard** – Manage users, donations, requests, and platform activities.
- **Activity Logs** – Maintain records of important platform activities.

## 👥 User Roles

| Role | Responsibilities |
|---|---|
| Admin | Manage users, donations, requests, and platform activities. |
| Donor | Donate surplus food and manage incoming requests. |
| Receiver | Browse available food and submit food requests. |
| Volunteer | Support food collection and distribution activities. |

## 🛠️ Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform mobile application development |
| Dart | Programming language |
| Firebase Authentication | User authentication |
| Cloud Firestore | Database and real-time data management |
| Android Studio | Development environment |
| Visual Studio Code | Code editor |
| Git & GitHub | Version control and collaboration |

## 📱 Application Screens & Modules

- Splash & Welcome Screen
- Login & Registration
- Role Selection
- Admin Dashboard
- Donor Dashboard
- Receiver Dashboard
- Volunteer Dashboard
- Add Food Donation
- Browse Food
- My Donations
- My Requests
- Incoming Requests
- Available Collections
- My Collections
- Manage Users
- Manage Donations & Requests
- Notifications
- User Profile
- Edit Profile
- Delivery Task

## 📸 Application Screenshots

Explore the user interface of FoodLink and its role-based features.

### 🏠 Welcome & Role Selection

**Welcome Screen**

![Welcome Screen](screenshots/welcome%20screen.jpeg)

**Role Selection**

![Role Selection](screenshots/role%20selection.jpeg)

### 👨‍💼 Admin Dashboard

![Admin Dashboard](screenshots/admin%20dashboard.jpeg)

### 🍱 Donor Dashboard & Food Donation

**Donor Dashboard**

![Donor Dashboard](screenshots/donor%20dashboard.jpeg)

**Food Donation Screen**

![Food Donation Screen](screenshots/food%20donation%20screen.jpeg)

### 🤝 Receiver Dashboard & Requests

**Receiver Dashboard**

![Receiver Dashboard](screenshots/Receiver%20dashboard.jpeg)

**My Requests Screen**

![Receiver My Requests](screenshots/Reciver%20My%20request%20screen.jpeg)

### 🚚 Volunteer Dashboard & Delivery

**Volunteer Dashboard**

![Volunteer Dashboard](screenshots/volunteer%20dashboard.jpeg)

**Delivery Task Screen**

![Delivery Task](screenshots/delivery%20task%20screen.jpeg)

### 🔔 Notifications

![Notification Screen](screenshots/Notification%20screen.jpeg)

### 👤 User Profile

**Profile Screen**

![Profile Screen](screenshots/profile%20screen.jpeg)

**Edit Profile Screen**

![Edit Profile Screen](screenshots/Edit%20profile%20screen.jpeg)

## 📂 Project Structure

```text
foodlink/
│
├── android/
├── ios/
├── lib/
│   ├── models/
│   ├── screens/
│   ├── services/
│   ├── firebase_options.dart
│   └── main.dart
│
├── macos/
├── web/
├── windows/
│
├── screenshots/
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

## ⚙️ Installation & Setup

### Prerequisites

Make sure the following tools are installed:

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- Git
- A configured Firebase project

### 1. Clone the Repository

```bash
git clone https://github.com/khadija863/mobile-app-development.git
```

### 2. Navigate to the Project Directory

```bash
cd mobile-app-development
```

### 3. Get Dependencies

```bash
flutter pub get
```

### 4. Firebase Configuration

The application uses Firebase Authentication and Cloud Firestore.

To configure Firebase for your environment:

- Connect the project to your Firebase project.
- Configure Firebase for your target platform.
- Ensure the required Firebase configuration files are available.
- Enable Firebase Authentication and Cloud Firestore.

### 5. Run the Application

Connect an Android device or start an emulator, then run:

```bash
flutter run
```

## 🔔 Notification System

FoodLink includes an in-app notification system to keep users informed about important activities, including:

- New food requests
- Request acceptance
- Request rejection
- Request cancellation
- Donation and collection updates

Notifications are displayed inside the application.

## 🔥 Backend & Database

FoodLink uses Firebase services:

- **Firebase Authentication:** Handles user registration and login.
- **Cloud Firestore:** Stores user information, donations, requests, collections, notifications, and activity logs.

## 🚀 Future Improvements

- Enhanced food donation and collection tracking.
- Improved volunteer coordination.
- Better reporting and platform analytics.
- Additional user experience improvements.

## 👨‍💻 Development Team

**Project Name:** FoodLink  
**Project Type:** Mobile Application Development  
**Platform:** Android (Flutter)

## 📄 License

This project was developed for academic and educational purposes.

---

### ❤️ FoodLink
**Share Food, Spread Kindness, Reduce Waste.**
