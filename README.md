# 🎨 Fays Arukattil - Portfolio Website

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Google AI](https://img.shields.io/badge/Google_AI-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev/)
[![Live Demo](https://img.shields.io/badge/Live-Demo-success?style=for-the-badge)](https://faysarukattil.github.io/FaysArukattil_Portfolio/)

A modern, responsive portfolio website built with Flutter that showcases my projects, skills, and professional experience. Features **intelligent project descriptions** using Google's Generative AI, dynamic GitHub integration, automated resume generation, and a sleek glassmorphism UI.

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
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

This portfolio website is built with Flutter Web and serves as a dynamic showcase of my development work. The site automatically fetches projects from GitHub, uses **advanced natural language processing** to generate compelling project descriptions, filters projects based on quality metrics, and generates professional PDF resumes on-demand with enhanced content.

**Entry point:** `lib/main.dart`
- Direct navigation to `HomeScreen` (no loading screen delay)
- Optimized for fast first paint

**Key screens:**
- `lib/homescreen.dart` - Main portfolio with Hero, Skills, Projects, and Contact sections
- `lib/loading_screen.dart` - Asset preloading (optional, currently bypassed)
- `lib/widgets/projects_section.dart` - Reusable projects grid component

**Services:**
- `lib/services/github_service.dart` - GitHub API integration with intelligent filtering
- `lib/services/gemini_service.dart` - Natural language generation for project content
- `lib/services/resume_generator_service.dart` - Dynamic PDF resume generation
- `lib/services/env_loader_service.dart` - Async environment configuration loader

## Features

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
- **Intelligent Project Selection:**
  - Priority projects listed first (Buddy, Instagram Clone, Portfolio)
  - Non-priority projects sorted by quality score
  - Maximum 5 projects to keep resume concise
  - 6 highlights per project maximum

### 🎯 Smart Project Showcase
- **Auto-Generated Summaries:** Natural language processing creates compelling project descriptions
- **Adaptive Content:** Concise summaries for cards, detailed analyses on hover (desktop)
- **Feature Extraction:** Automatically identifies and highlights key features from documentation
- **Technology Detection:** Recognizes and displays tech stack automatically
- **Technical Highlights:** Extracts architecture and implementation details intelligently
- **Hover Interactions:** Desktop users see detailed technical descriptions on hover
- **Responsive Cards:** Beautiful gradient-based cards with project-specific colors
- **GitHub Links:** Direct navigation to source code with visual indicators

### 💾 Advanced Caching System
- **Multi-Layer Cache:**
  - Raw GitHub API responses (24hr TTL)
  - Filtered/scored projects with generated summaries (24hr TTL)
  - Generated PDF bytes (persistent)
  - Project data for comparison (persistent)
- **Offline Support:** Graceful fallback to cached data on network failure
- **Smart Invalidation:** Automatic cache refresh on project changes
- **Background Updates:** Cache refreshed silently without blocking UI
- **Content Caching:** Generated summaries cached to optimize performance

### 🔧 Async Environment Configuration
- **EnvLoaderService:** Non-blocking environment variable loading
- **Lazy Loading:** API keys loaded asynchronously after app start
- **Graceful Degradation:** App functions with cached data while config loads
- **Status Tracking:** Built-in loading state management
- **Error Resilience:** Continues operation even if .env loading fails

### 🎨 Modern UI/UX
- **Glassmorphism Design:** Frosted glass effects with gradient accents
- **Smooth Animations:** 
  - Fade-in sections on scroll
  - Logo pulse animation
  - Hover scale effects with color intensity changes
  - Progress bar transitions
  - Button state changes
  - Expandable project cards
- **Section Navigation:** Smart scroll tracking with active indicators
- **Micro-interactions:** Hover effects, button animations, loading states
- **Material Design 3:** Modern components and elevation system
- **Visual Feedback:** Loading states for content generation, refresh actions, and resume downloads

### 📱 Fully Responsive
- **Desktop (>1024px):** 
  - Full navigation bar
  - Hover effects enabled with detailed summaries
  - 2-3 column project grid (responsive to width)
  - Side-by-side hero layout
  - Expandable project cards on hover
- **Tablet (768-1024px):**
  - Adjusted navigation
  - 2-column project grid
  - Stacked hero sections
  - Touch interactions
- **Mobile (<768px):**
  - Hamburger menu
  - Single-column layout
  - Touch-optimized interactions
  - Concise summaries only (no hover expansion)
  - Condensed content

## Tech Stack

### Framework & Language
- **Flutter 3.0+** - Cross-platform UI framework
- **Dart SDK 3.0+** - Programming language

### AI & Natural Language Processing
- **google_generative_ai 0.2.0+** - Google's Generative AI SDK for content generation
- **Gemini 2.5 Flash** - High-performance language model for text analysis and generation

### State Management
- **StatefulWidget** - Local component state
- **Provider** - Dependency injection (ready for future use)

### API & Networking
- **http 1.1.0** - HTTP client for GitHub API calls
- **REST API** - GitHub REST API v3

### Data Persistence
- **shared_preferences 2.2.2** - Local key-value storage for caching
- **Persistent caching** for generated summaries and PDF bytes

### PDF Generation
- **pdf 3.10.7** - PDF document creation
- **printing 5.11.1** - PDF rendering and Google Fonts support (Roboto Regular, Bold, Italic)

### File Operations
- **file_saver 0.2.14** - Cross-platform file saving
- **path_provider 2.1.5** - Platform-specific paths

### Environment Configuration
- **flutter_dotenv 5.1.0** - Environment variable management for API keys

### URL Handling
- **url_launcher 6.3.0** - Open external links

### Development Tools
- **flutter_native_splash 2.4.2** - Splash screen generation
- **flutter_lints 6.0.0** - Dart code analysis rules

## Architecture

### Project Structure
```
lib/
├── main.dart                          # App entry point
├── homescreen.dart                    # Main portfolio screen
├── loading_screen.dart                # Optional asset preloader
├── services/
│   ├── github_service.dart           # GitHub API + content generation
│   ├── gemini_service.dart           # Language model service
│   ├── resume_generator_service.dart # PDF generation
│   └── env_loader_service.dart       # Async environment loader
└── widgets/
    └── projects_section.dart         # Projects grid component
```

### Service Architecture

#### GitHubService
- Fetches repositories from GitHub API
- Implements intelligent project scoring algorithm
- Integrates with GeminiService for content generation
- Manages multi-layer caching (repos, filtered data)
- Handles priority project custom descriptions
- Filters learning/tutorial repositories

#### GeminiService
- **Model:** `gemini-2.5-flash` - High-performance language model
- **Configuration:**
  - Temperature: 0.7 (balanced creativity/accuracy)
  - Max tokens: 1000
- **Methods:**
  - `generateShortSummary()` - Concise 1-2 line summaries
  - `generateDetailedSummary()` - 4-6 bullet point technical breakdowns
  - `generateBothSummaries()` - Efficient single request for both formats
- **Content Strategy:**
  - Technical writing focused on functionality
  - Extracts features from README analysis
  - Emphasizes what projects do, not just what they are
  - Structured output formatting
- **Error Handling:**
  - Automatic fallback to rule-based generation
  - Graceful degradation on failures
  - Comprehensive error logging

#### ResumeGeneratorService
- Generates professional LaTeX-quality PDF resumes
- **Content Integration:** Uses generated summaries for project descriptions
- **Smart Extraction:** Parses detailed summaries into structured bullet points
- **Font Caching:** Loads Google Fonts once and reuses
- **Text Sanitization:** Removes emojis and special Unicode characters
- **Dynamic Project Selection:**
  - Priority projects (Buddy, Instagram Clone) with enhanced descriptions
  - Additional high-quality projects from GitHub
  - Intelligent highlight extraction from generated content
  - Maximum 6 highlights per project
- **Resume Sections:**
  - Header with contact information
  - Professional summary
  - Skills (categorized)
  - Experience
  - Projects (with rich descriptions)
  - Education
  - Certifications

#### EnvLoaderService (NEW!)
- **Async Environment Loading:** Non-blocking .env file loading
- **State Management:**
  - `isLoaded` - Check if environment is ready
  - `ensureLoaded()` - Async loading with deduplication
- **Safe Access Methods:**
  - `get(key)` - Returns null if not loaded or key missing
  - `getOrDefault(key, default)` - Returns fallback value
- **Error Handling:**
  - Graceful failure when .env unavailable
  - Debug logging for troubleshooting
  - App continues with cached data
- **Usage Pattern:**
  ```dart
  await EnvLoaderService.ensureLoaded();
  final token = EnvLoaderService.get('GITHUB_TOKEN');
  ```

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

### Content Strategy

**Concise Summaries:**
- Focus on what the application accomplishes
- Single compelling sentence (max 150 chars)
- Mentions primary feature or problem solved
- Active voice and clear language
- Technical when relevant

**Detailed Breakdowns:**
- 4-6 structured bullet points
- Specific technical details
- Technologies and frameworks mentioned
- Unique/impressive features highlighted
- Professional technical language

**Example Output:**
```
CONCISE:
A Flutter expense tracker that automatically extracts transactions from SMS notifications and provides real-time spending analytics.

DETAILED:
- Built automated expense tracking system that reads UPI and SMS notifications using background services
- Implemented regex-based transaction parser supporting 50+ Indian banks and payment providers
- Created interactive analytics dashboard with daily, weekly, and monthly spending insights using FL Chart
- Designed offline-first architecture with SQLite for local data persistence and zero server dependencies
```

## Project Scoring Algorithm

Projects are scored automatically based on multiple criteria (0-55 points total):

### Scoring Breakdown
1. **README Length** (0-15 points)
   - ≥5000 chars: 15 points
   - ≥3000 chars: 10 points
   - ≥2000 chars: 7 points
   - ≥1000 chars: 3 points

2. **Visual Content** (0-10 points)
   - ≥5 images: 10 points
   - ≥3 images: 7 points
   - ≥1 image: 4 points

3. **Documentation Structure** (0-8 points)
   - ≥8 headings: 8 points
   - ≥6 headings: 6 points
   - ≥4 headings: 4 points

4. **Code Examples** (0-6 points)
   - ≥4 code blocks: 6 points
   - ≥2 code blocks: 4 points
   - ≥1 code block: 2 points

5. **Documentation Quality** (0-12 points)
   - Contains keywords: features, demo, screenshots, installation, getting started, architecture, technologies, built with

6. **Project Maturity** (0-4 points)
   - Has description (>20 chars): 2 points
   - Updated within 180 days: 2 points

### Filtering Rules
- **Minimum Score:** 15 points (for non-priority projects)
- **Priority Projects:** Always included (score overridden to 100)
- **Learning Projects:** Automatically filtered out based on keywords (learn, tutorial, practice, etc.)
- **Display Order:** Priority projects first, then sorted by score (highest to lowest)

## Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Git
- **GitHub Personal Access Token** (optional but recommended for higher rate limits)
- **Google AI API Key** (optional but recommended for intelligent features)

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

3. **Set up environment variables:**

Create a `.env` file in the project root:
```env
GITHUB_USERNAME=YourGitHubUsername
GITHUB_TOKEN=ghp_your_github_personal_access_token
GEMINI_API_KEY=your_api_key_here
```

**Getting API Keys:**

- **GitHub Token:** 
  1. Go to GitHub Settings → Developer settings → Personal access tokens
  2. Generate new token (classic)
  3. Select scopes: `public_repo` (read access to public repositories)
  4. Copy token and add to `.env`

- **Google AI API Key:**
  1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
  2. Create new API key
  3. Copy key and add to `.env`

4. **Configure the app:**

The app uses `EnvLoaderService` for async environment loading:
```dart
// Environment is loaded asynchronously after app start
await EnvLoaderService.ensureLoaded();
final githubUsername = EnvLoaderService.getOrDefault('GITHUB_USERNAME', 'FaysArukattil');
final githubToken = EnvLoaderService.get('GITHUB_TOKEN');
final geminiApiKey = EnvLoaderService.get('GEMINI_API_KEY');
```

5. **Run the app:**

For web:
```bash
flutter run -d chrome
```

For desktop:
```bash
flutter run -d windows  # or macos/linux
```

For mobile:
```bash
flutter run -d <device-id>
```

### Building for Production

**Web:**
```bash
flutter build web --release --base-href "/FaysArukattil_Portfolio/"
```

**Desktop:**
```bash
flutter build windows --release  # or macos/linux
```

**Mobile:**
```bash
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

## Configuration

### Customization Options

1. **Update Personal Information:**
   - Edit `ResumeGeneratorService` in `lib/services/resume_generator_service.dart`
   - Update `_personalInfo`, `_professionalSummary`, `_skills`, `_experience`, etc.

2. **Priority Projects:**
   - Edit `_projectDescriptions` in `lib/services/github_service.dart`
   - Add/remove projects with custom short and detailed descriptions

3. **Project Scoring:**
   - Modify `_calculateProjectScore()` in `lib/services/github_service.dart`
   - Adjust point values for different criteria
   - Change minimum score threshold

4. **Content Generation Settings:**
   - Modify settings in `lib/services/gemini_service.dart`
   - Adjust temperature, max tokens
   - Customize prompt templates
   - Change fallback behavior

5. **UI Theming:**
   - Update colors in `lib/widgets/projects_section.dart`
   - Modify `_projectColors` array for different gradient colors
   - Adjust glassmorphism effects and border styles

6. **Caching Duration:**
   - Change `_cacheDuration` in `lib/services/github_service.dart`
   - Default: 24 hours

7. **Environment Loading:**
   - Customize `EnvLoaderService` in `lib/services/env_loader_service.dart`
   - Modify loading behavior and error handling
   - Add custom environment variable accessors

## Dependencies

### Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  
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
  path_provider: ^2.1.5
  
  # Environment
  flutter_dotenv: ^5.1.0
  
  # URL Handling
  url_launcher: ^6.3.0
```

### Dev Dependencies
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  flutter_native_splash: ^2.4.2
```

## Key Features Implementation

### 1. Intelligent Project Summaries

**Implementation:** `lib/services/gemini_service.dart`

```dart
// Generate both summary types in one request
final summaries = await geminiService.generateBothSummaries(
  projectName: repoName,
  description: repo['description'],
  readme: readme,
  language: repo['language'],
);

// Returns:
// {
//   'short': 'One-line technical summary',
//   'detailed': '- Bullet point 1\n- Bullet point 2\n...'
// }
```

**Features:**
- Concurrent generation of short and detailed summaries
- Intelligent README content extraction (first 2000 chars)
- Fallback to rule-based generation on failure
- Cached responses to minimize API calls

### 2. Async Environment Loading

**Implementation:** `lib/services/env_loader_service.dart`

```dart
// Load environment asynchronously
await EnvLoaderService.ensureLoaded();

// Check loading status
if (EnvLoaderService.isLoaded) {
  final token = EnvLoaderService.get('GITHUB_TOKEN');
}

// Use with fallback
final username = EnvLoaderService.getOrDefault(
  'GITHUB_USERNAME', 
  'FaysArukattil'
);
```

**Features:**
- Non-blocking environment initialization
- Deduplication prevents multiple simultaneous loads
- Safe access with null handling
- Graceful degradation on errors
- Debug logging for troubleshooting

### 3. Intelligent Project Filtering

**Implementation:** `lib/services/github_service.dart`

```dart
Future<List<Map<String, dynamic>>> fetchFilteredRepositories()
```

**Process:**
1. Fetch all repositories from GitHub
2. Filter out learning/tutorial projects
3. Fetch README for each remaining project
4. Calculate quality score
5. Generate intelligent summaries for qualifying projects
6. Sort by priority status and score
7. Cache results

### 4. Dynamic PDF Resume Generation

**Implementation:** `lib/services/resume_generator_service.dart`

```dart
Future<Uint8List> generateResumePDF(List<Map<String, dynamic>> githubProjects)
```

**Features:**
- Uses generated project descriptions
- Extracts highlights from detailed summaries
- Smart bullet point parsing
- Emoji/special character sanitization
- Google Fonts integration (Roboto family)
- Multi-page support with headers and footers
- Automatic page numbering

### 5. Smart Caching System

**Layers:**
1. **Raw GitHub Data** (24hr TTL)
   - All repository information
   - Stored in SharedPreferences

2. **Filtered Projects with Summaries** (24hr TTL)
   - Scored and filtered repositories
   - Generated short and detailed summaries
   - Display titles and metadata

3. **PDF Bytes** (Persistent)
   - Generated resume PDF
   - Instant downloads after first generation

4. **Project Comparison Data** (Persistent)
   - Used to detect changes
   - Triggers cache invalidation

## UI Highlights

### Project Cards
- **Gradient backgrounds** with project-specific colors
- **Hover animations** (desktop): Scale up, enhanced glow, border highlight
- **Expandable content**: Short summaries expand to detailed descriptions on hover
- **Scrollable detailed view**: For lengthy generated descriptions
- **Icon indicators**: Language badges, GitHub links
- **Touch-optimized**: Tap to navigate on mobile

### Hero Section
- **Animated logo** with pulse effect
- **Gradient text** for headings
- **Profile image** with glassmorphism border
- **Social links** with hover effects
- **Download resume button** with loading states

### Skills Section
- **Categorized display**: Programming, Frameworks, Tools, Soft Skills
- **Grid layout**: Responsive to screen size
- **Visual hierarchy**: Clear section organization

### Contact Section
- **Social media links**: LinkedIn, GitHub, Email
- **Icon buttons** with hover effects
- **Responsive layout**: Adapts to screen size

## Responsive Design

### Breakpoints
- **Mobile:** ≤768px
- **Tablet:** 769px - 1024px
- **Desktop:** >1024px

### Adaptive Features

**Desktop:**
- 2-3 column project grid (width-dependent)
- Hover-triggered detailed summaries
- Full navigation bar
- Side-by-side layouts
- Enhanced animations

**Tablet:**
- 2 column project grid
- Touch interactions
- Adjusted spacing
- Stacked sections

**Mobile:**
- Single column layouts
- Short summaries only
- Touch-optimized buttons
- Condensed navigation
- Hamburger menu

## Privacy & Security

### Data Handling
- **No user data collection**: Static portfolio site
- **GitHub API**: Public repository data only
- **Local caching**: All data stored locally in browser
- **No analytics**: No tracking or analytics integrated
- **API keys**: Stored in `.env` file (never committed to Git)

### Environment Variables
- GitHub token: Optional, improves rate limits
- Google AI API key: Optional, enables intelligent features
- Never expose API keys in source code
- Use `.env` file (add to `.gitignore`)

### Security Best Practices
- ✅ API keys in environment variables
- ✅ `.gitignore` includes `.env` file
- ✅ Rate limiting respected (GitHub API)
- ✅ Error handling for failed requests
- ✅ Offline mode fallback
- ✅ Input sanitization in PDF generation
- ✅ Async environment loading prevents blocking

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

3. **PDF Generation:**
   - Emoji/special character removal necessary
   - Limited to LaTeX-compatible fonts
   - No embedded images in PDF (links only)

4. **Browser Compatibility:**
   - Modern browsers recommended (Chrome, Firefox, Safari, Edge)
   - Some animations may not work on older browsers

5. **Mobile Performance:**
   - Large PDFs may be slow to generate on low-end devices
   - API calls require stable internet connection

### Functional Limitations
- **Static site**: No backend server
- **No authentication**: Public portfolio only
- **Read-only**: Cannot modify GitHub data
- **Single user**: Designed for one portfolio

## Roadmap

### Planned Features
- [ ] **Blog section** with Markdown support
- [ ] **Project filtering** by technology/language
- [ ] **Search functionality** for projects
- [ ] **Dark/Light theme toggle**
- [ ] **Multiple language support** (i18n)
- [ ] **Analytics integration** (optional, privacy-focused)
- [ ] **Contact form** with email integration
- [ ] **Project detail pages** with full README display
- [ ] **Timeline view** for experience/education
- [ ] **Testimonials section**
- [ ] **Resume download in multiple formats** (PDF, Markdown, JSON)

### Content Enhancement Ideas
- [ ] **Automated project categorization** by technology
- [ ] **Skill level assessment** from project analysis
- [ ] **Technical blog generation** from project READMEs
- [ ] **Resume customization** based on different roles
- [ ] **Interactive Q&A** about projects and experience

## Contributing

Contributions are welcome! This is a personal portfolio template that can be adapted for your own use.

### How to Contribute
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter/Dart style guidelines
- Write meaningful commit messages
- Test on multiple screen sizes
- Document new features
- Update README when adding features

## Author

**Fays Arukattil**
- Portfolio: [faysarukattil.github.io](https://faysarukattil.github.io/FaysArukattil_Portfolio/)
- GitHub: [@FaysArukattil](https://github.com/FaysArukattil)
- LinkedIn: [FaysArukattil](https://linkedin.com/in/FaysArukattil)
- Email: faysarukattil@gmail.com

## Acknowledgments

### Technologies
- **Flutter Team** - Amazing cross-platform framework
- **Google AI** - Advanced language models for content generation
- **GitHub** - Version control and API
- **Dart Team** - Powerful programming language

### Inspiration
- Modern portfolio designs from Dribbble and Behance
- Material Design 3 guidelines
- Glassmorphism UI trends

### Libraries & Tools
- `google_generative_ai` - Google's Generative AI SDK
- `pdf` & `printing` packages - Professional PDF generation
- `http` package - Reliable networking
- `shared_preferences` - Simple caching solution
- `flutter_dotenv` - Environment configuration

---

## License

This project is open source and available under the MIT License. Feel free to use this template for your own portfolio!

---

## Quick Start Checklist

- [ ] Clone repository
- [ ] Install Flutter dependencies (`flutter pub get`)
- [ ] Create `.env` file with API keys
- [ ] Update personal information in `resume_generator_service.dart`
- [ ] Configure priority projects in `github_service.dart`
- [ ] Customize UI colors and theme
- [ ] Test on multiple screen sizes
- [ ] Build for web (`flutter build web`)
- [ ] Deploy to GitHub Pages or hosting service

---

**Built with ❤️ Developed in Flutter, featuring real-time data integration via the GitHub API and intelligent summarization powered by Gemini 2.5 Flash.**

