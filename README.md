# FashionHub

FashionHub is a Flutter and Firebase application for fashion commerce and styling workflows. It brings together customers, tailors, fabric sellers, and shop owners in one app for browsing products, managing orders, measuring garments, chatting, and handling social-style discovery.

## Overview

The app uses Firebase for authentication, Firestore for data storage, Cloud Storage for media, Remote Config for dynamic settings, and Cloud Functions for backend automation. The Flutter app is structured around role-based experiences and a shared feed/home flow.

## Features

- Authentication and profile management
- Customer and tailor dashboards
- Product, fabric, and shop browsing
- Order creation and order tracking
- Measurement capture and history
- Chat and connection features
- Remote configuration and Firebase App Check support
- Media upload and preview flows for images, video, and audio

## Requirements

- Flutter SDK 3.10 or later
- Dart SDK compatible with the version in `pubspec.yaml`
- Firebase CLI if you plan to deploy backend resources
- Node.js 24 for the `functions/` project

## Setup

1. Install Flutter dependencies:

	```bash
	flutter pub get
	```

2. Install Cloud Functions dependencies if you will run or deploy them:

	```bash
	cd functions
	npm install
	```

3. Make sure the Firebase configuration matches your project.

	This repository already includes `lib/firebase_options.dart` and `android/app/google-services.json` for the configured Firebase project. If you are using a different Firebase project, regenerate those files with FlutterFire and update the Android Firebase config.

## Run

Start the app with Flutter:

```bash
flutter run
```

If you want to target a specific device, use:

```bash
flutter devices
flutter run -d <device_id>
```

## Backend and Firebase

The repository includes Firebase configuration and deployment files for:

- Firestore rules: `firestore.rules`
- Firestore indexes: `firestore.indexes.json`
- Storage rules: `storage.rules`
- Cloud Functions: `functions/`

To deploy backend resources, use the Firebase CLI from the project root. A typical deployment looks like:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

## Project Structure

- `lib/` contains the Flutter application code
- `lib/screens/` contains the UI screens for the different app flows
- `lib/services/` contains Firebase and app service integrations
- `lib/theme/` contains shared theme and styling
- `functions/` contains Firebase Cloud Functions
- `assets/` contains app assets such as images and the launcher icon

## Notes

- The app title is `FashionHub`.
- The main entry point is `lib/main.dart`.
- The app currently supports multiple platforms through Flutter, with Firebase configuration already set up for the project.

## Helpful Commands

```bash
flutter clean
flutter pub get
flutter run
firebase deploy --only functions
```
