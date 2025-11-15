# 🎨 Fays Arukattil - Portfolio Website

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Google AI](https://img.shields.io/badge/Google_AI-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev/)
[![Live Demo](https://img.shields.io/badge/Live-Demo-success?style=for-the-badge)](https://faysarukattil.github.io/FaysArukattil_Portfolio/)

A modern, responsive portfolio website built with Flutter that showcases my projects, skills, and professional experience. Features **intelligent project descriptions** using Google's Generative AI, **secure Firebase token storage**, dynamic GitHub integration, automated resume generation, and a sleek glassmorphism UI.

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Firebase Integration](#firebase-integration)
- [Intelligent Content Generation](#intelligent-content-generation)
- [Project Scoring Algorithm](#project-scoring-algorithm)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Dependencies](#dependencies)
- [Key Features Implementation](#key-features-implementation)
- [UI Highlights](#ui-highlights)
- [Responsive Design](#responsive-design)
- [Privacy & Security](#privacy--security)
- [Known Limitations](#known-limitations)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [Author](#author)
- [Acknowledgments](#acknowledgments)

## Overview

This portfolio website is built with Flutter Web and serves as a dynamic showcase of my development work. The site automatically fetches projects from GitHub, uses **advanced natural language processing** to generate compelling project descriptions, securely stores API credentials in **Firebase Firestore**, filters projects based on quality metrics, and generates professional PDF resumes on-demand with enhanced content.

**Entry point:** `lib/main.dart`
- Initializes Firebase for secure token management
- Direct navigation to `HomeScreen` (no loading screen delay)
- Optimized for fast first paint

**Key screens:**
- `lib/homescreen.dart` - Main portfolio with Hero, Skills, Projects, and Contact sections
- `lib/widgets/projects_section.dart` - Reusable projects grid component

**Services:**
- `lib/services/firebase_token_service.dart` - **NEW!** Secure Firebase-based token management
- `lib/services/github_service.dart` - GitHub API integration with intelligent filtering
- `lib/services/gemini_service.dart` - Natural language generation for project content
- `lib/services/resumegeneration.dart` - Dynamic PDF resume generation

**Configuration:**
- `lib/config/firebase_config.dart` - Firebase project configuration

## Features

### 🔐 Secure Firebase Token Storage (NEW!)
- **Cloud-Based Credentials:** API keys stored securely in Firebase Firestore
- **No Secrets in Code:** Tokens never committed to repository
- **Easy Updates:** Change API keys instantly via Firebase Console
- **GitHub Pages Friendly:** Deploy safely to public hosting without exposing secrets
- **Automatic Retrieval:** App fetches tokens on startup from Firebase
- **Error Handling:** Graceful fallback to cached data if Firebase unavailable
- **Zero Configuration Deployment:** No need to set GitHub Actions secrets

### 🧠 Intelligent Content Generation
- **Automated Project Descriptions:** Leverages advanced language models to analyze and describe projects
- **Dual Content Formats:** 
  - **Concise summaries** (1-2 lines) for quick project overviews
  - **Detailed breakdowns** (4-6 bullet points) showcasing technical depth
- **Smart Analysis Engine:** Processes project README, description, and tech stack to extract:
  - Clear, functionality-focused descriptions
  - Key features and technical capabilities
  - Architecture and implementation patterns
  - Technology stack identification
- **Efficient Processing:** Single request generates both content types simultaneously
- **Intelligent Fallbacks:** Seamlessly switches to rule-based generation when needed
- **Curated Priority Projects:** Maintains handcrafted descriptions for flagship work

### 🤖 Dynamic GitHub Integration
- **Automatic Project Fetching:** Connects to GitHub API to retrieve all public repositories
- **Intelligent Filtering:** Smart scoring system evaluates projects based on:
  - README quality and length (0-15 points)
  - Visual content - screenshots, diagrams (0-10 points)
  - Documentation structure (0-8 points)
  - Code examples (0-6 points)
  - Documentation quality keywords (0-12 points)
  - Project maturity indicators (0-4 points)
  - **Minimum score threshold: 15 points** for non-priority projects
- **Priority Projects:** Manually curated flagship projects (Buddy, Instagram Clone, Portfolio) with custom descriptions
- **Learning Filter:** Automatically hides tutorial/practice repositories using keyword detection
- **Real-time Updates:** Projects update automatically when you push to GitHub

### 📄 Automated Resume Generation
- **One-Click PDF Download:** Generate professional PDF resume instantly with latest project data
- **Enhanced Content:** 
  - Uses intelligently-generated project descriptions
  - Automatically extracts highlights from detailed analyses
  - Smart bullet point formatting from technical breakdowns
- **Dynamic Content:** Automatically includes latest GitHub projects with rich descriptions
- **Smart Caching:** 
  - Resume cached after first generation
  - Instant subsequent downloads
  - Background regeneration when projects change
- **Beautiful Animations:** Loading states with progress indicators and status messages
- **LaTeX-Quality Output:** Professional formatting with Google Fonts (Roboto family)
- **Text Sanitization:** Automatic removal of emojis/special characters for PDF compatibility

### 💾 Advanced Caching System
- **Multi-Layer Cache:**
  - Raw GitHub API responses (24hr TTL)
  - Filtered/scored projects with generated summaries (24hr TTL)
  - Generated PDF bytes (persistent)
  - Project data for comparison (persistent)
- **Offline Support:** Graceful fallback to cached data on network failure
- **Smart Invalidation:** Automatic cache refresh on project changes
- **Background Updates:** Cache refreshed silently without blocking UI

### 🎨 Modern UI/UX
- **Glassmorphism Design:** Frosted glass effects with gradient accents
- **Smooth Animations:** Fade-in sections, hover effects, progress transitions
- **Section Navigation:** Smart scroll tracking with active indicators
- **Material Design 3:** Modern components and elevation system
- **Visual Feedback:** Loading states for all async operations

### 📱 Fully Responsive
- **Desktop (>1024px):** Full navigation, hover effects, 2-3 column grid
- **Tablet (768-1024px):** 2-column grid, touch interactions
- **Mobile (<768px):** Single column, hamburger menu, touch-optimized

## Tech Stack

### Framework & Language
- **Flutter 3.27.1+** - Cross-platform UI framework
- **Dart SDK 3.0+** - Programming language

### Backend & Storage
- **Firebase Core 3.8.1** - Firebase platform initialization
- **Cloud Firestore 5.5.2** - NoSQL cloud database for secure token storage

### AI & Natural Language Processing
- **google_generative_ai 0.2.0+** - Google's Generative AI SDK for content generation
- **Gemini 2.5 Flash** - High-performance language model for text analysis and generation

### API & Networking
- **http 1.1.0** - HTTP client for GitHub API calls
- **REST API** - GitHub REST API v3

### Data Persistence
- **shared_preferences 2.2.2** - Local key-value storage for caching

### PDF Generation
- **pdf 3.10.7** - PDF document creation
- **printing 5.11.1** - PDF rendering and Google Fonts support

### File Operations
- **file_saver 0.2.14** - Cross-platform file saving

### URL Handling
- **url_launcher 6.3.0** - Open external links

### UI Components
- **visibility_detector 0.4.0+2** - Detect widget visibility for animations

## Architecture

### Project Structure
```
lib/
├── main.dart                             # App entry point with Firebase init
├── homescreen.dart                       # Main portfolio screen
├── config/
│   └── firebase_config.dart             # Firebase project configuration
├── services/
│   ├── firebase_token_service.dart      # 🔥 NEW: Secure token management
│   ├── github_service.dart              # GitHub API + content generation
│   ├── gemini_service.dart              # Language model service
│   └── resumegeneration.dart            # PDF generation
└── widgets/
    └── projects_section.dart            # Projects grid component
```

### Service Architecture

#### FirebaseTokenService (NEW!)
- **Initialization:** Connects to Firebase on app startup
- **Token Retrieval:** Fetches API keys from Firestore securely
- **Methods:**
  - `initialize()` - Sets up Firebase and fetches tokens
  - `githubToken` - Returns GitHub personal access token
  - `geminiApiKey` - Returns Google AI API key
  - `hasAllTokens` - Checks if both tokens loaded successfully
- **Error Handling:**
  - Graceful failure when Firebase unavailable
  - App continues with cached data
  - Comprehensive error logging
- **Security:**
  - Tokens stored in Firestore (not in code)
  - Read-only access for public
  - Write access only via Firebase Console

#### GitHubService
- Fetches repositories from GitHub API using Firebase-provided token
- Implements intelligent project scoring algorithm
- Integrates with GeminiService for content generation
- Manages multi-layer caching (repos, filtered data)
- Handles priority project custom descriptions
- Filters learning/tutorial repositories

#### GeminiService
- **Model:** `gemini-2.5-flash` - High-performance language model
- Uses Firebase-provided API key
- **Configuration:**
  - Temperature: 0.4 (balanced creativity/accuracy)
  - Max tokens: 2000
- **Methods:**
  - `generateBothSummaries()` - Efficient single request for both formats
- **Content Strategy:**
  - Technical writing focused on functionality
  - Extracts features from README analysis
  - Structured output formatting
- **Error Handling:** Automatic fallback to rule-based generation

#### ResumeGeneratorService
- Generates professional LaTeX-quality PDF resumes
- Uses generated summaries for project descriptions
- Smart extraction of bullet points from detailed summaries
- Font caching and text sanitization
- Dynamic project selection with intelligent highlight extraction

## Firebase Integration

### Setup Process

1. **Create Firebase Project:**
   - Visit [Firebase Console](https://console.firebase.google.com/)
   - Click "Add project"
   - Enter project name (e.g., `fays-portfolio`)
   - Disable Google Analytics (optional)
   - Click "Create project"

2. **Enable Firestore Database:**
   - In Firebase Console, click "Firestore Database"
   - Click "Create database"
   - Choose "Start in production mode"
   - Select your region
   - Click "Enable"

3. **Set Security Rules:**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /config/tokens {
         allow read: if true;  // Public read access
         allow write: if false; // Only admin can write
       }
     }
   }
   ```
   - Click "Publish"

4. **Add Your Tokens:**
   - Go to Firestore Database → Data tab
   - Click "Start collection"
   - Collection ID: `config`
   - Document ID: `tokens`
   - Add fields:
     - `githubToken` (string): Your GitHub personal access token
     - `geminiApiKey` (string): Your Google AI API key
   - Click "Save"

5. **Register Web App:**
   - In Firebase Console, click gear icon → Project settings
   - Scroll to "Your apps" → Click Web icon (`</>`)
   - App nickname: `Portfolio Web App`
   - Don't check "Firebase Hosting"
   - Click "Register app"
   - Copy the Firebase configuration

6. **Configure Your App:**
   - Create `lib/config/firebase_config.dart`:
   ```dart
   class FirebaseConfig {
     static const String apiKey = "AIza...";
     static const String authDomain = "your-project.firebaseapp.com";
     static const String projectId = "your-project-id";
     static const String storageBucket = "your-project.appspot.com";
     static const String messagingSenderId = "123456789";
     static const String appId = "1:123456789:web:abc123";
   }
   ```

### How It Works

1. **App Startup:** `main.dart` initializes Firebase
2. **Token Fetch:** `FirebaseTokenService.initialize()` retrieves tokens from Firestore
3. **Service Integration:** GitHub and Gemini services use fetched tokens
4. **Secure Storage:** Tokens never committed to Git or exposed in code
5. **Easy Updates:** Change tokens anytime via Firebase Console

### Benefits

✅ **No secrets in repository** - Safe to commit all code  
✅ **Easy token rotation** - Update via Firebase Console instantly  
✅ **GitHub Pages compatible** - No need for GitHub Actions secrets  
✅ **Public deployment ready** - Tokens fetched at runtime  
✅ **Fallback support** - App works with cached data if Firebase unavailable  
✅ **Simple architecture** - No backend server needed  

## Intelligent Content Generation

### How It Works

1. **Data Collection:**
   - Project name, description, and README fetched from GitHub
   - Programming language detected
   - Priority status checked

2. **Content Processing:**
   - For non-priority projects: Language model analyzes content
   - Generates two content types in one request
   - Extracts key features, tech stack, and capabilities
   - Focuses on functionality and technical highlights

3. **Quality Assurance:**
   - Validates output format
   - Falls back to rule-based generation if needed
   - Removes emojis and special characters
   - Ensures content meets length requirements

4. **Caching:**
   - Generated summaries cached for 24 hours
   - Reduces API calls and improves performance
   - Background refresh when projects updated

## Project Scoring Algorithm

Projects are scored automatically based on multiple criteria (0-55 points total):

### Scoring Breakdown
1. **README Length** (0-15 points)
2. **Visual Content** (0-10 points)
3. **Documentation Structure** (0-8 points)
4. **Code Examples** (0-6 points)
5. **Documentation Quality** (0-12 points)
6. **Project Maturity** (0-4 points)

### Filtering Rules
- **Minimum Score:** 15 points (for non-priority projects)
- **Priority Projects:** Always included (score overridden to 100)
- **Learning Projects:** Automatically filtered out
- **Display Order:** Priority projects first, then sorted by score

## Getting Started

### Prerequisites
- Flutter SDK 3.27.1+
- Dart SDK 3.0+
- Git
- **Firebase Account** (free tier is sufficient)
- **GitHub Personal Access Token**
- **Google AI API Key**

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/FaysArukattil/FaysArukattil_Portfolio.git
cd FaysArukattil_Portfolio
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Set up Firebase** (see [Firebase Integration](#firebase-integration) section):
   - Create Firebase project
   - Enable Firestore
   - Set security rules
   - Add tokens to Firestore
   - Copy Firebase config

4. **Configure Firebase in your app:**

Create `lib/config/firebase_config.dart`:
```dart
class FirebaseConfig {
  static const String apiKey = "YOUR_FIREBASE_API_KEY";
  static const String authDomain = "your-project.firebaseapp.com";
  static const String projectId = "your-project-id";
  static const String storageBucket = "your-project.appspot.com";
  static const String messagingSenderId = "123456789";
  static const String appId = "1:123456789:web:abc123";
}
```

5. **Get API Keys:**

**GitHub Token:**
   1. Go to GitHub Settings → Developer settings → Personal access tokens
   2. Generate new token (classic)
   3. Select scope: `repo` (full control of repositories)
   4. Copy token (starts with `ghp_`)
   5. Add to Firestore (see Firebase setup)

**Google AI API Key:**
   1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
   2. Create new API key
   3. Copy key
   4. Add to Firestore (see Firebase setup)

6. **Run the app:**

For web:
```bash
flutter run -d chrome
```

**Check console logs for:**
```
🔥 Initializing Firebase...
✅ Firebase initialized
📡 Fetching tokens from Firestore...
✅ GitHub Token: Loaded (40 chars)
✅ Gemini Key: Loaded (39 chars)
🎉 Firebase token service ready!
```

### Building for Production

**Web:**
```bash
flutter build web --release --base-href "/YourRepoName/"
```

**Desktop:**
```bash
flutter build windows --release  # or macos/linux
```

**GitHub Pages Deployment:**
The included GitHub Actions workflow automatically:
1. Builds your Flutter web app
2. Deploys to `gh-pages` branch
3. Your app fetches tokens from Firebase at runtime

No need to set GitHub Actions secrets! 🎉

## Configuration

### Customization Options

1. **Update Personal Information:**
   - Edit `ResumeGeneratorService` constants
   - Update `_personalInfo`, `_professionalSummary`, `_skills`, etc.

2. **Priority Projects:**
   - Edit `_projectDescriptions` in `github_service.dart`
   - Add/remove projects with custom descriptions

3. **Firebase Configuration:**
   - Update `lib/config/firebase_config.dart` with your Firebase project values
   - Change Firestore collection/document paths if needed

4. **Project Scoring:**
   - Modify `_calculateProjectScore()` in `github_service.dart`
   - Adjust point values and thresholds

5. **Content Generation:**
   - Modify settings in `gemini_service.dart`
   - Adjust temperature, max tokens, prompts

6. **UI Theming:**
   - Update colors in `projects_section.dart`
   - Modify gradient colors and styles

## Dependencies

### Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^3.8.1
  cloud_firestore: ^5.5.2
  
  # AI & Natural Language
  google_generative_ai: ^0.2.0
  
  # Networking
  http: ^1.1.0
  
  # Data Persistence
  shared_preferences: ^2.2.2
  
  # PDF Generation
  pdf: ^3.10.7
  printing: ^5.11.1
  
  # File Operations
  file_saver: ^0.2.14
  
  # URL Handling
  url_launcher: ^6.3.0
  
  # UI Components
  visibility_detector: ^0.4.0+2
```

## Key Features Implementation

### 1. Secure Token Management

**Implementation:** `lib/services/firebase_token_service.dart`

```dart
// Initialize Firebase and fetch tokens
await FirebaseTokenService.initialize();

// Use tokens in services
final githubService = GitHubService(
  'YourUsername',
  token: FirebaseTokenService.githubToken,
  geminiApiKey: FirebaseTokenService.geminiApiKey,
);

// Check token availability
if (FirebaseTokenService.hasAllTokens) {
  // Both tokens loaded successfully
}
```

### 2. Intelligent Project Summaries

```dart
// Generate both summary types in one request
final summaries = await geminiService.generateBothSummaries(
  projectName: repoName,
  description: repo['description'],
  readme: readme,
  language: repo['language'],
);
```

### 3. Dynamic PDF Resume Generation

```dart
Future<Uint8List> generateResumePDF(List<Map<String, dynamic>> githubProjects)
```

**Features:**
- Uses generated project descriptions
- Firebase tokens automatically available
- Smart bullet point parsing
- Google Fonts integration

## Privacy & Security

### Data Handling
- **No user data collection** - Static portfolio site
- **GitHub API** - Public repository data only
- **Firebase Firestore** - Read-only token storage
- **Local caching** - All data stored locally in browser
- **No analytics** - No tracking integrated

### Security Best Practices
✅ API keys stored in Firebase Firestore  
✅ Read-only Firestore rules for public access  
✅ Write access only via Firebase Console  
✅ No secrets in Git repository  
✅ Tokens never exposed in client code  
✅ Rate limiting respected (GitHub API)  
✅ Error handling for failed requests  
✅ Offline mode fallback  

### Firebase Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /config/tokens {
      allow read: if true;   // Anyone can read
      allow write: if false; // Only you can write (via Console)
    }
  }
}
```

## Known Limitations

### Technical Limitations
1. **GitHub API Rate Limits:**
   - Without token: 60 requests/hour
   - With token: 5000 requests/hour
   - Caching mitigates this (24hr TTL)

2. **Google AI API:**
   - Requires API key (free tier available)
   - Rate limits apply (varies by plan)
   - Fallback to rule-based summaries on failure

3. **Firebase:**
   - Requires internet connection for first load
   - Free tier sufficient for personal portfolios
   - Tokens visible to anyone who inspects Firestore (use non-critical tokens)

4. **Browser Compatibility:**
   - Modern browsers recommended
   - Some animations may not work on older browsers

## Roadmap

### Planned Features
- [ ] Blog section with Markdown support
- [ ] Project filtering by technology/language
- [ ] Search functionality for projects
- [ ] Dark/Light theme toggle
- [ ] Multiple language support (i18n)
- [ ] Contact form with Firebase Functions
- [ ] Project detail pages with full README
- [ ] Resume customization for different roles
- [ ] Admin panel for Firebase token management

### Security Enhancements
- [ ] Token rotation reminders
- [ ] Firebase App Check integration
- [ ] Domain restrictions for API keys
- [ ] Rate limiting on client side

## Contributing

Contributions are welcome! This is a personal portfolio template that can be adapted for your own use.

### How to Contribute
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## Author

**Fays Arukattil**
- Portfolio: [faysarukattil.github.io](https://faysarukattil.github.io/FaysArukattil_Portfolio/)
- GitHub: [@FaysArukattil](https://github.com/FaysArukattil)
- LinkedIn: [FaysArukattil](https://linkedin.com/in/FaysArukattil)
- Email: faysarukattil@gmail.com

## Acknowledgments

### Technologies
- **Flutter Team** - Amazing cross-platform framework
- **Firebase** - Secure cloud infrastructure
- **Google AI** - Advanced language models
- **GitHub** - Version control and API

### Inspiration
- Modern portfolio designs from Dribbble and Behance
- Material Design 3 guidelines
- Glassmorphism UI trends

---

## Quick Start Checklist

- [ ] Clone repository
- [ ] Install Flutter dependencies
- [ ] Create Firebase project
- [ ] Enable Firestore Database
- [ ] Set Firestore security rules
- [ ] Add tokens to Firestore (`config/tokens` document)
- [ ] Register web app in Firebase
- [ ] Create `lib/config/firebase_config.dart`
- [ ] Update personal information
- [ ] Test locally (`flutter run -d chrome`)
- [ ] Build for web (`flutter build web`)
- [ ] Deploy to GitHub Pages

---

**Built with ❤️ using Flutter | Powered by Firebase & Google AI | Deployed on GitHub Pages**