![image](https://github.com/user-attachments/assets/e3856de1-5b29-4f83-a945-d6ddf5514eec)
# HydroGoal 💧

HydroGoal is an intelligent hydration tracking app designed to make building a healthy habit of drinking water easy, engaging, and accountable. With AI-powered features, personalized goal calculations, and a beautiful interface, HydroGoal ensures you stay hydrated and on track with your health goals.

---

## About The Project

HydroGoal is more than just a water reminder app. It integrates AI-powered proof verification, personalized goal calculation, and a clean, animated interface to provide a comprehensive hydration companion. Built with Flutter and Firebase, it offers a seamless cross-platform experience.

This project includes a full suite of features from user authentication and data persistence to native notifications and integration with the Gemini API for intelligent analysis.

---

### ✨ Key Features

1. **Animated Onboarding**: A fluid, `liquid_swipe` introduction to the app for a great first impression.

![WhatsApp Image 2025-07-06 at 10 29 40_9ff3313b](https://github.com/user-attachments/assets/86e2461e-2fe9-48ad-a39c-d0eeaf418a36)



2. **Firebase Authentication**: Secure user signup and login using email and password.

![WhatsApp Image 2025-07-06 at 10 29 40_0f885828](https://github.com/user-attachments/assets/67a7c6ea-555b-475e-ba98-3fafd1f5d314) ![image](https://github.com/user-attachments/assets/eca0030f-7883-4951-a189-53f73f3a3cb2)




3.   **Dynamic Dashboard**: A visually appealing home screen with a circular progress meter to track daily water intake.

![WhatsApp Image 2025-07-06 at 10 29 40_04c680f7](https://github.com/user-attachments/assets/22f6fa8c-0e3d-4e83-b773-64da903d49fd)




4.  **AI-Powered Hydration Proof**:
    -   Log water intake by taking a picture of your water bottle.
    -   Uses the Gemini API to verify the image contains a water container.
    -   Analyzes the water level in the bottle to estimate the amount consumed.

![WhatsApp Image 2025-07-06 at 10 29 41_e0862518](https://github.com/user-attachments/assets/e3834206-1831-4a15-93f7-5095873dcb8a)


5.  **Personalized Goal Calculator**: A detailed drawer menu to calculate a recommended daily goal based on:
    -   Weight
    -   Age
    -   Gender
    -   Daily Activity Level
    -   Climate
    
![WhatsApp Image 2025-07-06 at 10 29 43_2895b5c0](https://github.com/user-attachments/assets/b8e0bbe9-e001-4d70-97a9-df1cc5fda626)


6. **Bottle Inventory**: Users can add, manage, and delete their favorite water bottles with specific capacities.

![WhatsApp Image 2025-07-06 at 10 29 44_bae18052](https://github.com/user-attachments/assets/f970a70e-f55f-4146-bf72-0c432166065e)


7.  **Calendar History**: A full-featured calendar to review historical intake data, with daily log timestamps.

![WhatsApp Image 2025-07-06 at 10 29 47_20fee635](https://github.com/user-attachments/assets/59c9a739-b98d-49f4-99f3-524065d8feaa)



8.  **Account Management**: A profile screen showing user details with the ability to upload a profile picture to Firebase Storage.

![WhatsApp Image 2025-07-06 at 10 29 54_3e325a22](https://github.com/user-attachments/assets/45f62232-ea0f-4758-a204-dd982737e3dc)



9.  **Custom Reminders**: Users can set and receive local notifications to remind them to hydrate at custom intervals.

![WhatsApp Image 2025-07-06 at 10 30 09_05b6bb07](https://github.com/user-attachments/assets/486c9e59-64e4-4d89-b856-4a9d117fd208)



  

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
