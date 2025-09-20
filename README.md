# WellWiz

A comprehensive health and wellness Flutter application that provides mental health support, medical assistance, and personalized health tracking features.

## Overview

WellWiz is an all-in-one health assistant app designed to help users manage their mental well-being, track health metrics, and access medical resources. The app combines AI-powered chat functionality with practical health tools and breathing exercises.

## Features

### Mental Health & Wellness
- **Breathing Exercises**: 8 different breathing techniques including Deep, Box, 4-7-8, Alternate Nostril, Happy, Calm Down, Stress Relief, and Relaxed Mind
- **Emotion Tracking**: Monitor and track emotional states with visual feedback
- **AI Chat Bot**: Powered by Google Gemini AI for mental health support and general assistance
- **Thought Sharing**: Share and view positive thoughts from the community
- **Social Features**: Chat rooms for community support

### Medical & Health Tracking
- **Health Metrics Scanner**: Scan medical reports and extract health metrics using AI
- **Report Analysis**: Support for various medical reports including CBC, LFT, KFT, Lipid Profile, Blood Sugar, Thyroid Profile, and more
- **Nearby Hospitals**: Find hospitals within 1km, 5km, and 20km radius with ratings
- **Prescription Management**: Track and manage medication prescriptions
- **Health Traits**: Monitor personal health characteristics and patterns

### Emergency & Safety
- **SOS Alert System**: Quick access to emergency contacts and services
- **Emergency Contacts**: Manage emergency contact information
- **Location-based Services**: Find nearby medical facilities

### User Management
- **Google Sign-in**: Secure authentication with Google accounts
- **User Profiles**: Customizable user profiles with handles and personal information
- **Onboarding**: Comprehensive app tour with permission requests
- **Account Management**: Edit profile information and manage account settings

### Additional Features
- **Reminders**: Set up medication and health reminders
- **Notifications**: Push notifications for important health updates
- **Offline Support**: Local data storage and caching
- **Background Services**: Health monitoring in the background

## Technical Stack

- **Framework**: Flutter 3.8.1+
- **State Management**: Riverpod
- **Backend**: Firebase (Authentication, Firestore, Cloud Messaging)
- **AI Integration**: Google Generative AI (Gemini)
- **Maps & Location**: Geolocator
- **Audio**: AudioPlayers for breathing exercises
- **Animations**: Lottie animations
- **Caching**: Flutter Cache Manager
- **Notifications**: Flutter Local Notifications, WorkManager

## Setup

### Prerequisites
- Flutter SDK 3.8.1 or higher
- Dart SDK
- Android Studio / VS Code
- Firebase project setup
- Google Cloud Console project for Gemini AI

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd wellwiz
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project
   - Enable Authentication, Firestore, and Cloud Messaging
   - Download `google-services.json` for Android
   - Download `GoogleService-Info.plist` for iOS
   - Place them in the respective platform directories

4. **API Keys Setup**
   - Create a `lib/secrets.dart` file
   - Add your API keys:
   ```dart
   const String geminikey = 'your-gemini-api-key';
   const String clientid = 'your-google-client-id';
   ```

5. **Permissions**
   - The app requires permissions for camera, location, contacts, SMS, and notifications
   - These are requested during the onboarding process

6. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── secrets.dart             # API keys and secrets
├── chat/                    # AI chat functionality
├── doctor/                  # Medical features and health tracking
├── mental_peace/           # Mental health and breathing exercises
├── quick_access/           # Quick access features and account management
├── login/                  # Authentication and user onboarding
├── globalScaffold/         # Main app navigation and layout
├── onboarding/             # App tour and permission requests
├── providers/              # Riverpod state management
└── utils/                  # Utility functions and services
```

## Key Dependencies

- `firebase_core`: Firebase integration
- `firebase_auth`: User authentication
- `cloud_firestore`: Database operations
- `google_generative_ai`: AI chat functionality
- `flutter_riverpod`: State management
- `geolocator`: Location services
- `audioplayers`: Audio playback for exercises
- `lottie`: Animations
- `image_picker`: Camera functionality
- `permission_handler`: Permission management
- `workmanager`: Background tasks
- `flutter_local_notifications`: Local notifications

## Usage

1. **First Time Setup**: Complete the onboarding process and grant necessary permissions
2. **Sign In**: Use Google Sign-in to create or access your account
3. **Mental Health**: Access breathing exercises and emotion tracking
4. **Health Tracking**: Scan medical reports and track health metrics
5. **Emergency**: Set up emergency contacts and SOS features
6. **AI Assistant**: Chat with the AI bot for health advice and support

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is private and not intended for public distribution.

## Support

For support and questions, please contact the development team.
