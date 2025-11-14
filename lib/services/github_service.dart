import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GitHubService {
  static const String _baseUrl = 'https://api.github.com';
  static const String _cacheKeyRepos = 'cached_repos';
  static const String _cacheKeyFilteredRepos = 'cached_filtered_repos';
  static const String _cacheKeyTimestamp = 'cache_timestamp';
  static const String _cacheKeyFilteredTimestamp = 'cache_filtered_timestamp';
  static const Duration _cacheDuration = Duration(hours: 24);

  static const Map<String, Map<String, String>> _projectDescriptions = {
    'instagram_clone': {
      'title': 'Instagram Clone',
      'short':
          'Full-featured social media app with Reels, Stories, Messenger, and offline-first architecture.',
      'detailed':
          '''- Recreated Instagram's complete feature set including feed, reels, messenger, search functionality, and profile management
- Implemented video player with auto-play detection when scrolling through reels and pinch-to-zoom capabilities for photo viewing
- Built camera integration and gallery picker allowing users to capture photos, record videos, and share as posts, stories, or reels
- Developed local persistence layer using SharedPreferences storing posts, comments, likes, follows, and all user interactions
- Created explore page with Pinterest-style staggered grid layout and real-time messaging system with read receipts
- Tech stack: Flutter, Dart, video_player, camera, image_picker, SharedPreferences, photo_view, 16+ packages'''
    },
    'buddy_expense_tracker': {
      'title': 'Buddy - Expense Tracker',
      'short':
          'AI-powered expense tracker that automatically captures transactions from SMS/UPI notifications - works 24/7 in background.',
      'detailed':
          '''- Built AI-powered expense tracker that automatically captures transactions from SMS/UPI notifications without manual data entry
- Created background service running 24/7 using regex patterns to extract amount, merchant, and category from notification content
- Implemented duplicate detection system comparing notification hashes to prevent same transaction being added multiple times
- Designed comprehensive analytics dashboard showing daily, weekly, monthly, and yearly spending insights with FL Chart visualization
- Integrated SQLite database for local storage with PDF export functionality for generating transaction reports
- Added AI categorization that intelligently sorts spending by analyzing transaction notes for better financial insights
- Tech stack: Flutter, Dart, SQLite, notification_listener_service, FL Chart, Background Services, PDF generation'''
    },
    'stylish_ecommerce_website': {
      'title': 'Stylish - E-commerce App',
      'short':
          'First hands-on E-commerce prototype built from Figma design with clean UI, cart & wishlist functionality.',
      'detailed':
          '''- Built clean and responsive UI translated directly from Figma design specifications with pixel-perfect accuracy
- Implemented product catalog system with cart management and wishlist functionality for seamless shopping experience
- Added comprehensive form validation and user input handling following best practices
- Created responsive layouts optimized for different screen sizes ensuring consistent experience across devices
- Developed professional E-commerce workflow design demonstrating strong UI/UX implementation skills
- Tech stack: Flutter, Dart, Material Design components, Provider state management
- Note: Learning project with local data storage, backend integration and payment gateway planned for future versions'''
    },
  };

  static const List<String> _learningKeywords = [
    'learn',
    'learning',
    'tutorial',
    'practice',
    'exercise',
    'course',
    'bootcamp',
    'training',
    'sample',
    'demo-only',
    'test-project',
    'playground',
    'experiment',
  ];

  final String username;
  final String? token;
  final String? _geminiApiKey;

  GitHubService(
    this.username, {
    this.token,
    String? geminiApiKey,
  }) : _geminiApiKey = geminiApiKey;

  Map<String, String> get _headers {
    final headers = {
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'Flutter-Portfolio-App',
    };
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  bool _isPriorityProject(String repoName) {
    final lowerName = repoName.toLowerCase();
    return _projectDescriptions.keys.any((priority) =>
        lowerName.contains(priority.toLowerCase()) ||
        priority.toLowerCase().contains(lowerName));
  }

  bool _isLearningRepository(String repoName, String? description) {
    final lowerName = repoName.toLowerCase();
    final lowerDesc = (description ?? '').toLowerCase();
    return _learningKeywords.any((keyword) =>
        lowerName.contains(keyword) || lowerDesc.contains(keyword));
  }

  String _getProjectKey(String repoName) {
    final lowerName = repoName.toLowerCase();
    for (var key in _projectDescriptions.keys) {
      if (lowerName.contains(key.toLowerCase()) ||
          key.toLowerCase().contains(lowerName)) {
        return key;
      }
    }
    return '';
  }

  String _generateProjectTitle(String repoName) {
    final projectKey = _getProjectKey(repoName);
    if (projectKey.isNotEmpty && _projectDescriptions.containsKey(projectKey)) {
      return _projectDescriptions[projectKey]!['title']!;
    }

    return repoName
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) {
      if (word.isEmpty) return '';
      if (word.toLowerCase() == 'ui') return 'UI';
      if (word.toLowerCase() == 'api') return 'API';
      if (word.toLowerCase() == 'app') return 'App';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Future<Map<String, String>> _generateSummaries(
    String repoName,
    String readme,
    Map<String, dynamic> repo,
  ) async {
    try {
      final projectKey = _getProjectKey(repoName);

      if (projectKey.isNotEmpty &&
          _projectDescriptions.containsKey(projectKey)) {
        return {
          'short': _projectDescriptions[projectKey]!['short']!,
          'detailed': _projectDescriptions[projectKey]!['detailed']!,
        };
      }

      final cacheKey = 'summaries_$repoName';
      final cached = await _getCachedSummary(cacheKey);
      if (cached != null) {
        return cached;
      }

      // Only use Gemini if API key is provided and not empty
      if (_geminiApiKey != null &&
          _geminiApiKey!.isNotEmpty &&
          _geminiApiKey!.length > 10) {
        try {
          debugPrint('🤖 Using Gemini AI for: $repoName');

          final description = repo['description'] as String?;
          final topics = (repo['topics'] as List?)?.join(', ') ?? '';

          final prompt = '''
You are a technical resume writer. Generate project descriptions for a Flutter developer's resume.

Project: $repoName
Description: ${description ?? 'Flutter project'}
Topics: $topics

README Content:
${readme.length > 3000 ? readme.substring(0, 3000) : readme}

Generate TWO descriptions:

1. SHORT_SUMMARY (one concise sentence, 15-25 words):
- Must be a complete sentence describing what the app does
- Use action words: "built", "created", "developed"
- Example format: "Built an expense tracker that automatically reads transaction SMS and UPI notifications to add expenses without manual entry"

2. DETAILED_SUMMARY (4-6 action-oriented bullet points for a resume):
CRITICAL REQUIREMENTS:
- Each point must start with a strong past-tense action verb: Built, Created, Implemented, Designed, Developed, Added, Integrated, Set up, etc.
- Focus on WHAT was built and HOW it works technically
- Include specific technical details (APIs, libraries, features)
- Avoid generic statements
- Each point should be 15-30 words
- Format as bullet points with "-" prefix

EXAMPLE FORMAT (study this carefully):
- Built an expense tracker that automatically reads transaction SMS and UPI notifications to add expenses without manual entry
- Created a background service that keeps running even when the app is closed, using regex patterns to extract transaction details
- Added duplicate detection by comparing notification hashes so the same transaction doesn't get added twice
- Designed analytics screens showing daily, weekly, monthly stats with interactive charts using FL Chart library
- Used SQLite for local storage and added PDF export feature to generate transaction reports
- Tech stack: Flutter, Dart, SQLite, Notification Listener Service, FL Chart

FORMAT YOUR RESPONSE EXACTLY AS:
SHORT_SUMMARY: [your one-sentence summary]

DETAILED_SUMMARY:
- [First action-oriented bullet point with technical details]
- [Second point describing implementation/how it works]
- [Third point about a key feature with specifics]
- [Fourth point about another feature or technology]
- [Optional fifth point if there's more significant functionality]
- Tech stack: [List main technologies, libraries, APIs used]

DO NOT include any other text, explanations, or markdown formatting. Just the summaries.
''';

          final model = GenerativeModel(
            model: 'gemini-2.5-flash',
            apiKey: _geminiApiKey!,
          );

          final content = [Content.text(prompt)];
          final response = await model.generateContent(content);

          if (response.text != null) {
            final summaries = _parseSummaryResponse(response.text!);
            await _cacheSummary(cacheKey, summaries);
            debugPrint('✅ Gemini success: $repoName');
            return summaries;
          }
        } catch (e) {
          debugPrint('❌ Gemini failed for $repoName: $e');
        }
      }

      return _getDefaultSummaries(repoName, repo['description'] as String?);
    } catch (e) {
      debugPrint('Error generating summaries for $repoName: $e');
      return _getDefaultSummaries(repoName, repo['description'] as String?);
    }
  }

  Map<String, String> _parseSummaryResponse(String response) {
    try {
      final shortMatch = RegExp(
        r'SHORT_SUMMARY:\s*(.+?)(?=\n\n|DETAILED_SUMMARY:)',
        dotAll: true,
        caseSensitive: false,
      ).firstMatch(response);

      final detailedMatch = RegExp(
        r'DETAILED_SUMMARY:\s*(.+)',
        dotAll: true,
        caseSensitive: false,
      ).firstMatch(response);

      String shortSummary = 'Flutter mobile application';
      String detailedSummary = '';

      if (shortMatch != null) {
        shortSummary = shortMatch.group(1)!.trim();
        shortSummary =
            shortSummary.replaceAll(RegExp(r'^[-*\d.]+\s*'), '').trim();
      }

      if (detailedMatch != null) {
        detailedSummary = detailedMatch.group(1)!.trim();

        final lines = detailedSummary.split('\n');
        final cleanedLines = <String>[];

        for (var line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;

          if (trimmed.startsWith('-') ||
              trimmed.startsWith('*') ||
              RegExp(r'^\d+\.').hasMatch(trimmed) ||
              trimmed.length > 30) {
            cleanedLines.add(trimmed);
          }
        }

        detailedSummary = cleanedLines.join('\n');
      }

      return {
        'short': shortSummary,
        'detailed': detailedSummary,
      };
    } catch (e) {
      debugPrint('Error parsing summary response: $e');
      return {
        'short': 'Flutter mobile application',
        'detailed':
            '- Professional Flutter application with modern architecture\n- Built with clean code practices and best design patterns',
      };
    }
  }

  Map<String, String> _getDefaultSummaries(
      String repoName, String? description) {
    final projectTitle = _generateProjectTitle(repoName);

    return {
      'short': description ??
          'A professional $projectTitle application built with Flutter',
      'detailed': '''
- Built $projectTitle with Flutter focusing on clean architecture and performance
- Implemented modern development practices and design patterns
- Created responsive UI with smooth animations and transitions
- Integrated key features for enhanced user experience
- Tech stack: Flutter, Dart, and modern libraries
''',
    };
  }

  Future<Map<String, String>?> _getCachedSummary(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);
      if (cached != null) {
        final decoded = json.decode(cached) as Map<String, dynamic>;
        return {
          'short': decoded['short'] as String,
          'detailed': decoded['detailed'] as String,
        };
      }
    } catch (e) {
      debugPrint('Error loading cached summary: $e');
    }
    return null;
  }

  Future<void> _cacheSummary(String key, Map<String, String> summaries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, json.encode(summaries));
    } catch (e) {
      debugPrint('Error caching summary: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchRepositories({
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cached = await _getCachedRepos();
        if (cached != null) return cached;
      }

      final response = await http
          .get(
            Uri.parse(
                '$_baseUrl/users/$username/repos?sort=updated&per_page=100'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> repos = json.decode(response.body);
        final reposData = repos.cast<Map<String, dynamic>>();
        await _cacheRepos(reposData);
        return reposData;
      } else if (response.statusCode == 403) {
        final cached = await _getCachedRepos();
        if (cached != null) return cached;
        throw Exception(
            'Rate limit exceeded. Try again later or add GitHub token.');
      } else if (response.statusCode == 404) {
        throw Exception('GitHub user "$username" not found');
      } else {
        throw Exception('Failed to load repositories (${response.statusCode})');
      }
    } catch (e) {
      final cached = await _getCachedRepos();
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchFilteredRepositoriesFast({
    bool forceRefresh = false,
    Function(String)? onProgress,
    int batchSize = 3,
  }) async {
    try {
      if (!forceRefresh) {
        final cached = await _getCachedFilteredRepos();
        if (cached != null) {
          onProgress?.call('Loaded from cache');
          return cached;
        }
      }

      onProgress?.call('Fetching repositories...');
      final repos = await fetchRepositories(forceRefresh: forceRefresh);

      final eligibleRepos = repos.where((repo) {
        final repoName = repo['name'] as String;
        final description = repo['description'] as String?;
        final isPriority = _isPriorityProject(repoName);
        final isLearning = _isLearningRepository(repoName, description);
        return !isLearning || isPriority;
      }).toList();

      onProgress?.call('Processing ${eligibleRepos.length} repositories...');

      final filtered = <Map<String, dynamic>>[];
      final priorityRepos = <Map<String, dynamic>>[];

      for (int i = 0; i < eligibleRepos.length; i += batchSize) {
        final batch = eligibleRepos.skip(i).take(batchSize).toList();

        onProgress?.call(
            'Processing batch ${(i ~/ batchSize) + 1} of ${(eligibleRepos.length / batchSize).ceil()}');

        final results = await Future.wait(
          batch.map((repo) => _processRepository(repo)),
        );

        for (final result in results) {
          if (result != null) {
            if (result['is_priority'] == true) {
              priorityRepos.add(result);
            } else {
              filtered.add(result);
            }
          }
        }

        if (i + batchSize < eligibleRepos.length) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      filtered.sort((a, b) {
        final scoreA = a['project_score'] as int;
        final scoreB = b['project_score'] as int;
        return scoreB.compareTo(scoreA);
      });

      final finalList = [...priorityRepos, ...filtered];

      onProgress?.call('Caching results...');
      await _cacheFilteredRepos(finalList);

      onProgress?.call('Complete! Loaded ${finalList.length} projects');
      return finalList;
    } catch (e) {
      final cached = await _getCachedFilteredRepos();
      if (cached != null) {
        onProgress?.call('Using cached data due to error');
        return cached;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _processRepository(
      Map<String, dynamic> repo) async {
    try {
      final repoName = repo['name'] as String;
      final isPriority = _isPriorityProject(repoName);

      final readme = await fetchReadme(repoName);

      if (readme != null || isPriority) {
        final score = readme != null
            ? _calculateProjectScore(repo, readme)
            : {'total_score': 0};

        if (isPriority || (score['total_score'] as int) >= 15) {
          final summaries = await _generateSummaries(
            repoName,
            readme ?? '',
            repo,
          );

          final repoWithReadme = Map<String, dynamic>.from(repo);
          repoWithReadme['project_score'] =
              isPriority ? 100 : score['total_score'];
          repoWithReadme['score_breakdown'] = score;
          repoWithReadme['is_priority'] = isPriority;
          repoWithReadme['display_title'] = _generateProjectTitle(repoName);
          repoWithReadme['short_summary'] = summaries['short']!;
          repoWithReadme['detailed_summary'] = summaries['detailed']!;

          return repoWithReadme;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error processing repo ${repo['name']}: $e');
      return null;
    }
  }

  Future<String?> fetchReadme(String repoName) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/repos/$username/$repoName/readme'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['content'] as String;
        return utf8.decode(base64.decode(content.replaceAll('\n', '')));
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching README for $repoName: $e');
      return null;
    }
  }

  Map<String, dynamic> _calculateProjectScore(
      Map<String, dynamic> repo, String readme) {
    int score = 0;
    final breakdown = <String, int>{};
    final lowercaseReadme = readme.toLowerCase();
    final description = (repo['description'] as String? ?? '').toLowerCase();

    if (readme.length >= 5000) {
      score += 15;
      breakdown['length'] = 15;
    } else if (readme.length >= 3000) {
      score += 10;
      breakdown['length'] = 10;
    } else if (readme.length >= 2000) {
      score += 7;
      breakdown['length'] = 7;
    } else if (readme.length >= 1000) {
      score += 3;
      breakdown['length'] = 3;
    }

    final imageCount =
        '!['.allMatches(readme).length + '<img'.allMatches(readme).length;
    if (imageCount >= 5) {
      score += 10;
      breakdown['images'] = 10;
    } else if (imageCount >= 3) {
      score += 7;
      breakdown['images'] = 7;
    } else if (imageCount >= 1) {
      score += 4;
      breakdown['images'] = 4;
    }

    final headingCount = '##'.allMatches(readme).length +
        RegExp(r'^# ', multiLine: true).allMatches(readme).length;
    if (headingCount >= 8) {
      score += 8;
      breakdown['structure'] = 8;
    } else if (headingCount >= 6) {
      score += 6;
      breakdown['structure'] = 6;
    } else if (headingCount >= 4) {
      score += 4;
      breakdown['structure'] = 4;
    }

    final codeBlockCount = '```'.allMatches(readme).length ~/ 2;
    if (codeBlockCount >= 4) {
      score += 6;
      breakdown['code_examples'] = 6;
    } else if (codeBlockCount >= 2) {
      score += 4;
      breakdown['code_examples'] = 4;
    } else if (codeBlockCount >= 1) {
      score += 2;
      breakdown['code_examples'] = 2;
    }

    final qualityKeywords = {
      'features': 3,
      'demo': 2,
      'screenshots': 2,
      'installation': 2,
      'getting started': 2,
      'architecture': 3,
      'technologies': 2,
      'built with': 2,
    };

    int qualityScore = 0;
    for (var entry in qualityKeywords.entries) {
      if (lowercaseReadme.contains(entry.key)) {
        qualityScore += entry.value;
      }
    }
    score += qualityScore > 12 ? 12 : qualityScore;
    breakdown['documentation'] = qualityScore > 12 ? 12 : qualityScore;

    int maturityScore = 0;
    if (description.isNotEmpty && description.length > 20) {
      maturityScore += 2;
    }

    final updatedAt = DateTime.tryParse(repo['updated_at'] as String? ?? '');
    if (updatedAt != null) {
      final daysSinceUpdate = DateTime.now().difference(updatedAt).inDays;
      if (daysSinceUpdate < 180) maturityScore += 2;
    }

    score += maturityScore;
    breakdown['maturity'] = maturityScore;
    breakdown['total_score'] = score;

    return breakdown;
  }

  Future<void> _cacheRepos(List<Map<String, dynamic>> repos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKeyRepos, json.encode(repos));
      await prefs.setInt(
          _cacheKeyTimestamp, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Cache error: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> _getCachedRepos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampMs = prefs.getInt(_cacheKeyTimestamp);

      if (timestampMs == null) return null;

      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestampMs;
      if (cacheAge > _cacheDuration.inMilliseconds) return null;

      final cached = prefs.getString(_cacheKeyRepos);
      if (cached == null) return null;

      final List<dynamic> decoded = json.decode(cached);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheFilteredRepos(List<Map<String, dynamic>> repos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKeyFilteredRepos, json.encode(repos));
      await prefs.setInt(
          _cacheKeyFilteredTimestamp, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Cache error: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> _getCachedFilteredRepos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampMs = prefs.getInt(_cacheKeyFilteredTimestamp);

      if (timestampMs == null) return null;

      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestampMs;
      if (cacheAge > _cacheDuration.inMilliseconds) return null;

      final cached = prefs.getString(_cacheKeyFilteredRepos);
      if (cached == null) return null;

      final List<dynamic> decoded = json.decode(cached);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKeyRepos);
      await prefs.remove(_cacheKeyTimestamp);
      await prefs.remove(_cacheKeyFilteredRepos);
      await prefs.remove(_cacheKeyFilteredTimestamp);
    } catch (e) {
      debugPrint('Clear cache error: $e');
    }
  }
}
