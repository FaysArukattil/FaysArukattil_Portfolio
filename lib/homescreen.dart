// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:my_portfolio/config/app_config.dart';
import 'package:my_portfolio/services/github_service.dart';
import 'package:my_portfolio/services/resumegeneration.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_saver/file_saver.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../widgets/projects_section.dart';

//hi
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // ignore: unused_field
  bool _projectsPreloaded = false;

  final _scrollController = ScrollController();
  final _sectionKeys = List.generate(4, (_) => GlobalKey());
  late AnimationController _fadeController, _nameController, _imageController;
  late Animation<double> _nameSlide, _nameOpacity, _imageScale, _imageOpacity;

  int _currentSection = 0;
  int? _hoveredSkill,
      _hoveredContact,
      _hoveredButton,
      _hoveredChip,
      _hoveredRestAPI,
      _hoveredNavItem;
  bool _heroVisible = false,
      _skillsVisible = false,
      _projectsVisible = false,
      _contactVisible = false;
  bool _isDesktop = false;
  bool _isDownloading = false;

  // NEW: Cache for PDF bytes and projects
  Uint8List? _cachedPdfBytes;
  List<Map<String, dynamic>>? _cachedProjects;
  static const String _pdfCacheKey = 'cached_resume_pdf';
  static const String _projectsCacheKey = 'cached_resume_projects';

  @override
  @override
  @override
  void initState() {
    super.initState();

    // Initialize animations IMMEDIATELY (required for first paint)
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();

    _nameController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _nameSlide = Tween<double>(begin: -50, end: 0).animate(
        CurvedAnimation(parent: _nameController, curve: Curves.easeOut));

    _nameOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _nameController, curve: Curves.easeIn));

    _imageController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    _imageScale = Tween<double>(begin: 0.7, end: 1).animate(
        CurvedAnimation(parent: _imageController, curve: Curves.easeOut));

    _imageOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _imageController, curve: Curves.easeIn));

    _scrollController.addListener(_handleScroll);

    // Start hero animations immediately
    _nameController.forward();
    _imageController.forward();
    setState(() => _heroVisible = true);

    // DEFER ALL HEAVY OPERATIONS until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load cached data immediately (fast operation)
      _loadCachedResume();

      // REMOVED: No more EnvLoaderService calls
      // AppConfig is already initialized in main.dart

      // Preload projects in background
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _preloadProjectsInBackground();
        }
      });
    });
  }

  // NEW: Load cached PDF from SharedPreferences
  Future<void> _loadCachedResume() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final pdfBase64 = prefs.getString(_pdfCacheKey);
      if (pdfBase64 != null) {
        _cachedPdfBytes = base64Decode(pdfBase64);
        debugPrint('✅ Loaded cached PDF');
      }

      final projectsJson = prefs.getString(_projectsCacheKey);
      if (projectsJson != null) {
        final List<dynamic> decoded = json.decode(projectsJson);
        _cachedProjects = decoded.cast<Map<String, dynamic>>();
        debugPrint('✅ Loaded cached projects (${_cachedProjects!.length})');
      }

      // Generate PDF silently in background if needed
      if (_cachedProjects != null && _cachedPdfBytes == null) {
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            _generateAndCacheResume(_cachedProjects!, silent: true);
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading cache: $e');
    }
  }

  // NEW: Generate PDF and cache it
  Future<void> _generateAndCacheResume(
    List<Map<String, dynamic>> projects, {
    bool silent = false,
  }) async {
    try {
      final resumeService = ResumeGeneratorService();
      final pdfBytes = await resumeService.generateResumePDF(projects);

      // Cache the PDF bytes and projects
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pdfCacheKey, base64Encode(pdfBytes));
      await prefs.setString(_projectsCacheKey, json.encode(projects));

      if (mounted) {
        setState(() {
          _cachedPdfBytes = pdfBytes;
          _cachedProjects = projects;
        });
      }

      if (!silent) {
        debugPrint('Resume cached successfully');
      }
    } catch (e) {
      debugPrint('Error generating resume: $e');
    }
  }

  void _preloadProjectsInBackground() async {
    try {
      final githubService = GitHubService('FaysArukattil');

      debugPrint('📡 Fetching projects in background...');

      githubService
          .fetchFilteredRepositoriesFast(forceRefresh: false)
          .timeout(const Duration(seconds: 15))
          .then((projects) {
        if (mounted) {
          setState(() => _projectsPreloaded = true);
          debugPrint('✅ Projects preloaded (${projects.length})');

          if (_shouldRegenerateResume(projects)) {
            // Defer PDF generation to avoid blocking
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                debugPrint('🔄 Regenerating resume...');
                _generateAndCacheResume(projects, silent: true);
              }
            });
          }
        }
      }).catchError((e) {
        debugPrint('❌ Error preloading projects: $e');
        if (mounted) setState(() => _projectsPreloaded = true);
      });
    } catch (e) {
      debugPrint('❌ Background preload error: $e');
      if (mounted) setState(() => _projectsPreloaded = true);
    }
  }

  // NEW: Check if resume needs regeneration
  bool _shouldRegenerateResume(List<Map<String, dynamic>> newProjects) {
    if (_cachedProjects == null) return true;
    if (_cachedProjects!.length != newProjects.length) return true;

    // Compare project names
    for (int i = 0;
        i < newProjects.length && i < _cachedProjects!.length;
        i++) {
      if (newProjects[i]['name'] != _cachedProjects![i]['name']) {
        return true;
      }
    }

    return false;
  }

  // NEW: Callback from ProjectsSection when projects refresh
  void _onProjectsRefreshed(List<Map<String, dynamic>> projects) {
    debugPrint('Projects refreshed, regenerating resume...');
    _generateAndCacheResume(projects);
  }

  void _handleScroll() {
    if (!mounted) return;

    final h = MediaQuery.of(context).size.height;
    final s = _scrollController.offset;

    int newSection = 0;
    if (s > h * 2.5) {
      newSection = 3;
    } else if (s > h * 1.5) {
      newSection = 2;
    } else if (s > h * 0.5) {
      newSection = 1;
    }

    if (newSection != _currentSection) {
      setState(() => _currentSection = newSection);
    }

    final shouldShowSkills = s > h * 0.2 && s < h * 1.8;
    if (shouldShowSkills != _skillsVisible) {
      setState(() => _skillsVisible = shouldShowSkills);
    }

    final shouldShowProjects = s > h * 1.0 && s < h * 2.8;
    if (shouldShowProjects != _projectsVisible) {
      setState(() => _projectsVisible = shouldShowProjects);
    }

    final shouldShowContact = s > h * 2.0;
    if (shouldShowContact != _contactVisible) {
      setState(() => _contactVisible = shouldShowContact);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _imageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(int i) {
    setState(() => _currentSection = i);
    final ctx = _sectionKeys[i].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 700), curve: Curves.easeInOut);
    }
  }

  Widget _buildGeneratingAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulsing ring
            Container(
              width: 140 + (20 * value),
              height: 140 + (20 * value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFDA8B26)
                      .withValues(alpha: 0.3 * (1 - value)),
                  width: 2,
                ),
              ),
            ),
            // Rotating progress ring
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                backgroundColor:
                    const Color(0xFFDA8B26).withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.lerp(
                    const Color(0xFFDA8B26),
                    const Color(0xFFFFC107),
                    value,
                  )!,
                ),
              ),
            ),
            // Center icon with gradient background
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFDA8B26).withValues(alpha: 0.3),
                    const Color(0xFFFFC107).withValues(alpha: 0.2),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDA8B26).withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.description_outlined,
                size: 40,
                color: Color.lerp(
                  const Color(0xFFDA8B26),
                  const Color(0xFFFFC107),
                  value,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReadyAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  const Color(0xFF45a049).withValues(alpha: 0.2),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 60,
              color: const Color(0xFF4CAF50),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressSteps() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 2000),
      builder: (context, value, child) {
        final steps = [
          'Fetching projects',
          'Analyzing data',
          'Formatting content',
          'Generating PDF'
        ];
        final currentStep = (value * steps.length).floor();

        return Column(
          children: [
            // Progress bar
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFDA8B26).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDA8B26), Color(0xFFFFC107)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDA8B26).withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Current step text
            if (currentStep < steps.length)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFDA8B26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    steps[currentStep],
                    style: TextStyle(
                      color: const Color(0xFFDA8B26),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Future<void> _downloadResume() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      Uint8List pdfBytes;

      // Use cached PDF if available, otherwise generate new one
      if (_cachedPdfBytes != null) {
        _showDownloadOverlay(useCache: true);
        pdfBytes = _cachedPdfBytes!;

        // Small delay to show the overlay
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        _showDownloadOverlay(useCache: false);

        // Fetch latest projects and generate PDF
        final githubService = GitHubService('FaysArukattil');
        final projects = await githubService.fetchFilteredRepositoriesFast(
          forceRefresh: false,
        );

        final resumeService = ResumeGeneratorService();
        pdfBytes = await resumeService.generateResumePDF(projects);

        // Cache for next time
        await _generateAndCacheResume(projects, silent: true);
      }

      // Save PDF
      await FileSaver.instance.saveFile(
        name: 'Fays_Arukattil_Resume',
        bytes: pdfBytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );

      if (mounted) {
        Navigator.of(context).pop();
        _showSnack('✓ Resume downloaded successfully!', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showSnack('✗ Download failed: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _showDownloadOverlay({required bool useCache}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(50),
            constraints: const BoxConstraints(maxWidth: 450),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16213E),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFDA8B26).withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDA8B26).withValues(alpha: 0.3),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 80,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Icon Section
                if (!useCache)
                  _buildGeneratingAnimation()
                else
                  _buildReadyAnimation(),

                const SizedBox(height: 36),

                // Title with gradient
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFDA8B26), Color(0xFFFFC107)],
                  ).createShader(bounds),
                  child: Text(
                    useCache ? 'Resume Ready!' : 'Generating Resume',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Subtitle
                Text(
                  useCache
                      ? 'Your professional resume is ready for download'
                      : 'Please wait while we prepare your resume...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 15,
                    letterSpacing: 0.3,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (!useCache) ...[
                  const SizedBox(height: 28),
                  // Animated progress steps
                  _buildProgressSteps(),
                ],

                if (useCache) ...[
                  const SizedBox(height: 24),
                  // Success checkmark animation would go here
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: const Color(0xFF4CAF50),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Using cached version',
                        style: TextStyle(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: color == Colors.green
                        ? [const Color(0xFF4CAF50), const Color(0xFF45a049)]
                        : [Colors.red.shade400, Colors.red.shade600],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                    color == Colors.green ? Icons.check_circle : Icons.error,
                    color: Colors.white,
                    size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(msg,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3))),
            ],
          ),
          backgroundColor: const Color(0xFF1A1A2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withValues(alpha: 0.5), width: 2),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('✗ Cannot open link', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final desk = w > 1024, tab = w > 768 && w <= 1024, mob = w <= 768;
    _isDesktop = desk;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
              Color(0xFF0A0A0A),
              Color(0xFF1A1A2E),
              Color(0xFF16213E)
            ])),
        child: Column(children: [
          _navbar(desk, tab, mob),
          Expanded(
              child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: Column(children: [
                    _hero(desk, mob),
                    _skills(desk, mob),
                    _projects(desk, mob),
                    _contact(desk, mob)
                  ])))
        ]),
      ),
    );
  }

  Widget _navbar(bool desk, bool tab, bool mob) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: desk ? 80 : (tab ? 40 : 20), vertical: 16),
        decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            border: Border(
                bottom: BorderSide(
                    color: const Color(0xFFDA8B26).withValues(alpha: 0.15),
                    width: 1))),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFDA8B26), Color(0xFFFFC107)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFDA8B26).withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 1)
                  ]),
              child: const Center(
                  child: Text('FA',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1))),
            ),
            const SizedBox(width: 14),
            ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFDA8B26)]).createShader(b),
                child: const Text('Fays Arukattil',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        letterSpacing: 0.3))),
          ]),
          if (desk || tab)
            Row(
                children: ['About', 'Skills', 'Projects', 'Contact']
                    .asMap()
                    .entries
                    .map((e) => _navBtn(e.value, e.key, desk))
                    .toList())
          else
            PopupMenuButton<int>(
              icon: const Icon(Icons.menu, color: Colors.white, size: 28),
              color: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                      color: const Color(0xFFDA8B26).withValues(alpha: .3))),
              onSelected: _scrollTo,
              itemBuilder: (_) => [
                _menuItem(0, Icons.person, 'About'),
                _menuItem(1, Icons.bar_chart, 'Skills'),
                _menuItem(2, Icons.work, 'Projects'),
                _menuItem(3, Icons.mail, 'Contact')
              ],
            ),
        ]),
      );

  PopupMenuItem<int> _menuItem(int v, IconData icon, String text) =>
      PopupMenuItem(
          value: v,
          child: Row(children: [
            Icon(icon, color: const Color(0xFFDA8B26)),
            const SizedBox(width: 12),
            Text(text,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600))
          ]));

  Widget _navBtn(String label, int i, bool enableHover) {
    final sel = _currentSection == i,
        hovered = _hoveredNavItem == i && enableHover;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: MouseRegion(
        onEnter:
            enableHover ? (_) => setState(() => _hoveredNavItem = i) : null,
        onExit:
            enableHover ? (_) => setState(() => _hoveredNavItem = null) : null,
        cursor: enableHover ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTap: () => _scrollTo(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: sel
                  ? const LinearGradient(
                      colors: [Color(0xFFDA8B26), Color(0xFFFFC107)])
                  : null,
              borderRadius: BorderRadius.circular(10),
              border: sel
                  ? null
                  : Border.all(
                      color:
                          Colors.white.withValues(alpha: hovered ? 0.3 : 0.1),
                      width: hovered ? 1.5 : 1),
              boxShadow: sel
                  ? [
                      BoxShadow(
                          color: const Color(0xFFDA8B26).withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 1)
                    ]
                  : (hovered
                      ? [
                          BoxShadow(
                              color: const Color(0xFFDA8B26)
                                  .withValues(alpha: 0.2),
                              blurRadius: 15)
                        ]
                      : []),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 0.5)),
          ),
        ),
      ),
    );
  }

  Widget _hero(bool desk, bool mob) => Container(
        key: _sectionKeys[0],
        constraints: const BoxConstraints(minHeight: 700),
        padding: EdgeInsets.symmetric(
            horizontal: desk ? 120 : (mob ? 20 : 60),
            vertical: desk ? 100 : 60),
        child: AnimatedOpacity(
          opacity: _heroVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          child: desk
              ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(flex: 3, child: _heroContent(desk, mob)),
                  const SizedBox(width: 72),
                  Expanded(flex: 2, child: _profileCard(desk))
                ])
              : Column(children: [
                  _profileCard(desk),
                  const SizedBox(height: 40),
                  _heroContent(desk, mob)
                ]),
        ),
      );

  Widget _profileCard(bool desk) {
    final sz = desk ? 380.0 : 280.0;
    return AnimatedBuilder(
      animation: _imageController,
      builder: (context, _) => Transform.scale(
        scale: _imageScale.value,
        child: Opacity(
          opacity: _imageOpacity.value,
          child: Stack(alignment: Alignment.center, children: [
            ...List.generate(
                2,
                (i) => Container(
                    width: sz + 40 + (i * 40),
                    height: sz + 40 + (i * 40),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFDA8B26)
                                .withValues(alpha: 0.3 - i * 0.15),
                            width: 2 - i.toDouble())))),
            Container(
              width: sz,
              height: sz,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFDA8B26), Color(0xFF1A1A2E)]),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFDA8B26).withValues(alpha: 0.5),
                        blurRadius: 60,
                        spreadRadius: 10)
                  ]),
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset('assets/images/Profile.JPG',
                          fit: BoxFit.cover))),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _heroContent(bool desk, bool mob) => Column(
        crossAxisAlignment:
            desk ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _nameController,
            builder: (context, _) => Transform.translate(
              offset: Offset(_nameSlide.value, 0),
              child: Opacity(
                opacity: _nameOpacity.value,
                child: Column(
                    crossAxisAlignment: desk
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      Text('Hello, I\'m',
                          style: TextStyle(
                              fontSize: mob ? 18 : 22,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1)),
                      const SizedBox(height: 8),
                      ShaderMask(
                          shaderCallback: (b) => const LinearGradient(colors: [
                                Color(0xFFDA8B26),
                                Color(0xFFFFC107),
                                Color(0xFFDA8B26)
                              ]).createShader(b),
                          child: Text('Fays Arukattil',
                              style: TextStyle(
                                  fontSize: mob ? 44 : (desk ? 64 : 52),
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.1,
                                  letterSpacing: -1.5))),
                      const SizedBox(height: 16),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.white.withValues(alpha: 0.1),
                                Colors.white.withValues(alpha: 0.05)
                              ]),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFDA8B26)
                                      .withValues(alpha: 0.4))),
                          child: Text("Mobile Application Developer",
                              style: TextStyle(
                                  fontSize: mob ? 16 : 20,
                                  color: const Color(0xFFDA8B26),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5))),
                    ]),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Container(
              constraints:
                  BoxConstraints(maxWidth: desk ? 550 : double.infinity),
              child: Text(
                  "Crafting seamless cross-platform experiences with Flutter. Specialized in building high-performance mobile applications with elegant UI/UX and robust architecture.",
                  textAlign: desk ? TextAlign.left : TextAlign.center,
                  style: TextStyle(
                      fontSize: mob ? 15 : 17,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.6,
                      letterSpacing: 0.3))),
          const SizedBox(height: 32),
          Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: desk ? WrapAlignment.start : WrapAlignment.center,
              children: [
                _techChip(Icons.flutter_dash, 'Flutter', 0),
                _techChip(Icons.code, 'Dart', 1),
                _techChip(Icons.api, 'REST API', 2),
                _techChip(Icons.layers, 'Provider', 3),
              ]),
          const SizedBox(height: 40),
          Wrap(spacing: 16, runSpacing: 16, children: [
            _glassButton(
                onPressed: _downloadResume,
                icon: Icons.download_rounded,
                label: 'Download Resume',
                isPrimary: true,
                index: 0),
            _glassButton(
                onPressed: () => _scrollTo(3),
                icon: Icons.mail_outline,
                label: 'Contact Me',
                isPrimary: false,
                index: 1)
          ]),
          const SizedBox(height: 32),
          Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: desk ? WrapAlignment.start : WrapAlignment.center,
              children: [
                _infoChip(Icons.location_on, 'Malappuram, Kerala', 10),
                _infoChip(Icons.school, 'B.Tech CSE', 11),
              ]),
        ],
      );

  Widget _techChip(IconData icon, String label, int index) {
    final hovered = _hoveredChip == index && _isDesktop;
    return MouseRegion(
      onEnter: _isDesktop ? (_) => setState(() => _hoveredChip = index) : null,
      onExit: _isDesktop ? (_) => setState(() => _hoveredChip = null) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:
              const Color(0xFFDA8B26).withValues(alpha: hovered ? 0.25 : 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFFDA8B26)
                  .withValues(alpha: hovered ? 0.8 : 0.5),
              width: hovered ? 2 : 1.5),
          boxShadow: hovered
              ? [
                  BoxShadow(
                      color: const Color(0xFFDA8B26).withValues(alpha: (0.4)),
                      blurRadius: 15)
                ]
              : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: const Color(0xFFDA8B26), size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13))
        ]),
      ),
    );
  }

  Widget _infoChip(IconData icon, String txt, int index) {
    final hovered = _hoveredChip == index && _isDesktop;
    return MouseRegion(
      onEnter: _isDesktop ? (_) => setState(() => _hoveredChip = index) : null,
      onExit: _isDesktop ? (_) => setState(() => _hoveredChip = null) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.white.withValues(alpha: hovered ? 0.12 : 0.08),
              Colors.white.withValues(alpha: hovered ? 0.06 : 0.04)
            ]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFFDA8B26)
                    .withValues(alpha: hovered ? 0.5 : 0.3)),
            boxShadow: hovered
                ? [
                    BoxShadow(
                        color: const Color(0xFFDA8B26).withValues(alpha: 0.2),
                        blurRadius: 15)
                  ]
                : []),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: const Color(0xFFDA8B26), size: 18),
          const SizedBox(width: 8),
          Text(txt,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14))
        ]),
      ),
    );
  }

  Widget _glassButton(
      {required VoidCallback onPressed,
      required IconData icon,
      required String label,
      required bool isPrimary,
      required int index}) {
    final hovered = _hoveredButton == index && _isDesktop;
    return MouseRegion(
      onEnter:
          _isDesktop ? (_) => setState(() => _hoveredButton = index) : null,
      onExit: _isDesktop ? (_) => setState(() => _hoveredButton = null) : null,
      cursor: _isDesktop ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
              gradient: isPrimary
                  ? const LinearGradient(
                      colors: [Color(0xFFDA8B26), Color(0xFFFFC107)])
                  : LinearGradient(colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05)
                    ]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFDA8B26), width: isPrimary ? 0 : 2),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFDA8B26).withValues(
                        alpha: hovered ? 0.5 : (isPrimary ? 0.4 : 0.2)),
                    blurRadius: hovered ? 25 : 20,
                    spreadRadius: hovered ? 3 : 2)
              ]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3))
          ]),
        ),
      ),
    );
  }

  Widget _skills(bool desk, bool mob) {
    final mainSkills = [
      {
        'name': 'Flutter',
        'icon': Icons.flutter_dash,
        'color': const Color(0xFF02569B)
      },
      {'name': 'Dart', 'icon': Icons.code, 'color': const Color(0xFF0175C2)},
      {
        'name': 'REST API',
        'icon': Icons.api,
        'color': const Color(0xFF4CAF50),
        'hasSubSkills': true
      },
      {
        'name': 'Provider',
        'icon': Icons.layers,
        'color': const Color(0xFF00BCD4)
      },
    ];
    final otherSkills = [
      {'name': 'HTML', 'icon': Icons.html, 'color': const Color(0xFFE44D26)},
      {'name': 'CSS', 'icon': Icons.css, 'color': const Color(0xFF264DE4)},
      {'name': 'Python', 'icon': Icons.code, 'color': const Color(0xFF3776AB)},
      {
        'name': 'C',
        'icon': Icons.code_rounded,
        'color': const Color(0xFFA8B9CC)
      },
      {'name': 'C++', 'icon': Icons.code_off, 'color': const Color(0xFF00599C)},
      {
        'name': 'MySQL',
        'icon': Icons.table_chart,
        'color': const Color(0xFF4479A1)
      },
      {'name': 'Hive', 'icon': Icons.widgets, 'color': const Color(0xFFFFCA28)},
      {
        'name': 'Sqflite',
        'icon': Icons.data_object,
        'color': const Color(0xFF2196F3)
      },
    ];

    return Container(
      key: _sectionKeys[1],
      padding: EdgeInsets.symmetric(
          horizontal: desk ? 120 : (mob ? 18 : 40), vertical: 100),
      child: AnimatedOpacity(
        opacity: _skillsVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 600),
        child: Column(children: [
          ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFFDA8B26), Color(0xFFFFC107)])
                  .createShader(b),
              child: const Text('Technical Expertise',
                  style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                  textAlign: TextAlign.center)),
          const SizedBox(height: 12),
          const Text('Core Technologies',
              style: TextStyle(fontSize: 18, color: Colors.white60)),
          const SizedBox(height: 50),
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: desk ? 4 : (mob ? 2 : 3),
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.1),
              itemCount: mainSkills.length,
              itemBuilder: (_, i) => _mainSkillCard(mainSkills[i], i)),
          const SizedBox(height: 40),
          const Text('Other Technologies',
              style: TextStyle(fontSize: 16, color: Colors.white60)),
          const SizedBox(height: 20),
          Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(otherSkills.length,
                  (i) => _smallSkillCard(otherSkills[i], i + 100))),
        ]),
      ),
    );
  }

  Widget _mainSkillCard(Map<String, dynamic> s, int i) {
    final hovered = _hoveredSkill == i && _isDesktop,
        hasSubSkills = s['hasSubSkills'] == true;
    return MouseRegion(
      onEnter: _isDesktop ? (_) => setState(() => _hoveredSkill = i) : null,
      onExit: _isDesktop ? (_) => setState(() => _hoveredSkill = null) : null,
      cursor: _isDesktop ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              (s['color'] as Color).withValues(alpha: hovered ? 0.25 : 0.12),
              (s['color'] as Color).withValues(alpha: hovered ? 0.1 : 0.05)
            ], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: (s['color'] as Color)
                    .withValues(alpha: hovered ? 0.9 : 0.4),
                width: hovered ? 2.5 : 1.5),
            boxShadow: [
              BoxShadow(
                  color: (s['color'] as Color)
                      .withValues(alpha: hovered ? 0.6 : 0.2),
                  blurRadius: hovered ? 40 : 20,
                  offset: Offset(0, hovered ? 15 : 8))
            ]),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 160,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(s['icon'] as IconData, size: 48, color: s['color'] as Color),
              const SizedBox(height: 12),
              Text(s['name'] as String,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                  textAlign: TextAlign.center),
              if (hasSubSkills)
                SizedBox(
                  height: 44,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: hovered ? 1.0 : 0.0,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _subSkillChip('HTTP', 0),
                          const SizedBox(width: 8),
                          _subSkillChip('DIO', 1)
                        ],
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _subSkillChip(String label, int index) {
    final hovered = _hoveredRestAPI == index && _isDesktop;
    return MouseRegion(
      onEnter:
          _isDesktop ? (_) => setState(() => _hoveredRestAPI = index) : null,
      onExit: _isDesktop ? (_) => setState(() => _hoveredRestAPI = null) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color:
                const Color(0xFF4CAF50).withValues(alpha: hovered ? 0.3 : 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: const Color(0xFF4CAF50)
                    .withValues(alpha: hovered ? 0.8 : 0.5))),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _smallSkillCard(Map<String, dynamic> s, int i) {
    final hovered = _hoveredSkill == i && _isDesktop;
    return MouseRegion(
      onEnter: _isDesktop ? (_) => setState(() => _hoveredSkill = i) : null,
      onExit: _isDesktop ? (_) => setState(() => _hoveredSkill = null) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              (s['color'] as Color).withValues(alpha: hovered ? 0.2 : 0.1),
              (s['color'] as Color).withValues(alpha: hovered ? 0.1 : 0.05)
            ]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: (s['color'] as Color)
                    .withValues(alpha: hovered ? 0.7 : 0.4),
                width: hovered ? 2 : 1),
            boxShadow: hovered
                ? [
                    BoxShadow(
                        color: (s['color'] as Color).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ]
                : []),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(s['icon'] as IconData, size: 18, color: s['color'] as Color),
          const SizedBox(width: 8),
          Text(s['name'] as String,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13))
        ]),
      ),
    );
  }

  Widget _projects(bool desk, bool mob) => ProjectsSection(
        key: _sectionKeys[2],
        githubUsername: 'FaysArukattil',
        eagerLoad: false,
        onProjectsRefreshed: _onProjectsRefreshed,
        // Use AppConfig instead of EnvLoaderService
        githubToken: AppConfig.githubToken,
        geminiApiKey: AppConfig.geminiKey,
      );

  Widget _contact(bool desk, bool mob) {
    final contacts = [
      {
        'title': 'Email',
        'sub': 'faysarukattil@gmail.com',
        'icon': Icons.email,
        'url': 'mailto:faysarukattil@gmail.com',
        'img': 'assets/images/gmail.png',
        'c1': const Color(0xFF673AB7),
        'c2': const Color(0xFF3F51B5)
      },
      {
        'title': 'WhatsApp',
        'sub': '+91 9605174832',
        'icon': Icons.chat,
        'url': 'https://wa.me/919605174832',
        'img': 'assets/images/whatsapp.png',
        'c1': const Color(0xFF25D366),
        'c2': const Color(0xFF128C7E)
      },
      {
        'title': 'LinkedIn',
        'sub': 'FAYS ARUKATTIL',
        'icon': Icons.link,
        'url': 'https://www.linkedin.com/in/faysarukattil',
        'img': 'assets/images/linkedin.png',
        'c1': const Color(0xFF0077B5),
        'c2': const Color(0xFF005582)
      },
      {
        'title': 'GitHub',
        'sub': 'FaysArukattil',
        'icon': Icons.code,
        'url': 'https://github.com/FaysArukattil',
        'img': 'assets/images/github.png',
        'c1': const Color(0xFF333333),
        'c2': const Color(0xFF6e5494)
      },
    ];

    return Container(
      key: _sectionKeys[3],
      padding: EdgeInsets.symmetric(
          horizontal: desk ? 120 : (mob ? 20 : 40), vertical: 100),
      child: AnimatedOpacity(
        opacity: _contactVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 600),
        child: Column(children: [
          ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFFDA8B26), Color(0xFFFFC107)])
                  .createShader(b),
              child: const Text('Get In Touch',
                  style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                  textAlign: TextAlign.center)),
          const SizedBox(height: 12),
          const Text("Let's work together on your next project",
              style: TextStyle(color: Colors.white60, fontSize: 18)),
          const SizedBox(height: 50),
          LayoutBuilder(
            builder: (context, constraints) {
              if (desk) {
                return Column(children: [
                  Row(children: [
                    Expanded(child: _contactCard(contacts[0], 0)),
                    const SizedBox(width: 24),
                    Expanded(child: _contactCard(contacts[1], 1))
                  ]),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(child: _contactCard(contacts[2], 2)),
                    const SizedBox(width: 24),
                    Expanded(child: _contactCard(contacts[3], 3))
                  ])
                ]);
              } else {
                return Column(
                    children: List.generate(
                        contacts.length,
                        (i) => Padding(
                            padding: EdgeInsets.only(
                                bottom: i < contacts.length - 1 ? 24 : 0),
                            child: _contactCard(contacts[i], i))));
              }
            },
          ),
          const SizedBox(height: 60),
          Container(
            padding: EdgeInsets.symmetric(
              vertical: 20,
              horizontal: MediaQuery.of(context).size.width < 600 ? 16 : 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.02)
              ]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFDA8B26).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, color: Color(0xFFDA8B26), size: 20),
                SizedBox(
                    width: MediaQuery.of(context).size.width < 600 ? 8 : 12),
                Flexible(
                  child: Text(
                    '© 2025 Fays Arukattil. Built with Flutter',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize:
                          MediaQuery.of(context).size.width < 600 ? 12 : 14,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _contactCard(Map<String, dynamic> c, int i) {
    final hovered = _hoveredContact == i && _isDesktop;
    return MouseRegion(
      onEnter: _isDesktop ? (_) => setState(() => _hoveredContact = i) : null,
      onExit: _isDesktop ? (_) => setState(() => _hoveredContact = null) : null,
      cursor: _isDesktop ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: () => _launch(c['url'] as String),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(colors: [
                (c['c1'] as Color).withValues(alpha: hovered ? 0.25 : 0.12),
                (c['c2'] as Color).withValues(alpha: hovered ? 0.2 : 0.08)
              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
              border: Border.all(
                  color:
                      (c['c1'] as Color).withValues(alpha: hovered ? 0.8 : 0.4),
                  width: hovered ? 2.5 : 1.5),
              boxShadow: [
                BoxShadow(
                    color: (c['c1'] as Color)
                        .withValues(alpha: hovered ? 0.5 : 0.2),
                    blurRadius: hovered ? 35 : 20,
                    offset: Offset(0, hovered ? 12 : 8))
              ]),
          child: Row(children: [
            AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [c['c1'] as Color, c['c2'] as Color]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: (c['c1'] as Color)
                              .withValues(alpha: hovered ? 0.6 : 0.4),
                          blurRadius: hovered ? 20 : 15,
                          spreadRadius: hovered ? 3 : 2)
                    ]),
                child:
                    Icon(c['icon'] as IconData, size: 36, color: Colors.white)),
            const SizedBox(width: 20),
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(c['title'] as String,
                      style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(c['sub'] as String,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)
                ])),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: hovered ? 110 : 0,
              height: 110,
              margin: EdgeInsets.only(left: hovered ? 16 : 0),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: hovered ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: hovered
                      ? [
                          BoxShadow(
                              color: (c['c1'] as Color).withValues(alpha: 0.6),
                              blurRadius: 20,
                              spreadRadius: 2)
                        ]
                      : []),
              child: hovered
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FadeInImage(
                        placeholder:
                            const AssetImage('assets/images/Profile.JPG'),
                        image: AssetImage(c['img'] as String),
                        fit: BoxFit.contain,
                        fadeInDuration: const Duration(milliseconds: 150),
                      ))
                  : null,
            ),
            if (!hovered)
              Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(Icons.arrow_forward,
                      color: c['c1'] as Color, size: 24)),
          ]),
        ),
      ),
    );
  }
}
