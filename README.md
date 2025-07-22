# Nebula Expense

**Advanced Military-Grade Offline Expense Tracker with Quantum-Resistant Security**

Nebula Expense is a comprehensive offline personal expense tracker featuring military-grade encryption, quantum-resistant security protocols, and advanced privacy protection that exceeds DoD and NSA standards. Built with Flutter for cross-platform compatibility, it provides complete financial privacy with zero network dependencies.

## Table of Contents

- [Features](#features)
- [Security Architecture](#security-architecture)
- [System Requirements](#system-requirements)
- [Installation](#installation)
- [Building for Different Platforms](#building-for-different-platforms)
- [Deployment](#deployment)
- [Configuration](#configuration)
- [Architecture](#architecture)
- [Development](#development)
- [Testing](#testing)
- [Contributing](#contributing)
- [Security Standards](#security-standards)
- [License](#license)

## Features

### Core Expense Management
- Multi-wallet support with individual encryption
- Transaction categorization and custom tagging
- Recurring transactions and transaction templates
- Receipt attachments and detailed notes
- Advanced filtering, sorting, and full-text search
- Budget tracking with customizable alerts
- Spending pattern analysis and insights
- Interactive charts and data visualizations
- Calendar timeline view with smart grouping
- Custom fields and metadata support

### Security Features

#### Encryption and Data Protection
- AES-256 encryption with device-based key derivation
- Quantum-resistant key stretching with 500,000+ PBKDF2 iterations
- Argon2 simulation for enhanced key derivation
- Custom quantum-resistant hashing algorithms
- Triple-redundancy tamper detection with multiple hash algorithms
- Runtime integrity monitoring
- Secure memory management with automatic overwriting

#### Emergency Security Protocols
- Self-destruct PIN with configurable wipe levels:
  - Basic: Standard data deletion
  - Secure: Multi-pass overwrite (DoD 5220.22-M)
  - Military: NSA/CSS-02-01 + forensic countermeasures
- Panic mode with configurable emergency actions
- Decoy PIN mode with fake wallets and data masking
- Military emergency protocol with automatic lockdown
- Emergency contact integration for critical events

#### Privacy and Stealth Features
- Stealth mode with hidden wallets
- Calculator mode for app disguise
- Per-wallet security locks
- Progressive lockout on failed authentication attempts
- Comprehensive security audit logs
- Biometric authentication integration
- Multi-profile isolation with encrypted storage

#### Advanced Monitoring
- Runtime integrity checks detecting:
  - Debugging tools and development environments
  - Memory manipulation attempts
  - Code injection and tampering
  - Unauthorized access attempts
- Forensic countermeasures and anti-analysis features
- Security recommendations engine
- Periodic security health checks

### Data Management
- Encrypted local database (Hive)
- Offline-first architecture with zero network dependencies
- Data versioning and audit trails
- Snapshot and rollback capabilities
- Encrypted backup and restore functionality
- Export capabilities (JSON, CSV, encrypted ZIP)
- Import from various formats
- Data integrity verification

### User Interface
- Futuristic design with claymorphic/neumorphic/glassmorphic elements
- Dark and light theme support
- Accessibility features and screen reader support
- Responsive design for all screen sizes
- Customizable dashboard and layouts
- Advanced animation and transition effects
- Multi-language support preparation

### Developer Tools
- Offline DevTools panel for debugging
- Performance monitoring and analytics
- Security metrics dashboard
- Development mode with enhanced logging
- CLI tools for data management

## Security Architecture

### Encryption Standards
- **Primary**: AES-256-CBC encryption
- **Key Derivation**: PBKDF2 with 500,000+ iterations
- **Hashing**: SHA-256, SHA-512, custom quantum-resistant algorithms
- **Storage**: Flutter Secure Storage for key management
- **Database**: Hive with AES encryption

### Security Compliance
- DoD 5220.22-M (Department of Defense data sanitization)
- NSA/CSS-02-01 (National Security Agency secure erasure)
- FIPS 140-2 (Federal Information Processing Standards)
- Common Criteria EAL4+ evaluation standards

### Threat Model
- Protection against physical device access
- Defense against memory analysis and forensics
- Resistance to debugging and reverse engineering
- Mitigation of side-channel attacks
- Protection against malware and keyloggers

## System Requirements

### Development Environment
- Flutter SDK 3.19.0 or higher
- Dart SDK 3.3.0 or higher
- Git for version control

### Platform-Specific Requirements

#### Android Development
- Android Studio 2023.1.1 or higher
- Android SDK API level 21+ (Android 5.0+)
- Java Development Kit (JDK) 11 or higher
- Android NDK (for native components)

#### iOS Development
- Xcode 15.0 or higher
- iOS 11.0 or higher
- macOS 10.15 or higher (for development)
- Apple Developer Account (for distribution)

#### Web Development
- Modern web browser with WebAssembly support
- Chrome 88+, Firefox 85+, Safari 14+, Edge 88+

#### Windows Development
- Visual Studio 2022 with "Desktop development with C++" workload
- Windows 10 version 1903 or higher
- Windows SDK 10.0.17763.0 or higher
- Developer Mode enabled in Windows settings

#### macOS Development
- Xcode 15.0 or higher
- macOS 10.14 or higher
- CocoaPods 1.11.0 or higher

#### Linux Development
- Ubuntu 18.04 or equivalent distribution
- GTK 3.0 development libraries
- pkg-config
- ninja-build
- clang

## Installation

### Prerequisites
1. Install Flutter SDK:
   ```bash
   # Download Flutter SDK from https://flutter.dev/docs/get-started/install
   # Add Flutter to your PATH
   export PATH="$PATH:`pwd`/flutter/bin"
   ```

2. Verify Flutter installation:
   ```bash
   flutter doctor
   ```

### Project Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/nebula_expense.git
   cd nebula_expense
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate required files:
   ```bash
   flutter packages pub run build_runner build
   ```

4. Run the application:
   ```bash
   flutter run
   ```

## Building for Different Platforms

### Android

#### Debug Build
```bash
flutter build apk --debug
```

#### Release Build
```bash
# Generate keystore (first time only)
keytool -genkey -v -keystore android/app/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias nebula_expense

# Build release APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

#### Configuration
Update `android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        applicationId "com.nebula.expense"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
}
```

### iOS

#### Debug Build
```bash
flutter build ios --debug
```

#### Release Build
```bash
# Build for device
flutter build ios --release

# Build IPA for distribution
flutter build ipa --release
```

#### Configuration
Update `ios/Runner/Info.plist`:
```xml
<key>CFBundleDisplayName</key>
<string>Nebula Expense</string>
<key>CFBundleIdentifier</key>
<string>com.nebula.expense</string>
<key>CFBundleVersion</key>
<string>1.0.0</string>
```

### Web

#### Debug Build
```bash
flutter run -d chrome
```

#### Release Build
```bash
# Build for web
flutter build web --release

# Build with specific renderer
flutter build web --web-renderer canvaskit --release
```

#### PWA Configuration
Update `web/manifest.json`:
```json
{
  "name": "Nebula Expense",
  "short_name": "Nebula Expense",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#0175C2",
  "theme_color": "#0175C2",
  "description": "Advanced Military-Grade Offline Expense Tracker",
  "orientation": "portrait-primary",
  "prefer_related_applications": false
}
```

### Windows

#### Prerequisites
- Enable Developer Mode in Windows settings
- Install Visual Studio with C++ development tools

#### Build
```bash
# Debug build
flutter build windows --debug

# Release build
flutter build windows --release
```

#### Packaging
```bash
# Create MSIX package
flutter pub run msix:create
```

### macOS

#### Build
```bash
# Debug build
flutter build macos --debug

# Release build
flutter build macos --release
```

#### Code Signing
Update `macos/Runner/Release.entitlements`:
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

### Linux

#### Prerequisites
```bash
# Ubuntu/Debian
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev

# Fedora
sudo dnf install clang cmake ninja-build pkgconf-pkg-config gtk3-devel
```

#### Build
```bash
# Debug build
flutter build linux --debug

# Release build
flutter build linux --release
```

## Deployment

### Android Deployment

#### Google Play Store
1. Build App Bundle:
   ```bash
   flutter build appbundle --release
   ```
2. Upload to Google Play Console
3. Complete store listing and compliance forms

#### Alternative Distribution
- Direct APK distribution
- F-Droid (open-source)
- Amazon Appstore
- Samsung Galaxy Store

### iOS Deployment

#### App Store
1. Build IPA:
   ```bash
   flutter build ipa --release
   ```
2. Upload via Xcode or Application Loader
3. Submit for App Store review

#### Enterprise Distribution
- In-house distribution with enterprise certificate
- TestFlight for beta testing

### Web Deployment

#### Static Hosting
```bash
# Build for production
flutter build web --release

# Deploy to hosting service
# Examples: Netlify, Vercel, GitHub Pages, Firebase Hosting
```

#### Server Configuration
Nginx configuration:
```nginx
server {
    listen 80;
    server_name nebula-expense.com;
    root /var/www/nebula_expense;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
}
```

### Desktop Deployment

#### Windows
- MSIX package for Microsoft Store
- Traditional installer (NSIS, Inno Setup)
- Portable executable distribution

#### macOS
- Mac App Store distribution
- Direct download with notarization
- Homebrew cask

#### Linux
- AppImage for universal distribution
- Snap package
- Flatpak
- Distribution-specific packages (DEB, RPM)

## Configuration

### Environment Variables
Create `.env` file:
```
APP_NAME=Nebula Expense
APP_VERSION=1.0.0
ENVIRONMENT=production
DEBUG_MODE=false
SECURITY_LEVEL=military
```

### Security Configuration
Update `lib/core/constants/app_constants.dart`:
```dart
class SecurityConfig {
  static const int pbkdf2Iterations = 500000;
  static const int keySize = 256;
  static const String encryptionAlgorithm = 'AES-256-CBC';
  static const bool enableTamperDetection = true;
  static const bool enableRuntimeIntegrity = true;
}
```

### Database Configuration
```dart
class DatabaseConfig {
  static const String databaseName = 'nebula_expense';
  static const int databaseVersion = 1;
  static const bool enableEncryption = true;
  static const bool enableCompression = true;
}
```

## Architecture

### Project Structure
```
lib/
├── core/
│   ├── constants/          # Application constants
│   ├── security/           # Security services
│   ├── storage/            # Data storage layer
│   └── theme/              # UI theming
├── features/
│   ├── authentication/     # Auth screens and logic
│   ├── wallets/           # Wallet management
│   ├── transactions/      # Transaction handling
│   ├── analytics/         # Data visualization
│   └── settings/          # App configuration
├── shared/
│   ├── models/            # Data models
│   ├── services/          # Business logic
│   └── widgets/           # Reusable UI components
└── presentation/
    ├── app/               # App configuration
    ├── screens/           # UI screens
    └── widgets/           # UI components
```

### Design Patterns
- **Clean Architecture**: Separation of concerns
- **Repository Pattern**: Data access abstraction
- **Provider Pattern**: State management
- **Factory Pattern**: Object creation
- **Observer Pattern**: Event handling
- **Strategy Pattern**: Algorithm selection

### Dependencies

#### Core Dependencies
```yaml
flutter:
  sdk: flutter
cupertino_icons: ^1.0.6
provider: ^6.1.2
go_router: ^14.2.7
hive: ^2.2.3
hive_flutter: ^1.1.0
flutter_secure_storage: ^9.2.2
crypto: ^3.0.3
local_auth: ^2.3.0
```

#### Development Dependencies
```yaml
flutter_test:
  sdk: flutter
flutter_lints: ^4.0.0
build_runner: ^2.4.12
hive_generator: ^2.0.1
json_annotation: ^4.9.0
json_serializable: ^6.8.0
mockito: ^5.4.4
```

## Development

### Code Style
- Follow Dart style guide
- Use `flutter_lints` for code analysis
- Maintain 80% minimum test coverage
- Document all public APIs

### Git Workflow
```bash
# Feature development
git checkout -b feature/new-security-feature
git commit -m "feat: add quantum-resistant encryption"
git push origin feature/new-security-feature

# Create pull request
# Code review and testing
# Merge to main branch
```

### Code Generation
```bash
# Generate model files
flutter packages pub run build_runner build

# Watch for changes
flutter packages pub run build_runner watch

# Clean generated files
flutter packages pub run build_runner clean
```

### Debugging
```bash
# Run with debugging
flutter run --debug

# Run with profiling
flutter run --profile

# Analyze code
flutter analyze

# Format code
dart format .
```

## Testing

### Unit Tests
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

### Integration Tests
```bash
# Run integration tests
flutter drive --target=test_driver/app.dart
```

### Security Testing
```bash
# Static analysis
flutter analyze
dart analyze --fatal-infos

# Dependency audit
flutter pub deps

# Security scan
# Use tools like: snyk, safety, bandit
```

### Performance Testing
```bash
# Profile performance
flutter run --profile

# Memory profiling
flutter run --profile --trace-startup

# Build size analysis
flutter build apk --analyze-size
```

## Contributing

### Getting Started
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

### Code Review Process
1. Automated testing (CI/CD)
2. Security review for sensitive changes
3. Code quality assessment
4. Performance impact evaluation
5. Documentation review

### Security Considerations
- All security-related changes require thorough review
- Cryptographic implementations must be validated
- No hardcoded secrets or keys
- Follow secure coding practices
- Regular security audits

## Security Standards

### Compliance
- **DoD 5220.22-M**: Department of Defense data sanitization
- **NSA/CSS-02-01**: National Security Agency secure erasure
- **FIPS 140-2**: Federal Information Processing Standards
- **Common Criteria EAL4+**: International security evaluation

### Security Audit
Regular security assessments include:
- Static code analysis
- Dynamic application security testing
- Penetration testing
- Cryptographic validation
- Privacy impact assessment

### Vulnerability Reporting
To report security vulnerabilities:
1. Email: security@nebula-expense.com
2. Use encrypted communication
3. Provide detailed reproduction steps
4. Allow reasonable disclosure timeline

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Third-Party Licenses
See [LICENSES.md](LICENSES.md) for complete list of third-party dependencies and their licenses.

## Support

### Documentation
- [User Guide](docs/user-guide.md)
- [API Documentation](docs/api.md)
- [Security Guide](docs/security.md)
- [Deployment Guide](docs/deployment.md)

### Community
- GitHub Issues for bug reports
- GitHub Discussions for questions
- Wiki for additional documentation

### Commercial Support
For enterprise support and custom implementations, contact: enterprise@nebula-expense.com

---

**Nebula Expense** - Advanced Military-Grade Offline Expense Tracker

Version 1.0.0 | Built with Flutter | Secured with Military-Grade Encryption
