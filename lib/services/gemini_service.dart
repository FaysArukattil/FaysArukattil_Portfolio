import 'package:flutter/widgets.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String apiKey;
  late final GenerativeModel _model;

  GeminiService(this.apiKey) {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', // Updated to latest stable model
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.4, // Lower for more consistent, professional output
        maxOutputTokens: 2000,
        topP: 0.8,
        topK: 40,
      ),
    );
  }

  /// Generate both summaries in a single API call (more efficient)
  Future<Map<String, String>> generateBothSummaries({
    required String projectName,
    required String? description,
    required String? readme,
    required String? language,
  }) async {
    try {
      final prompt = _buildEnhancedCombinedPrompt(
        projectName: projectName,
        description: description,
        readme: readme,
        language: language,
      );

      debugPrint('🤖 Calling Gemini for: $projectName');

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';

      if (text.isEmpty) {
        debugPrint('⚠️ Empty response from Gemini');
        return {
          'short': _generateFallbackShortSummary(projectName, description),
          'detailed': _generateFallbackDetailedSummary(projectName, language),
        };
      }

      debugPrint('✅ Gemini success for: $projectName');
      return _parseCombinedResponse(text, projectName, description, language);
    } catch (e) {
      debugPrint('❌ Gemini error for $projectName: $e');

      // Check if it's an API key error
      if (e.toString().contains('API key') || e.toString().contains('401')) {
        debugPrint('🔑 Invalid API key - check GEMINI_API_KEY in .env file');
      }

      return {
        'short': _generateFallbackShortSummary(projectName, description),
        'detailed': _generateFallbackDetailedSummary(projectName, language),
      };
    }
  }

  String _buildEnhancedCombinedPrompt({
    required String projectName,
    required String? description,
    required String? readme,
    required String? language,
  }) {
    final readmeSnippet = readme != null && readme.isNotEmpty
        ? readme.substring(0, readme.length > 3000 ? 3000 : readme.length)
        : '';

    return '''You are a professional technical writer creating resume content for a software developer's portfolio.

PROJECT INFORMATION:
Name: $projectName
Language: ${language ?? 'Flutter/Dart'}
Description: ${description ?? 'Not provided'}

README CONTENT:
${readmeSnippet.isNotEmpty ? readmeSnippet : 'Not available'}

TASK: Generate TWO professional summaries suitable for a resume/CV:

1. SHORT_SUMMARY (One sentence, 15-25 words):
   - Must be action-oriented using past tense verbs (Built, Created, Developed, Implemented)
   - Focus on WHAT was built and its PRIMARY PURPOSE
   - Include the key technology or approach used
   - Example: "Built an automated expense tracker that reads SMS/UPI notifications using background services and regex parsing to eliminate manual data entry"

2. DETAILED_SUMMARY (4-6 bullet points for resume):
   - Each bullet starts with a STRONG ACTION VERB (past tense)
   - Focus on technical implementation and HOW things work
   - Include specific technologies, APIs, libraries used
   - Quantify where possible (e.g., "50+ banks supported", "24/7 background service")
   - Each bullet should be 20-35 words
   - End with a "Tech stack:" line listing all technologies

FORMATTING RULES (CRITICAL):
- Use ONLY past tense verbs: Built, Created, Implemented, Developed, Designed, Integrated, Added, Set up
- Be SPECIFIC about technical details
- NO generic statements like "provides great UX"
- NO marketing language, only technical facts
- NO emojis or special characters
- Each bullet focuses on ONE feature or capability

EXAMPLE FORMAT (study carefully):

SHORT_SUMMARY: Built an automated expense tracker that reads SMS and UPI notifications using background services to eliminate manual transaction entry

DETAILED_SUMMARY:
- Built automated expense tracking system that monitors SMS and UPI notifications 24/7 using Android notification listener service with regex-based transaction parsing
- Implemented intelligent duplicate detection system using notification hash comparison to prevent same transaction being recorded multiple times
- Created comprehensive analytics dashboard displaying daily, weekly, and monthly spending patterns with interactive charts using FL Chart library
- Designed offline-first architecture with SQLite database for local data persistence and PDF export functionality for transaction reports
- Integrated AI-powered categorization engine analyzing transaction notes to automatically sort expenses into spending categories
- Tech stack: Flutter, Dart, SQLite, Notification Listener Service, FL Chart, Background Services, PDF Generation, Regex

YOUR RESPONSE (use EXACT format above):''';
  }

  Map<String, String> _parseCombinedResponse(
    String response,
    String projectName,
    String? description,
    String? language,
  ) {
    try {
      // Extract SHORT_SUMMARY
      final shortMatch = RegExp(
        r'SHORT_SUMMARY:\s*(.+?)(?=\n\n|\nDETAILED_SUMMARY:|$)',
        dotAll: true,
        caseSensitive: false,
      ).firstMatch(response);

      // Extract DETAILED_SUMMARY
      final detailedMatch = RegExp(
        r'DETAILED_SUMMARY:\s*(.+)',
        dotAll: true,
        caseSensitive: false,
      ).firstMatch(response);

      String shortSummary = '';
      String detailedSummary = '';

      if (shortMatch != null) {
        shortSummary = shortMatch.group(1)!.trim();
        // Clean up short summary
        shortSummary = shortSummary
            .replaceAll(RegExp(r'^[-*\d.]+\s*'), '')
            .replaceAll(RegExp(r'[\n\r]+'), ' ')
            .trim();
      }

      if (detailedMatch != null) {
        final detailedText = detailedMatch.group(1)!.trim();
        final lines = detailedText.split('\n');
        final cleanedLines = <String>[];

        for (var line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;

          // Keep lines that are bullet points or substantial content
          if (trimmed.startsWith('-') ||
              trimmed.startsWith('*') ||
              trimmed.startsWith('•') ||
              RegExp(r'^\d+\.').hasMatch(trimmed) ||
              trimmed.toLowerCase().startsWith('tech stack:')) {
            // Normalize bullet point
            var cleaned = trimmed;
            if (!cleaned.startsWith('-')) {
              cleaned = cleaned.replaceFirst(RegExp(r'^[*•\d.]+\s*'), '- ');
            }
            cleanedLines.add(cleaned);
          }
        }

        detailedSummary = cleanedLines.join('\n');
      }

      // Validate and use fallbacks if needed
      if (shortSummary.isEmpty || shortSummary.length < 20) {
        shortSummary = _generateFallbackShortSummary(projectName, description);
      }

      if (detailedSummary.isEmpty || detailedSummary.split('\n').length < 3) {
        detailedSummary =
            _generateFallbackDetailedSummary(projectName, language);
      }

      return {
        'short': shortSummary,
        'detailed': detailedSummary,
      };
    } catch (e) {
      debugPrint('Error parsing Gemini response: $e');
      return {
        'short': _generateFallbackShortSummary(projectName, description),
        'detailed': _generateFallbackDetailedSummary(projectName, language),
      };
    }
  }

  String _generateFallbackShortSummary(
      String projectName, String? description) {
    if (description != null && description.isNotEmpty) {
      // Try to make it action-oriented
      final desc = description.trim();
      if (desc.length > 150) {
        return 'Built ${desc.substring(0, 147)}...';
      }
      if (!desc.toLowerCase().startsWith('built') &&
          !desc.toLowerCase().startsWith('created') &&
          !desc.toLowerCase().startsWith('developed')) {
        return 'Built $desc';
      }
      return desc;
    }

    final cleanName =
        projectName.replaceAll('_', ' ').replaceAll('-', ' ').trim();

    return 'Built $cleanName application using Flutter with modern development practices and clean architecture';
  }

  String _generateFallbackDetailedSummary(
      String projectName, String? language) {
    final tech = language ?? 'Flutter & Dart';
    final cleanName =
        projectName.replaceAll('_', ' ').replaceAll('-', ' ').trim();

    return '''- Developed $cleanName mobile application using $tech with focus on performance and user experience
- Implemented clean architecture pattern with proper separation of concerns and state management
- Created responsive UI design that adapts seamlessly to different screen sizes and orientations
- Integrated modern Flutter packages and libraries following best practices for code maintainability
- Built offline-first functionality with local data persistence for reliable user experience
- Tech stack: Flutter, Dart, Provider/Bloc, REST APIs, SQLite/Hive''';
  }
}
