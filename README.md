# FITFUEL AI - Project Documentation

## 📱 Project Overview

**FITFUEL AI** is a premium, production-grade Flutter application for AI-powered calorie tracking and nutrition coaching. The app is designed to look like a $100M startup product with enterprise-level architecture.

## 🏗️ Architecture

### Clean Architecture Principles
- **Separation of Concerns**: Clear separation between UI, business logic, and data layers
- **Testability**: All layers are independently testable
- **Scalability**: Ready to scale to 1M+ users
- **Maintainability**: Easy to modify and extend

### Layers

1. **Presentation Layer** (`features/*/presentation`)
   - Pages (Full screens)
   - Widgets (Reusable UI components)
   - BLoC (State management)

2. **Domain Layer** (`features/*/domain`)
   - Entities (Business logic objects)
   - Repositories (Abstract interfaces)
   - Use Cases (Business logic operations)

3. **Data Layer** (`features/*/data`)
   - Models (API/DB objects)
   - Data Sources (Remote & Local)
   - Repository Implementation

4. **Core Layer** (`lib/core`)
   - Configuration
   - Constants
   - Utilities
   - Services

5. **Shared Layer** (`lib/shared`)
   - Reusable Widgets
   - Theme
   - Common utilities

## 📦 Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                 # Root widget
├── core/
│   ├── config/
│   │   └── routes.dart      # Go Router configuration
│   ├── constants/
│   │   ├── app_colors.dart
│   │   └── app_constants.dart
│   ├── services/            # Placeholder for services
│   └── utils/               # Utility functions
├── shared/
│   ├── theme/
│   │   └── app_theme.dart
│   └── widgets/
│       ├── custom_buttons.dart
│       ├── custom_app_bars.dart
│       └── custom_cards.dart
└── features/
    ├── auth/
    ├── onboarding/
    ├── home/
    ├── food_scanner/
    ├── meal_tracking/
    ├── water_tracker/
    ├── weight_tracker/
    ├── analytics/
    ├── ai_coach/
    ├── achievements/
    ├── profile/
    ├── barcode/
    ├── subscription/
    └── notifications/

