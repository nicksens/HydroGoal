![image](https://github.com/user-attachments/assets/e3856de1-5b29-4f83-a945-d6ddf5514eec)
# HydroGoal 💧

HydroGoal is an intelligent hydration tracking app designed to make building a healthy habit of drinking water easy, engaging, and accountable. With AI-powered features, personalized goal calculations, and a beautiful interface, HydroGoal ensures you stay hydrated and on track with your health goals.

---

## About The Project

HydroGoal is more than just a water reminder app. It integrates AI-powered proof verification, personalized goal calculation, and a clean, animated interface to provide a comprehensive hydration companion. Built with Flutter and Firebase, it offers a seamless cross-platform experience.

This project includes a full suite of features from user authentication and data persistence to native notifications and integration with the Gemini API for intelligent analysis.

---

### ✨ Key Features

1.  **Animated Onboarding**: A fluid, `liquid_swipe` introduction to the app for a great first impression.
    <br>
    <img src="https://github.com/user-attachments/assets/882ed51d-a4ba-47b6-bbe5-014e3314824d" alt="Animated Onboarding" width="350"/>

---

2.  **Firebase Authentication**: Secure user signup and login using email and password.
    <br>
    <img src="https://github.com/user-attachments/assets/67a7c6ea-555b-475e-ba98-3fafd1f5d314" alt="Sign Up Screen" width="350"/>
    <img src="https://github.com/user-attachments/assets/eca0030f-7883-4951-a189-53f73f3a3cb2" alt="Login Screen" width="350"/>

---

3.  **Dynamic Dashboard**: A visually appealing home screen with a circular progress meter to track daily water intake.
    <br>
    <img src="https://github.com/user-attachments/assets/d22c9be3-db7d-4d8c-9083-b637785fee90" alt="Dynamic Dashboard" width="350"/>

---

4.  **AI-Powered Hydration Proof**:
    -   Log water intake by taking a picture of your water bottle.
    -   Uses the Gemini API to verify the image contains a water container.
    -   Analyzes the water level in the bottle to estimate the amount consumed.
    <br>
    <img src="https://github.com/user-attachments/assets/cca6bbbf-ab5c-4be7-86b0-132c0c35e4ed" alt="AI Hydration Proof" width="350"/>

---

5.  **Personalized Goal Calculator**: A detailed drawer menu to calculate a recommended daily goal based on:
    -   Weight
    -   Age
    -   Gender
    -   Daily Activity Level
    -   Climate
    <br>
    <img src="https://github.com/user-attachments/assets/ab47bf83-7377-45b3-93c8-48ddac6c9989" alt="Goal Calculator" width="350"/>

---

6.  **Bottle Inventory**: Users can add, manage, and delete their favorite water bottles with specific capacities.
    <br>
    <img src="https://github.com/user-attachments/assets/b740d945-1b31-432e-9509-7ff5842ef01b" alt="Bottle Inventory" width="350"/>

---

7.  **Calendar History**: A full-featured calendar to review historical intake data, with daily log timestamps.
    <br>
    <img src="https://github.com/user-attachments/assets/91f7b587-477a-43c6-94fc-45b4812c07f8" alt="Calendar History" width="350"/>

---

8.  **Account Management**: A profile screen showing user details with the ability to upload a profile picture to Firebase Storage.
    <br>
    <img src="https://github.com/user-attachments/assets/dd091651-6f24-4f7b-8d43-748f8f9b081b" alt="Account Management" width="350"/>

---

9.  **Custom Reminders**: Users can set and receive local notifications to remind them to hydrate at custom intervals.
    <br>
    <img src="https://github.com/user-attachments/assets/ed362176-3ce3-4573-852a-1b0599357dcf" alt="Custom Reminders" width="350"/>



  

---

### 🛠️ Tech Stack

- **Framework**: Flutter
- **Backend**: Firebase (Authentication, Cloud Firestore, Cloud Storage)
- **AI**: Google Gemini API
- **State Management**: setState (StatefulWidgets)
- **Key Packages**:
  - `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
  - `google_generative_ai` for AI features
  - `flutter_local_notifications` for reminders
  - `image_picker` for camera and gallery access
  - `flutter_animate` & `liquid_swipe` for UI animations
  - `table_calendar` for the history view
  - `percent_indicator` for the progress meter

---

### 🚀 Getting Started

To get a local copy of the project up and running, follow these steps:

1. **Clone the repo**:

   ```bash
   git clone https://github.com/your_username/HydroGoal.git
   ```

2 **Set up Firebase**:
  - Follow the instructions at flutterfire.cli to connect your own Firebase project.
  - Run flutterfire configure to complete the Firebase setup.

3. **Add your Gemini API Key**:
  - Create a .env file in the root of the project.
  - Add your Gemini API key as follows:
    
   ```bash
   GEMINI_API_KEY=YOUR_API_KEY_HERE
   ```

4. **Install packages:**:

   ```bash
   flutter pub get
   ```

5. **Run the app**:

   ```bash
   flutter run
   ```

---

### 🤝 Contributing

Feel free to fork this repo, create a pull request, or open issues if you find any bugs or have suggestions for improvements. Contributions are welcome!

---

### 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for more information.

---

### 👥 Creator

If you have any questions or need further assistance, feel free to reach out to:
- Hernicksen Satria (hernicksen.satria@binus.ac.id)
- Lawryan Andrew Darisang (lawryan.darisang@binus.ac.id)

---

> HydroGoal is here to help you stay hydrated and take care of your health in a smart and engaging way. Let’s drink water, stay healthy, and reach our goals together! 💧
