![image](https://github.com/user-attachments/assets/e3856de1-5b29-4f83-a945-d6ddf5514eec)
# HydroGoal 💧

HydroGoal is an intelligent hydration tracking app designed to make building a healthy habit of drinking water easy, engaging, and accountable. With AI-powered features, personalized goal calculations, and a beautiful interface, HydroGoal ensures you stay hydrated and on track with your health goals.

---

## About The Project

HydroGoal is more than just a water reminder app. It integrates AI-powered proof verification, personalized goal calculation, and a clean, animated interface to provide a comprehensive hydration companion. Built with Flutter and Firebase, it offers a seamless cross-platform experience.

This project includes a full suite of features from user authentication and data persistence to native notifications and integration with the Gemini API for intelligent analysis.

---

### ✨ Key Features

![image](https://github.com/user-attachments/assets/45cddccd-bffa-4145-86a5-db1205ca477b)
- **Animated Onboarding**: A fluid, liquid_swipe introduction to the app for a great first impression.


![image](https://github.com/user-attachments/assets/34024884-d3af-40df-950f-f6bb95d9f75f)
- **Firebase Authentication**: Secure user signup and login using email and password.


![image](https://github.com/user-attachments/assets/012051a3-53a0-4162-a2a4-d202214e0514)
- **Dynamic Dashboard**: A visually appealing home screen with a circular progress meter to track daily water intake.


![image](https://github.com/user-attachments/assets/672f81be-b218-4d1a-a9d8-1f79a7743cde)
- **AI-Powered Hydration Proof**:
  - Log water intake by taking a picture of your water bottle.
  - Uses the Gemini API to verify the image contains a water container.
  - Analyzes the water level in the bottle to estimate the amount consumed.


![image](https://github.com/user-attachments/assets/5524d795-1266-4eaf-a64d-19dca86236fc)
- **Personalized Goal Calculator**: A detailed drawer menu to calculate a recommended daily goal based on:
  - Weight
  - Age
  - Gender
  - Daily Activity Level
  - Climate
 

![image](https://github.com/user-attachments/assets/0f8bdf4d-fddc-42ab-8dd8-7630b2f034ef)
- **Bottle Inventory**: Users can add, manage, and delete their favorite water bottles with specific capacities.


![image](https://github.com/user-attachments/assets/72307380-2eb1-4f41-a4ac-efae786dc8c7)
- **Calendar History**: A full-featured calendar to review historical intake data, with daily log timestamps.


![image](https://github.com/user-attachments/assets/ccbc0a9b-86f1-4771-8405-9d74b1e11d7a)
- **Account Management**: A profile screen showing user details with the ability to upload a profile picture to Firebase Storage.


![image](https://github.com/user-attachments/assets/37ccb623-fffa-46be-9fe0-17e629520212)
- **Custom Reminders**: Users can set and receive local notifications to remind them to hydrate at custom intervals.

  

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

### 👥 Support

If you have any questions or need further assistance, feel free to reach out via [your contact method here].

---

> HydroGoal is here to help you stay hydrated and take care of your health in a smart and engaging way. Let’s drink water, stay healthy, and reach our goals together! 💧