assets/
├── animations/              # Rive animations
├── images/                  # Images & illustrations
└── icons/                   # App icons
```

## 🎨 Design System

### Color Palette
- **Primary**: #4ADE80 (Green)
- **Secondary**: #22C55E (Dark Green)
- **Accent**: #34D399 (Teal)
- **Background**: #0B1220 (Dark Blue)
- **Surface**: #111827 (Dark Gray)
- **Card**: #1F2937 (Light Gray)

### Typography
- **Font**: Poppins
- Weights: Regular, Medium (500), SemiBold (600), Bold (700)

### Components
- Rounded corners: 12px (default), 8px (small), 20px (large)
- Padding: 16px (default)
- Animations: 300ms (short), 500ms (medium), 800ms (long)

## 🔧 Tech Stack

### State Management
- `flutter_bloc` - BLoC pattern
- `equatable` - Value comparison

### Routing
- `go_router` - Declarative routing

### Dependency Injection
- `get_it` - Service locator
- `injectable` - Annotation-based DI

### Networking
- `dio` - HTTP client
- `pretty_dio_logger` - Network logging

### Backend
- `supabase_flutter` - Backend as a Service
- `supabase` - Supabase SDK

### Local Storage
- `hive` - Local database
- `hive_flutter` - Flutter integration
- `flutter_secure_storage` - Secure storage

### Notifications
- `firebase_messaging` - Push notifications
- `firebase_core` - Firebase setup
- `flutter_local_notifications` - Local notifications

### Charts & Analytics
- `fl_chart` - Chart library

### Camera & Images
- `camera` - Camera access
- `image_picker` - Image selection
- `image` - Image processing

### Additional Libraries
- `google_fonts` - Custom fonts
- `lottie` - Animations
- `rive` - Rive animations
- `speech_to_text` - Voice input
- `cached_network_image` - Image caching
- `connectivity_plus` - Network connectivity
- `permission_handler` - Permission handling

## 📋 Features Implemented (UI/Structure)

✅ **Complete UI Shell** (No Business Logic)
- [x] Splash Screen
- [x] Authentication (Login/Signup)
- [x] Onboarding (8 Steps)
- [x] Home Dashboard
- [x] Food Scanner
- [x] Meal Tracking
- [x] Water Tracker
- [x] Weight Tracker
- [x] Analytics
- [x] AI Coach (Chat Interface)
- [x] Achievements & Gamification
- [x] User Profile
- [x] Barcode Scanner
- [x] Premium Subscription
- [x] Notifications

## 🚀 Getting Started

### Prerequisites
- Flutter 3.0+
- Dart 3.0+
- iOS 12+ (for iOS)
- Android 21+ (for Android)

### Setup Instructions

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Configure `.env`** (create it in the project root — it is git-ignored)
   ```env
   SUPABASE_URL=your-project-url
   SUPABASE_ANON_KEY=your-anon-key

   # Nutrition APIs (optional — search falls back to the remaining providers)
   USDA_API_KEY=
   CALORIE_NINJAS_API_KEY=

   # AI Health Coach (optional — without a key the coach answers locally from
   # the user's tracked data instead of calling Gemini)
   GEMINI_API_KEY=your-gemini-api-key
   GEMINI_MODEL=gemini-2.5-flash
   GEMINI_API_BASE=https://generativelanguage.googleapis.com/v1beta
   ```
   Get a free Gemini key at https://aistudio.google.com/app/apikey.
   Use a model your key can access (e.g. `gemini-2.5-flash`,
   `gemini-flash-latest`); retired models such as `gemini-1.5-flash` return
   HTTP 404 and the coach then answers from its local fallback.

3. **Run the App**
   ```bash
   flutter run
   ```

4. **Build for Release**
   ```bash
   flutter build ios
   flutter build apk
   ```

## 📊 Database Schema (Planned)

### Tables
- `users` - User profiles
- `meals` - Meal entries
- `weight_tracking` - Weight history
- `water_intake` - Water logs
- `achievements` - User achievements
- `gamification` - XP and streaks

## 🎮 Gamification System

- **XP Points**: Earned from activities
- **Daily Streaks**: Consistency rewards
- **Badges**: Achievement system
- **Levels**: Progression system
- **Weekly Challenges**: Engagement

## 📸 Next Steps

1. **UI Refinement**: Exact UI pixel-perfect design based on provided screenshots
2. **Business Logic**: BLoC implementations and state management
3. **API Integration**: Supabase backend setup
4. **AI Pipeline**: FastAPI and YOLO model integration
5. **Testing**: Unit tests, widget tests, integration tests
6. **Performance**: Optimization and profiling

## 🔐 Security Considerations

- Secure token storage with `flutter_secure_storage`
- SSL pinning for API calls
- Input validation and sanitization
- Rate limiting
- Secure authentication with Supabase

## 📝 Notes

- All screens use placeholder data
- Business logic will be implemented using BLoC pattern
- API calls will use Dio with proper error handling
- Local storage will use Hive for caching
- Push notifications via Firebase
- Analytics will be implemented with custom tracking

## 👨‍💻 Development Guidelines

1. **Code Style**: Follow Flutter style guide
2. **Naming**: Use meaningful names for variables and functions
3. **Comments**: Document complex logic
4. **Testing**: Write tests for business logic
5. **Performance**: Use widgets efficiently, avoid unnecessary rebuilds
6. **Accessibility**: Consider a11y in UI design

## 📞 Support

For issues or questions about the project structure, refer to:
- [Flutter Documentation](https://flutter.dev/docs)
- [Clean Architecture](https://resocoder.com/clean-architecture-tdd)
- [BLoC Pattern](https://bloclibrary.dev)

---

**Version**: 1.0.0  
**Created**: 2024
