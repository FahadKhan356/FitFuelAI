# FITFUEL AI - Quick Start Guide

## 🚀 Getting Started

### Prerequisites
- Flutter 3.0+ installed
- Dart 3.0+
- Android Studio / Xcode
- VS Code or preferred IDE

### Step 1: Install Dependencies

```bash
cd "FitFuel AI"
flutter pub get
```

### Step 2: Run the App

```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Specific device
flutter run -d chrome
flutter run -d "iPhone 15"
```

### Step 3: Project Structure Overview

**Current State**: 
- ✅ All screen scaffolds created
- ✅ Routing configured
- ✅ Theme system setup
- ✅ Color system defined
- ❌ Business logic (to be added)
- ❌ API integration (to be added)

## 📂 Folder Navigation

### Starting Points

**For UI Development**:
```
lib/features/[feature-name]/presentation/pages/
lib/features/[feature-name]/presentation/widgets/
```

**For Adding New Features**:
```
1. Create feature folder in lib/features/
2. Add presentation/pages and presentation/widgets
3. Add domain/ and data/ folders (structure ready)
4. Add route in lib/core/config/routes.dart
```

**For Modifying Theme**:
```
lib/shared/theme/app_theme.dart
lib/core/constants/app_colors.dart
```

**For Adding Widgets**:
```
lib/shared/widgets/
```

## 🎨 Design System

### Colors
All colors are defined in `lib/core/constants/app_colors.dart`

```dart
AppColors.primary       // #4ADE80 (Green)
AppColors.secondary     // #22C55E (Dark Green)
AppColors.accent        // #34D399 (Teal)
AppColors.background    // #0B1220 (Dark)
AppColors.surface       // #111827 (Gray)
AppColors.card          // #1F2937 (Light Gray)
```

### Text Styles
Use `Theme.of(context).textTheme` for all text:

```dart
Theme.of(context).textTheme.displayLarge     // 32px, Bold
Theme.of(context).textTheme.displayMedium    // 28px, Bold
Theme.of(context).textTheme.displaySmall     // 24px, Bold
Theme.of(context).textTheme.headlineLarge    // 22px, SemiBold
Theme.of(context).textTheme.titleLarge       // 18px, Medium
Theme.of(context).textTheme.bodyLarge        // 16px, Regular
Theme.of(context).textTheme.bodyMedium       // 14px, Regular
Theme.of(context).textTheme.bodySmall        // 12px, Regular
```

### Components
- **Buttons**: `PrimaryButton`, `SecondaryButton`, `GradientButton`
- **Cards**: `MacroCard`, `StatCard`, `ProgressCircle`
- **AppBars**: `CustomAppBar`, `CustomBottomNavBar`

## 📱 Available Screens

### Authentication
- `SplashScreen` - `/`
- `LoginScreen` - `/login`
- `SignupScreen` - `/signup`

### Main Flow
- `OnboardingScreen` - `/onboarding`
- `HomeScreen` - `/home`

### Features
- `FoodScannerScreen` - `/food-scanner`
- `MealTrackingScreen` - `/meal-tracking`
- `WaterTrackerScreen` - `/water-tracker`
- `WeightTrackerScreen` - `/weight-tracker`
- `AnalyticsScreen` - `/analytics`
- `AiCoachScreen` - `/ai-coach`
- `AchievementsScreen` - `/achievements`
- `ProfileScreen` - `/profile`
- `BarcodeScannerScreen` - `/barcode` (in features/barcode)
- `SubscriptionScreen` - `/subscription`
- `NotificationsScreen` - Not routed yet

## 🔄 Navigation

All routing is configured in `lib/core/config/routes.dart` using `go_router`.

### Navigate Between Screens
```dart
// Push named route
context.go('/home');
context.go('/food-scanner');

// With parameters (future)
context.go('/meal/$mealId');

// Replace current screen
context.replace('/home');
```

## 🎯 Next Steps for Development

### Phase 1: UI Enhancement (Current)
1. Review provided screenshots
2. Update each screen to match exact design
3. Add animations
4. Test on multiple devices

### Phase 2: State Management
1. Create BLoC classes for each feature
2. Implement state classes using `equatable`
3. Add BLoC listeners to screens
4. Test state transitions

### Phase 3: Backend Integration
1. Set up Supabase project
2. Create API service class with Dio
3. Implement data layer repositories
4. Add error handling

### Phase 4: Advanced Features
1. Camera implementation
2. Barcode scanning
3. AI Chat integration
4. Analytics charts

## 📚 Project Architecture Reference

### Clean Architecture Layers

```
Presentation Layer (UI)
    ↓
Domain Layer (Business Logic)
    ↓
Data Layer (API/DB)
    ↓
External Services (Supabase, Firebase)
```

### BLoC Pattern Flow
```
Widget → BLoC → Repository → DataSource → Backend/Local DB
```

## 🛠️ Useful Commands

```bash
# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Run on specific device
flutter devices
flutter run -d [device-id]

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release

# Run analyzer
flutter analyze

# Format code
dart format lib/

# Run tests
flutter test

# Clean build
flutter clean
flutter pub get
flutter run
```

## 📞 Common Issues & Solutions

### Issue: "Plugin not found"
**Solution**: Run `flutter pub get` and `flutter pub upgrade`

### Issue: "No devices found"
**Solution**: 
- Connect device or start emulator
- Run `flutter devices`

### Issue: "Build fails on iOS"
**Solution**: 
```bash
cd ios
rm -rf Pods
cd ..
flutter clean
flutter pub get
flutter run
```

### Issue: "Hot reload not working"
**Solution**: Stop app and run `flutter run` again, or use `flutter run -v`

## 📖 Documentation Links

- [Flutter Docs](https://flutter.dev/docs)
- [Go Router](https://pub.dev/packages/go_router)
- [Flutter BLoC](https://bloclibrary.dev)
- [Supabase Flutter](https://supabase.com/docs/reference/flutter)
- [Dio Package](https://pub.dev/packages/dio)

## ✨ Code Quality

This project uses:
- **Linting**: flutter_lints
- **Formatting**: Built-in dart formatter
- **Analysis**: flutter analyze

Run analysis with:
```bash
flutter analyze
```

---

## 🎬 Next: Awaiting UI Screenshots

**Current State**: Skeleton/framework ready

**Next Action**: Client provides screenshots → UI implementation begins

---

**Last Updated**: Now
**Difficulty Level**: Beginner-friendly structure, ready for implementation
