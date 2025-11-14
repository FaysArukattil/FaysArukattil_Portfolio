import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ResumeGeneratorService {
  static const primaryColor = PdfColor.fromInt(0xFF004F90);
  static const accentColor = PdfColor.fromInt(0xFFDA8B26);

  // Cache for fonts
  static pw.Font? _cachedRegularFont;
  static pw.Font? _cachedBoldFont;
  static pw.Font? _cachedItalicFont;

  // FIXED: Base CV content matching your LaTeX exactly
  static const String _professionalSummary =
      '''Flutter Developer and Computer Science graduate who enjoys solving real problems through code. Currently working as a Flutter trainee at Luminar Technolab, Kochi, where I'm developing Flutter applications and learning industry practices. I got frustrated manually adding my expenses in an expense tracker app, so I built an automated expense tracker that reads and add transaction from notifications automatically. I have also Created a fully Working Clone of Instagram. I also created a portfolio website so that I don't have to manually add new projects anymore and projects are fetched directly from GitHub and Sharing only my best and most polished work, presented in a simple yet impactful card-style format. I'am Always looking for ways to turn annoying real world problems into useful apps.''';

  static const Map<String, List<String>> _skills = {
    'Programming Languages': ['Dart', 'C', 'C++', 'SQL'],
    'Libraries and Frameworks': [
      'Flutter',
      'REST APIs',
      'HTTP',
      'Dio',
      'Provider',
      'SQLite',
      'SharedPreferences'
    ],
    'Version Control': ['Git'],
    'Tools and Operating Systems': [
      'VS Code',
      'Android Studio',
      'Windows',
      'Swagger',
      'Android SDK'
    ],
    'Soft Skills': [
      'Leadership',
      'Problem Solving',
      'Team Collaboration',
      'Communication',
      'Quick Learning',
      'Teaching'
    ],
    'Languages': [
      'English (Fluent)',
      'Malayalam (Native)',
      'Hindi (Conversational)',
      'Tamil (Conversational)'
    ],
  };

  static const Map<String, dynamic> _experience = {
    'title': 'Flutter Developer Trainee',
    'company': 'Luminar Technolab',
    'location': 'Kochi, Kerala',
    'duration': 'June 2025 -- Present',
    'highlights': [
      'Working on Flutter mobile apps with focus on clean UI design and smooth performance',
      'Writing maintainable code following best practices while collaborating with team',
      'Gaining experience with state management patterns like Provider and learning REST API integration with Http and Dio',
    ],
  };

  // FIXED: Pre-written project descriptions matching your LaTeX exactly
  static const List<Map<String, dynamic>> _baseProjects = [
    {
      'title': 'Buddy - Expense Tracker App',
      'url': 'github.com/FaysArukattil/buddy',
      'highlights': [
        'Built an expense tracker that automatically reads transaction SMS and UPI notifications to add expenses without manual entry',
        'Created a background service that keeps running even when the app is closed, using regex patterns to extract transaction details',
        'Added duplicate detection by comparing notification hashes so the same transaction doesn\'t get added twice',
        'Designed analytics screens showing daily, weekly, monthly stats with interactive charts using FL Chart library',
        'Used SQLite for local storage and added PDF export feature to generate transaction reports',
        'Tech stack: Flutter, Dart, SQLite, Notification Listener Service, FL Chart',
      ],
      'is_base': true,
    },
    {
      'title': 'Instagram Clone',
      'url': 'github.com/FaysArukattil/instagram',
      'highlights': [
        'Recreated Instagram\'s core features including feed, reels, messenger, search, and profile pages',
        'Implemented video playback for reels with auto-play when visible, plus pinch-to-zoom for photos',
        'Built camera and gallery integration for users to create and share posts, stories, and reels',
        'Set up local data storage using SharedPreferences to save posts, comments, likes, and user interactions',
        'Created an explore page with staggered grid layout and working chat system with message status',
        'Tech stack: Flutter, Dart, Video Player, Camera, Image Picker, SharedPreferences, Photo View',
      ],
      'is_base': true,
    },
  ];

  static const Map<String, dynamic> _education = {
    'degree': 'B.Tech',
    'institution': 'MES College of Engineering, Kuttippuram',
    'duration': 'June 2021 -- April 2025',
    'highlights': [
      'Studied core CS subjects like Data Structures, Algorithms, OOPS, DBMS, and Software Engineering',
      'Served as Class Representative for Consecutive 4 Years throughout college',
      'Participated in technical workshops and coding competitions throughout college',
    ],
  };

  static const List<String> _certifications = [
    'Flutter Development Training -- Luminar Technolab, Kochi (Ongoing)',
    'B.Tech in Computer Science and Engineering -- MES College of Engineering, Kuttippuram (2025)',
  ];

  // Load fonts once and cache them
  Future<void> _ensureFontsLoaded() async {
    if (_cachedRegularFont == null) {
      _cachedRegularFont = await PdfGoogleFonts.robotoRegular();
      _cachedBoldFont = await PdfGoogleFonts.robotoBold();
      _cachedItalicFont = await PdfGoogleFonts.robotoItalic();
    }
  }

  // Clean text to remove emojis and special Unicode characters
  String _cleanText(String text) {
    String cleaned = text
        .replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{2600}-\u{26FF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{2700}-\u{27BF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\uFE00-\uFE0F]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{1F900}-\u{1F9FF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{2190}-\u{21FF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{2300}-\u{23FF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{25A0}-\u{25FF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{2B00}-\u{2BFF}]', unicode: true), '')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll(''', "'")
        .replaceAll(''', "'")
        .replaceAll('"', '"')
        .replaceAll('"', '"')
        .replaceAll('…', '...')
        .trim();

    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    return cleaned;
  }

  Future<Uint8List> generateResumePDF(
      List<Map<String, dynamic>> githubProjects) async {
    await _ensureFontsLoaded();

    final pdf = pw.Document();

    // FIXED: Combine base projects with dynamic projects
    final allProjects = _buildProjectsList(githubProjects);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(2 * PdfPageFormat.cm),
        theme: pw.ThemeData.withFont(
          base: _cachedRegularFont,
          bold: _cachedBoldFont,
          italic: _cachedItalicFont,
        ),
        build: (context) => [
          _buildHeader(),
          pw.SizedBox(height: 12),
          _buildSection('Professional Summary', _buildSummary()),
          pw.SizedBox(height: 12),
          _buildSection('Skills', _buildSkills()),
          pw.SizedBox(height: 12),
          _buildSection('Experience', _buildExperience()),
          pw.SizedBox(height: 12),
          _buildSection('Projects', _buildProjects(allProjects)),
          pw.SizedBox(height: 12),
          _buildSection('Education', _buildEducation()),
          pw.SizedBox(height: 12),
          _buildSection('Certifications', _buildCertifications()),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );

    return pdf.save();
  }

  /// FIXED: Build projects list with base projects + dynamic portfolio + new projects
  List<Map<String, dynamic>> _buildProjectsList(
      List<Map<String, dynamic>> githubProjects) {
    final result = <Map<String, dynamic>>[];

    // 1. Add base projects first (Buddy and Instagram)
    result.addAll(_baseProjects);

    // 2. Add portfolio project dynamically
    final portfolioProject = _findPortfolioProject(githubProjects);
    if (portfolioProject != null) {
      result.add(portfolioProject);
    }

    // 3. Add other new dynamic projects (excluding base ones and portfolio)
    final newProjects = _getNewDynamicProjects(githubProjects);
    result.addAll(newProjects);

    return result;
  }

  /// Find portfolio project from GitHub
  Map<String, dynamic>? _findPortfolioProject(
      List<Map<String, dynamic>> githubProjects) {
    for (final project in githubProjects) {
      final projectName = (project['name'] as String).toLowerCase();
      if (projectName.contains('portfolio') ||
          projectName.contains('faysarukattil')) {
        return _extractProjectData(project);
      }
    }
    return null;
  }

  /// Get new projects that aren't in base list
  List<Map<String, dynamic>> _getNewDynamicProjects(
      List<Map<String, dynamic>> githubProjects) {
    final newProjects = <Map<String, dynamic>>[];
    final baseProjectNames = [
      'buddy',
      'instagram',
      'portfolio',
      'faysarukattil'
    ];

    for (final project in githubProjects) {
      final projectName = (project['name'] as String).toLowerCase();

      // Skip if it's a base project or portfolio
      if (baseProjectNames.any(
          (base) => projectName.contains(base) || base.contains(projectName))) {
        continue;
      }

      final processed = _extractProjectData(project);
      if (processed != null) {
        newProjects.add(processed);
      }

      // Limit total new projects to keep resume length reasonable
      if (newProjects.length >= 2) break;
    }

    return newProjects;
  }

  /// Extract project data from GitHub project
  Map<String, dynamic>? _extractProjectData(Map<String, dynamic> project) {
    try {
      final title = _cleanText(
          project['display_title'] as String? ?? project['name'] as String);

      final url = (project['html_url'] as String).replaceFirst('https://', '');

      final detailedSummary =
          _cleanText(project['detailed_summary'] as String? ?? '');

      final highlights = _extractHighlights(
        detailedSummary: detailedSummary,
        projectName: title,
        shortSummary: _cleanText(project['short_summary'] as String? ?? ''),
      );

      if (highlights.isEmpty) {
        return null;
      }

      return {
        'title': title,
        'url': url,
        'highlights': highlights,
        'is_base': false,
      };
    } catch (e) {
      return null;
    }
  }

  /// Extract highlights from project descriptions
  List<String> _extractHighlights({
    required String detailedSummary,
    required String projectName,
    required String shortSummary,
  }) {
    final highlights = <String>[];

    if (detailedSummary.isNotEmpty) {
      final lines = detailedSummary.split('\n');

      for (var line in lines) {
        final trimmed = _cleanText(line.trim());

        if (trimmed.isEmpty || trimmed.length < 30) continue;

        if (trimmed.startsWith('-') ||
            trimmed.startsWith('*') ||
            RegExp(r'^\d+\.').hasMatch(trimmed)) {
          var cleaned = trimmed.replaceAll(RegExp(r'^[-*\d\.]+\s*'), '').trim();

          if (cleaned.isNotEmpty && cleaned.length > 25) {
            if (cleaned[0] == cleaned[0].toLowerCase()) {
              cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
            }
            highlights.add(cleaned);
          }
        }
      }
    }

    if (highlights.length < 3 && shortSummary.isNotEmpty) {
      final sentences = shortSummary
          .split(RegExp(r'[.!?]+'))
          .where((s) => s.trim().length > 25)
          .map((s) => s.trim())
          .take(3)
          .toList();

      for (var sentence in sentences) {
        if (!highlights.any((h) => h.toLowerCase() == sentence.toLowerCase())) {
          highlights.add(sentence);
        }
      }
    }

    return highlights.take(6).toList();
  }

  pw.Widget _buildHeader() {
    return pw.Column(
      children: [
        pw.Text(
          'FAYS ARUKATTIL',
          style: pw.TextStyle(
            fontSize: 30,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
            font: _cachedBoldFont,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Wrap(
          alignment: pw.WrapAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildHeaderItem('Malappuram, Kerala'),
            _buildHeaderItem(
                'faysarukattil@gmail.com', 'mailto:faysarukattil@gmail.com'),
            _buildHeaderItem('+91-9605174832', 'tel:+919605174832'),
            _buildHeaderItem('faysarukattil.github.io',
                'https://faysarukattil.github.io/FaysArukattil_Portfolio/'),
            _buildHeaderItem(
                'FaysArukattil', 'https://linkedin.com/in/FaysArukattil'),
            _buildHeaderItem(
                'FaysArukattil', 'https://github.com/FaysArukattil'),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildHeaderItem(String text, [String? url]) {
    return pw.UrlLink(
      destination: url ?? '',
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          color: url != null ? PdfColors.blue800 : PdfColors.black,
          font: _cachedRegularFont,
        ),
      ),
    );
  }

  pw.Widget _buildSection(String title, pw.Widget content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: primaryColor, width: 0.8),
            ),
          ),
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
              font: _cachedBoldFont,
            ),
          ),
        ),
        pw.SizedBox(height: 6),
        content,
      ],
    );
  }

  pw.Widget _buildSummary() {
    return pw.Text(
      _cleanText(_professionalSummary),
      style: pw.TextStyle(
        fontSize: 10,
        lineSpacing: 1.4,
        font: _cachedRegularFont,
      ),
      textAlign: pw.TextAlign.justify,
    );
  }

  pw.Widget _buildSkills() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: _skills.entries.map((entry) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 180,
                child: pw.Text(
                  '${entry.key}:',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    font: _cachedBoldFont,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  entry.value.join(', '),
                  style: pw.TextStyle(
                    fontSize: 10,
                    font: _cachedRegularFont,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildExperience() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                '${_experience['company']}, ${_experience['title']}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  font: _cachedBoldFont,
                ),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Text(
              '${_experience['location']}\n${_experience['duration']}',
              style: pw.TextStyle(
                fontSize: 9,
                font: _cachedRegularFont,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        ...(_experience['highlights'] as List<String>)
            .map((h) => _buildBulletPoint(_cleanText(h))),
      ],
    );
  }

  pw.Widget _buildProjects(List<Map<String, dynamic>> projects) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: projects.asMap().entries.map((entry) {
        final index = entry.key;
        final project = entry.value;

        return pw.Padding(
          padding: pw.EdgeInsets.only(
            bottom: index < projects.length - 1 ? 8 : 0,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      _cleanText(project['title'] as String),
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        font: _cachedBoldFont,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    flex: 2,
                    child: pw.UrlLink(
                      destination: (project['url'] as String).startsWith('http')
                          ? project['url'] as String
                          : 'https://${project['url']}',
                      child: pw.Text(
                        project['url'] as String,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: primaryColor,
                          font: _cachedRegularFont,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              ...(project['highlights'] as List<String>)
                  .map((h) => _buildBulletPoint(_cleanText(h))),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildEducation() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                '${_education['institution']}, ${_education['degree']}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  font: _cachedBoldFont,
                ),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Text(
              _education['duration'] as String,
              style: pw.TextStyle(
                fontSize: 9,
                font: _cachedRegularFont,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        ...(_education['highlights'] as List<String>)
            .map((h) => _buildBulletPoint(_cleanText(h))),
      ],
    );
  }

  pw.Widget _buildCertifications() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: _certifications.map((cert) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Text(
            _cleanText(cert),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              font: _cachedBoldFont,
            ),
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildBulletPoint(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 12, bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 8,
            child: pw.Text(
              '•',
              style: pw.TextStyle(
                fontSize: 10,
                font: _cachedRegularFont,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: 10,
                lineSpacing: 1.3,
                font: _cachedRegularFont,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Fays Arukattil - Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(
          fontSize: 8,
          color: PdfColor.fromInt(0xFF999999),
          fontStyle: pw.FontStyle.italic,
          font: _cachedItalicFont,
        ),
      ),
    );
  }
}
