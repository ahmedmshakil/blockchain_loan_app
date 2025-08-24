# 🏦 Midnight Bank Ltd. - Blockchain Loan Application

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Blockchain](https://img.shields.io/badge/Blockchain-121D33?style=for-the-badge&logo=blockchain.com&logoColor=white)](https://ethereum.org)
[![Web3](https://img.shields.io/badge/Web3-F16822?style=for-the-badge&logo=web3.js&logoColor=white)](https://web3dart.github.io/web3dart/)

A revolutionary **blockchain-powered personal loan and credit scoring application** built with Flutter. This app leverages decentralized technology to enhance consumers' financial accessibility through transparent and secure credit assessment.

## 🚀 How to Run the Project

### Prerequisites

Before running the application, ensure you have the following installed:

- **Flutter SDK** (>=3.9.0) - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (>=3.9.0) - Comes with Flutter
- **Android Studio** or **VS Code** with Flutter extensions
- **Git** for version control

### 📱 Platform Requirements

- **Android**: API level 36 (Android 9.0) or higher
- **iOS**: iOS 14.0 or higher
- **Web**: Modern browsers with JavaScript enabled
- **Desktop**: Windows 10+, macOS 10.14+, or Linux

### 🔧 Installation Steps

1. **Clone the Repository**
   ```bash
   git clone https://github.com/ahmedmshakil/blockchain_loan_app.git
   cd blockchain_loan_app
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables**
   
   Copy the example environment file:
   ```bash
   cp .env.example .env
   ```
   
   Update the `.env` file with your configuration:
   - **Infura Project ID**: Get from [Infura.io](https://infura.io)
   - **Smart Contract Address**: Deploy your contract and add the address
   - **API Keys**: Add any required API keys

4. **Blockchain Configuration**
   
   Update the blockchain settings in `lib/config/blockchain_config.dart`:
   ```dart
   // Replace with your actual values
   static const String infuraProjectId = 'YOUR_INFURA_PROJECT_ID';
   static const String contractAddress = '0xYOUR_CONTRACT_ADDRESS';
   ```

5. **Generate App Icons** (Optional)
   ```bash
   flutter pub run flutter_launcher_icons:main
   ```

6. **Run the Application**
   
   For different platforms:
   ```bash
   # Android/iOS
   flutter run
   
   # Web
   flutter run -d chrome
   
   # Windows
   flutter run -d windows
   
   # macOS
   flutter run -d macos
   
   # Linux
   flutter run -d linux
   ```

### 🔍 Development Commands

```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Build for release (Android)
flutter build apk --release

# Build for release (iOS)
flutter build ios --release

# Build for web
flutter build web --release
```

## 📱 Application Screenshots

### 🏠 Main Interface
<div align="center">

| Main Page | Welcome Screen |
|-----------|----------------|
| <img src="appUI/01_main_page.png" width="300" alt="Main Page"/> | <img src="appUI/02_welcome_page.png" width="300" alt="Welcome Page"/> |

</div>

### 💰 Account Management
<div align="center">

| Account Overview | Account Details (Part 1) |
|------------------|---------------------------|
| <img src="appUI/03_account_overview.png" width="300" alt="Account Overview"/> | <img src="appUI/04_account_full_details01.png" width="300" alt="Account Details 1"/> |

</div>

<div align="center">

| Account Details (Part 2) | Transaction History |
|---------------------------|---------------------|
| <img src="appUI/05_account_full_details02.png" width="300" alt="Account Details 2"/> | <img src="appUI/06_transaction_history.png" width="300" alt="Transaction History"/> |

</div>

### 🎯 Activity & Loan Status
<div align="center">

| Activity Dashboard | Loan Status |
|--------------------|-------------|
| <img src="appUI/07_activity.png" width="300" alt="Activity Dashboard"/> | <img src="appUI/08_loan_status.png" width="300" alt="Loan Status"/> |

</div>

## ✨ Key Features

### 🔐 **Blockchain Integration**
- **Ethereum Sepolia Testnet** integration
- **Smart Contract** interactions for credit scoring
- **Web3** connectivity with secure wallet management
- **Decentralized** credit assessment system

### 🏦 **Banking Features**
- **Account Overview** with real-time balance tracking
- **Transaction History** with detailed records
- **Personal Loan** application and management
- **Credit Score** calculation and monitoring

### 🛡️ **Security & Privacy**
- **Secure Storage** for private keys and sensitive data
- **Biometric Authentication** support
- **Certificate Pinning** for network security
- **Cross-platform** security implementation

### 📊 **User Experience**
- **Intuitive Interface** with modern Material Design
- **Real-time Updates** and notifications
- **Multi-platform Support** (Android, iOS, Web, Desktop)
- **Responsive Design** for all screen sizes

## 🏗️ Architecture

The application follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├──  config/          # Configuration files
├──  models/          # Data models
├──  providers/       # State management
├──  screens/         # UI screens
├──  security/        # Security utilities
├──  services/        # Business logic
├──  utils/           # Helper utilities
└──  widgets/         # Reusable UI components
```

## 🛠️ Tech Stack

### **Frontend**
- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language
- **Provider** - State management
- **Material Design 3** - UI components

### **Blockchain**
- **Ethereum** - Blockchain network
- **Solidity** - Smart contract language
- **Web3Dart** - Ethereum client library
- **Infura** - Blockchain node provider


## Author

👤 **Shakil Ahmed**

* LinkedIn: [@ahmedmshakil](https://www.linkedin.com/in/ahmedmshakil/)
* GitHub: [@ahmedmshakil](https://github.com/ahmedmshakil)

---
<div align="center">



[![GitHub stars](https://img.shields.io/github/stars/ahmedmshakil/blockchain_loan_app?style=social)](https://github.com/ahmedmshakil/blockchain_loan_app)
[![GitHub forks](https://img.shields.io/github/forks/ahmedmshakil/blockchain_loan_app?style=social)](https://github.com/ahmedmshakil/blockchain_loan_app)

</div>
