# Smart Pass 🎟️

**A Digital Event Ticketing and Verification Platform**

## 1. Project Overview

Smart Pass is a digital ticketing platform designed to make event discovery, ticket management and event entry easier and more secure.

The platform connects event organisers with customers, allowing organisers to publish events and customers to discover available events and purchase tickets remotely.

## 2. Problem Statement

Traditional event ticketing often involves physical tickets, long queues, difficulties with remote purchases and the risk of fake or duplicated tickets.

Smart Pass aims to address these challenges through a digital ticketing system.

## 3. Our Solution

Smart Pass provides a central platform where:
- Customers can discover available events.
- Organisers can create and manage events.
- Administrators can review and approve submitted events.
- Attendants can verify tickets at event entrances.

## 4. Key Features

- User registration and login.
- Role-based access for different users.
- Event creation and management.
- Event approval by administrators.
- Published event discovery for customers.
- Event details viewing.
- Digital ticket purchasing and QR verification (under development).

## 5. User Roles

| Role | Responsibilities |
|---|---|
| Customer | Discover events and purchase tickets |
| Organiser | Create and manage events |
| Attendant | Verify tickets at event entrances |
| Administrator | Manage and approve platform events |

## 6. Technologies Used

- **Flutter:** Mobile application development.
- **Dart:** Application programming language.
- **Firebase Authentication:** User authentication.
- **Cloud Firestore:** Database and event management.

## 7. Getting Started

### Prerequisites

Before running the project, install:

- Flutter SDK
- Dart SDK (included with Flutter)
- Android Studio or Visual Studio Code
- Git

### Installation

1. Clone the repository:

   ```bash
  git clone https://github.com/RighteousCoder/smartpass.git
   ```

2. Navigate into the project folder:

   ```bash
   cd smart_pass
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Run the application:

   ```bash
   flutter run
   ```

**Note:** Firebase configuration is required to connect the application to its Firebase project.

## 8. Current Development Status

The following features have been implemented:

- User registration and authentication.
- Customer, organiser and administrator dashboards.
- Event creation and submission.
- Administrator event approval and rejection.
- Published event discovery.
- Event details viewing.

## 9. Planned Improvements

- Ticket purchasing and payment integration.
- Unique digital ticket generation.
- QR code generation and scanning.
- Ticket verification and duplicate-use prevention.
- Attendant accounts and event assignments.
- Ticket history and sales tracking.

## 10. Project Purpose

Smart Pass aims to make event ticketing more accessible, convenient and reliable through digital technology.
