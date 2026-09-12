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

  // Base CV content matching your verified PDF resume
  static const String _professionalSummary =
      '''Flutter Developer with hands-on experience building a full healthtech product end-to-end. As Founding Engineer at VisionOptoCare, I own the entire Flutter codebase (web, iOS, Android) for a platform that digitizes eye testing via smartphone for clinics and everyday users, currently in clinical trials ahead of launch, aiming to turn a slow, equipment-heavy process into something fast and accessible. I'm driven by real-world problems: I built an automated expense tracker after getting frustrated with manual entry, and a self-updating portfolio because I didn't want to maintain one by hand. I use AI-assisted tools like Antigravity and Cursor to move faster without cutting corners on code quality. Looking to join a product-focused team where I can keep solving practical problems and grow under experienced senior Flutter developers.''';

  static const Map<String, List<String>> _skills = {
    'Programming Languages': ['Dart', 'C', 'C++', 'SQL'],
    'Libraries and Frameworks': [
      'Flutter',
      'REST APIs',
      'HTTP',
      'Dio',
      'Provider',
      'SQLite',
      'SharedPreferences',
      'Video SDKs'
    ],
    'Cloud & Backend': [
      'Firebase',
      'Amazon Web Services (AWS)',
      'Firestore',
      'Cloud Storage'
    ],
    'Dev Tools': [
      'Antigravity',
      'Cursor',
      'AI-Assisted Development',
      'Git',
      'VS Code',
      'Android Studio',
      'Swagger',
      'Android SDK'
    ],
    'Domain': [
      'Health Tech',
      'Full-Stack Product Development',
      'R&D',
      'Healthcare Data Compliance'
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

  static const List<Map<String, dynamic>> _experiences = [
    {
      'company': 'VisionOptoCare',
      'title': 'Flutter Developer – Founding Engineer',
      'location': 'Mumbai, Maharashtra\n(On-site)',
      'duration': 'December 2025 – Present',
      'highlights': [
        'Sole developer building the complete Flutter product (web, iOS, Android, desktop from a single codebase) to digitize eye testing using a smartphone, designed for both clinics and individual users; currently pre-launch and undergoing clinical trials',
        'Own the full development lifecycle end-to-end: research, prototyping, implementation, and testing, with no other engineers on the team',
        'Built automated diagnostic and report-generation systems that process clinical test data into structured, shareable reports',
        'Designed and integrated APIs for video-based remote eye consultations, built to extend access to underserved users once launched',
        'Implemented healthcare data security practices in line with compliance requirements',
        'Translated clinical and medical requirements from doctors into working technical features',
        'Built and maintain the company website (visionoptocare.com) introducing the product and company',
        'Tech stack: Flutter, Dart, REST APIs, Video SDKs, Firebase, AWS, Git',
      ],
    },
    {
      'company': 'Luminar Technolab',
      'title': 'Flutter Developer Trainee',
      'location': 'Kochi, Kerala',
      'duration': 'June 2025 – December 2025',
      'highlights': [
        'Built Flutter mobile apps with a focus on clean UI design and smooth performance',
        'Wrote maintainable code following best practices while collaborating with a team',
        'Gained experience with state management patterns like Provider and REST API integration using Http and Dio',
      ],
    },
  ];

  static const List<Map<String, dynamic>> _baseProjects = [
    {
      'title': 'Buddy – Auto Expense Tracker with Notification Reading',
      'url': 'github.com/FaysArukattil/buddy',
      'highlights': [
        'Built an expense tracker that automatically reads transaction SMS and UPI notifications to add expenses without manual entry',
        'Runs a background listener service with regex-based parsing to extract amount, sender, UPI ID and timestamp',
        'Implemented duplicate prevention using notification hashing and time-window checks',
        'Added analytics with daily, weekly, monthly charts using FL Chart',
        'Used SQLite for offline storage and added PDF export for summaries',
        'Tech stack: Flutter, Dart, SQLite, Background Services, FL Chart',
      ],
      'is_base': true,
    },
    {
      'title':
          'AI-Powered Self-Updating Portfolio (GitHub + Gemini API Integration)',
      'url': 'faysarukattil.github.io',
      'highlights': [
        'Automatically fetches repositories using GitHub API and generates summaries via Google Gemini',
        'Firestore-based secure token storage ensures no API keys ever appear in code',
        'Intelligent scoring filters hide practice repos and highlight high-quality ones',
        'Dynamic project cards update instantly when new repos are pushed to GitHub',
        'Clean, responsive UI with smooth animations and organized sections',
        'Tech stack: Flutter Web, Firebase, GitHub API, Google Generative AI',
      ],
      'is_base': true,
    },
    {
      'title': 'Instagram Clone',
      'url': 'github.com/FaysArukattil/instagram',
      'highlights': [
        'Replicated core features: Feed, Reels, Search, Chat, Stories and Profile',
        'Added auto-play reels, pinch-to-zoom images, and smooth video interactions',
        'Camera + gallery support for creating and sharing posts, reels, and stories',
        'Local persistence using SharedPreferences for likes, posts, comments, and user data',
        'Real-time chat UI with message status and explore page with staggered grid',
        'Tech stack: Flutter, Dart, Video Player, Camera, SharedPreferences',
      ],
      'is_base': true,
    },
  ];

  static const Map<String, dynamic> _education = {
    'degree': 'B.Tech',
    'institution': 'MES College of Engineering, Kuttippuram',
    'duration': 'June 2021 – April 2025',
    'highlights': [
      'Studied core CS subjects like Data Structures, Algorithms, OOPS, DBMS, and Software Engineering',
      'Served as Class Representative for four consecutive years throughout college',
      'Participated in technical workshops and coding competitions throughout college',
    ],
  };

  static const List<String> _certifications = [
    'Flutter Development Training – Luminar Technolab, Kochi (Completed, December 2025)',
    'B.Tech in Computer Science and Engineering – MES College of Engineering, Kuttippuram (2025)',
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

  /// Build projects list matching verified resume
  List<Map<String, dynamic>> _buildProjectsList(
      List<Map<String, dynamic>> githubProjects) {
    return _baseProjects;
  }

  pw.Widget _buildHeader() {
    return pw.Column(
      children: [
        pw.Align(
          alignment: pw.Alignment.topRight,
          child: pw.Text(
            'Last updated in September 2026',
            style: pw.TextStyle(
              fontSize: 8,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey700,
              font: _cachedItalicFont,
            ),
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'FAYS ARUKATTIL',
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
            font: _cachedBoldFont,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Wrap(
          alignment: pw.WrapAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildHeaderItem('Mumbai, Maharashtra'),
            _buildHeaderItem(
                'faysarukattil@gmail.com', 'mailto:faysarukattil@gmail.com'),
            _buildHeaderItem('+91-9605174832', 'tel:+919605174832'),
            _buildHeaderItem('faysarukattil.github.io',
                'https://faysarukattil.github.io/FaysArukattil_Portfolio/'),
            _buildHeaderItem(
                'in FaysArukattil', 'https://linkedin.com/in/faysarukattil'),
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
      children: _experiences.asMap().entries.map((entry) {
        final index = entry.key;
        final exp = entry.value;

        return pw.Padding(
          padding: pw.EdgeInsets.only(
            bottom: index < _experiences.length - 1 ? 8 : 0,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.RichText(
                      text: pw.TextSpan(
                        children: [
                          pw.TextSpan(
                            text: '${exp['company']}, ',
                            style: pw.TextStyle(
                              fontSize: 10.5,
                              fontWeight: pw.FontWeight.bold,
                              font: _cachedBoldFont,
                            ),
                          ),
                          pw.TextSpan(
                            text: exp['title'] as String,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontStyle: pw.FontStyle.italic,
                              font: _cachedItalicFont,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    '${exp['location']}\n${exp['duration']}',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      font: _cachedRegularFont,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ],
              ),
              pw.SizedBox(height: 3),
              ...(exp['highlights'] as List<String>)
                  .map((h) => _buildBulletPoint(_cleanText(h))),
            ],
          ),
        );
      }).toList(),
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
          color: const PdfColor.fromInt(0xFF999999),
          fontStyle: pw.FontStyle.italic,
          font: _cachedItalicFont,
        ),
      ),
    );
  }
}
