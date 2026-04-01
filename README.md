# 📒 Ledger Book App

A professional Flutter application for personal finance management, allowing users to track their income and expenses efficiently. Built with modern Flutter best practices, Firebase for real-time data synchronization, and integrated with Brevo (Sendinblue) for transactional email services.

## 🚀 Features

- **User Authentication**: Secure login and registration using Firebase Authentication.
- **Transaction Tracking**: Add, update, and delete daily financial transactions.
- **Real-time Synchronization**: Data is instantly synced across devices using Cloud Firestore.
- **Data Safety**: Deleted transactions are archived for audit trails.
- **Email Notifications**: Automated transactional emails (e.g., Welcome Emails) using the Brevo API.
- **Visual Analytics**: Interactive charts to visualize spending habits (powered by `fl_chart`).
- **Offline Support**: Local database integration using `sqflite` for robust data handling.
- **Media Support**: Profile image selection using `image_picker`.

## 🛠️ Tech Stack & Architecture

- **Frontend**: Flutter (Dart)
- **State Management**: Provider
- **Backend/Database**: 
  - Firebase Authentication
  - Cloud Firestore (NoSQL)
  - SQLite (Local caching)
- **External APIs**: Brevo (Sendinblue) V3 API
- **Architecture**: MVVM / Service-Repository Pattern

---

## 🔌 API Documentation

This project integrates external APIs to handle communication and notifications. Below is the workflow and configuration for the third-party services.

### 📧 Brevo (Sendinblue) API

The app uses Brevo's V3 API to send transactional emails directly to users (e.g., upon successful registration).

**Base URL**: `https://api.brevo.com/v3`

#### Endpoint: Send Transactional Email
- **URL**: `/smtp/email`
- **Method**: `POST`
- **Headers**:
  - `accept`: `application/json`
  - `content-type`: `application/json`
  - `api-key`: `YOUR_BREVO_API_KEY`

**Request Body Structure**:
```json
{
  "sender": {
    "name": "Ledger Book Support",
    "email": "support@ledgerapp.com"
  },
  "to": [
    {
      "email": "user@example.com",
      "name": "User Name"
    }
  ],
  "subject": "Welcome to Ledger App! 🚀",
  "htmlContent": "<html><body>...</body></html>"
}
```

**Workflow**:
1. User registers in the app.
2. `AuthService` triggers a success callback.
3. `BrevoService` constructs a professional HTML email payload.
4. The payload is sent to Brevo's SMTP endpoint.
5. User receives a formatted Welcome Email.

> **Security Note**: In a production environment, API keys should be secured via a backend proxy (e.g., Firebase Cloud Functions) rather than embedding them directly in the client-side code.

---

## 📂 Project Structure

The project follows a scalable directory structure as follows:

```
lib/
├── core/            # Core utilities, themes, and constants
├── models/          # Data models (e.g., TransactionModel)
├── providers/       # State management logic
├── screens/         # UI Screen widgets (Home, Login, Dashboard)
├── services/        # API and Backend services
│   ├── auth_service.dart       # Firebase Auth handling
│   ├── brevo_service.dart      # Email API integration
│   ├── firestore_service.dart  # Database CRUD operations
│   └── database_service.dart   # Local SQLite persistence
├── widgets/         # Reusable UI components
├── firebase_options.dart # Firebase configuration
└── main.dart        # Application entry point
```

## 🏁 Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- configured Android/iOS environment or Web/Desktop targets.
- A Firebase project.
- A Brevo (Sendinblue) account with an API Key.

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/ledger-book.git
   cd ledger-book
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**:
   - Install CLI: `npm install -g firebase-tools`
   - Activate FlutterFire: `dart pub global activate flutterfire_cli`
   - Configure:
     ```bash
     flutterfire configure
     ```

4. **Setup Environment Variables**:
   - Update `lib/services/brevo_service.dart` with your Brevo API Key (or better, use `--dart-define` for secrets).

5. **Run the App**:
   ```bash
   flutter run
   ```

## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a pull request for any enhancements or bug fixes.

## 📄 License

This specific project source code is available under the MIT License.
