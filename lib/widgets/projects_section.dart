import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../services/github_service.dart';

class ProjectsSection extends StatefulWidget {
  final String githubUsername;
  final String? githubToken;
  final String? geminiApiKey;
  final bool eagerLoad;
  final Function(List<Map<String, dynamic>>)? onProjectsRefreshed;

  const ProjectsSection({
    super.key,
    required this.githubUsername,
    this.githubToken,
    this.eagerLoad = false,
    this.onProjectsRefreshed,
    this.geminiApiKey,
  });

  @override
  State<ProjectsSection> createState() => _ProjectsSectionState();
}

class _ProjectsSectionState extends State<ProjectsSection> {
  late GitHubService _githubService;
  List<Map<String, dynamic>>? _projects;
  List<Map<String, dynamic>>? _cachedProjects;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _isOffline = false;
  int? _hoveredProject;
  bool _isDesktop = false;

  // Track which projects are visible on mobile
  final Set<int> _visibleProjects = {};

  final List<Color> _projectColors = const [
    Color(0xFF02569B),
    Color(0xFF4CAF50),
    Color(0xFFFF6B6B),
    Color(0xFF9C27B0),
    Color(0xFFFF9800),
    Color(0xFF00BCD4),
    Color(0xFFE91E63),
    Color(0xFF3F51B5),
    Color(0xFF009688),
    Color(0xFFFFC107),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize with safe defaults
    _githubService = GitHubService(
      widget.githubUsername,
      token: widget.githubToken ?? '',
      geminiApiKey: widget.geminiApiKey ?? '',
    );

    if (widget.eagerLoad) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _loadProjects();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _loadProjects();
        });
      });
    }
  }

  String _loadingStatus = 'Initializing...';

  Future<void> _loadProjects({bool forceRefresh = false}) async {
    if (!mounted) return;

    if (forceRefresh) {
      setState(() {
        _isRefreshing = true;
        _loadingStatus = 'Starting refresh...';
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _isOffline = false;
        _loadingStatus = 'Initializing...';
      });
    }

    try {
      // Safely get tokens from environment
      String? githubToken = widget.githubToken;
      String? geminiKey = widget.geminiApiKey;

      // Try to load from dotenv if not provided
      try {
        if (dotenv.isInitialized) {
          githubToken ??= dotenv.env['GITHUB_TOKEN'];
          geminiKey ??= dotenv.env['GEMINI_API_KEY'];
        }
      } catch (e) {
        debugPrint('⚠️ Could not access dotenv: $e');
      }

      setState(() => _loadingStatus = 'Fetching projects...');

      // Reinitialize service with tokens
      _githubService = GitHubService(
        widget.githubUsername,
        token: githubToken ?? '',
        geminiApiKey: geminiKey ?? '',
      );

      final projects = await _githubService
          .fetchFilteredRepositoriesFast(
        forceRefresh: forceRefresh,
        batchSize: 3,
        onProgress: (status) {
          if (mounted) {
            setState(() => _loadingStatus = status);
          }
        },
      )
          .timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          throw TimeoutException(
            'Loading took too long. Please check your internet connection and try again.',
          );
        },
      );

      projects.sort((a, b) {
        final scoreA = a['project_score'] as int? ?? 0;
        final scoreB = b['project_score'] as int? ?? 0;
        return scoreB.compareTo(scoreA);
      });

      if (mounted) {
        setState(() {
          _projects = projects;
          _cachedProjects = projects;
          _isLoading = false;
          _isRefreshing = false;
          _loadingStatus = 'Complete!';
        });

        if (widget.onProjectsRefreshed != null) {
          widget.onProjectsRefreshed!(projects);
        }
      }
    } on TimeoutException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message ?? 'Request timed out';
          _isLoading = false;
          _isRefreshing = false;
          _isOffline = false;
          _loadingStatus = 'Timeout';
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading projects: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _isRefreshing = false;
          _isOffline = e.toString().contains('Failed host lookup') ||
              e.toString().contains('SocketException');
          _loadingStatus = 'Error';
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Color _getProjectColor(int index) {
    return _projectColors[index % _projectColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width > 1024;
        final isTablet = width > 768 && width <= 1024;
        final isMobile = width <= 768;
        _isDesktop = isDesktop;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 120 : (isMobile ? 18 : 40),
            vertical: 100,
          ),
          child: Column(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFDA8B26), Color(0xFFFFC107)],
                ).createShader(bounds),
                child: const Text(
                  'Featured Projects',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Showcase of my best work',
                style: TextStyle(color: Colors.white60, fontSize: 18),
              ),
              const SizedBox(height: 50),
              if (_isLoading && _cachedProjects == null)
                _buildLoadingState()
              else if (_errorMessage != null && _cachedProjects == null)
                _buildErrorState(isDesktop)
              else if ((_projects == null || _projects!.isEmpty) &&
                  _cachedProjects == null)
                _buildEmptyState()
              else
                _buildProjectsGrid(isDesktop, isTablet, isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 2000),
                  builder: (context, value, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120 + (20 * value),
                          height: 120 + (20 * value),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFDA8B26)
                                  .withValues(alpha: 0.3 * (1 - value)),
                              width: 2,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          height: 100,
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
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFDA8B26).withValues(alpha: 0.3),
                                const Color(0xFFFFC107).withValues(alpha: 0.2),
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.folder_open,
                            size: 30,
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
                ),
                const SizedBox(height: 32),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    backgroundColor:
                        const Color(0xFFDA8B26).withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFFC107),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFDA8B26), Color(0xFFFFC107)],
                  ).createShader(bounds),
                  child: const Text(
                    'Loading Projects',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _loadingStatus,
                    key: ValueKey(_loadingStatus),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 15,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDA8B26).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFDA8B26).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFDA8B26),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'First load may take up to 2 minutes while analyzing repositories',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha: 0.1),
            Colors.red.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            _isOffline ? Icons.wifi_off : Icons.error_outline,
            size: 64,
            color: Colors.red.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 20),
          Text(
            _isOffline ? 'Offline Mode' : 'Error Loading Projects',
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadProjects(forceRefresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDA8B26),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFFDA8B26).withValues(alpha: 0.1),
          const Color(0xFF1A1A2E).withValues(alpha: 0.1)
        ]),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: const Color(0xFFDA8B26).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: const Color(0xFFDA8B26).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Projects Found',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No repositories found.',
            style: TextStyle(color: Colors.white60, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsGrid(bool isDesktop, bool isTablet, bool isMobile) {
    final displayProjects = _projects ?? _cachedProjects ?? [];

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: MouseRegion(
            cursor:
                _isRefreshing ? MouseCursor.defer : SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _isRefreshing
                  ? null
                  : () => _loadProjects(forceRefresh: true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFDA8B26).withValues(alpha: 0.15),
                      const Color(0xFFFFC107).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFDA8B26).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isRefreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFDA8B26),
                              ),
                            ),
                          )
                        : ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFDA8B26), Color(0xFFFFC107)],
                            ).createShader(bounds),
                            child: const Icon(
                              Icons.refresh,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                    const SizedBox(width: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFDA8B26), Color(0xFFFFC107)],
                      ).createShader(bounds),
                      child: Text(
                        _isRefreshing ? 'Refreshing...' : 'Refresh Projects',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            const spacing = 24.0;

            double cardWidth;

            if (isMobile) {
              cardWidth = availableWidth;
            } else if (isTablet) {
              cardWidth = (availableWidth - spacing) / 2;
            } else {
              if (availableWidth > 1400) {
                cardWidth = (availableWidth - (spacing * 2)) / 3;
              } else {
                cardWidth = (availableWidth - spacing) / 2;
              }
            }

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: List.generate(
                displayProjects.length,
                (index) => _buildProjectCard(
                  displayProjects[index],
                  index,
                  isDesktop,
                  isMobile,
                  cardWidth,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProjectCard(
    Map<String, dynamic> project,
    int index,
    bool isDesktop,
    bool isMobile,
    double cardWidth,
  ) {
    final isHovered = _hoveredProject == index && _isDesktop;
    final isVisible = _visibleProjects.contains(index);

    // On mobile/tablet, show expanded view when visible
    final shouldExpand = isMobile ? isVisible : isHovered;

    final name = project['name'] as String;
    final displayTitle = project['display_title'] as String? ?? name;
    final shortSummary =
        project['short_summary'] as String? ?? 'A Flutter mobile application';
    final detailedSummary =
        project['detailed_summary'] as String? ?? shortSummary;
    final language = project['language'] as String?;
    final url = project['html_url'] as String;
    final projectColor = _getProjectColor(index);

    final currentSummary = shouldExpand ? detailedSummary : shortSummary;

    return VisibilityDetector(
      key: Key('project_$index'),
      onVisibilityChanged: (visibilityInfo) {
        if (!_isDesktop) {
          final visiblePercentage = visibilityInfo.visibleFraction * 100;
          if (mounted) {
            setState(() {
              if (visiblePercentage > 30) {
                _visibleProjects.add(index);
              } else {
                _visibleProjects.remove(index);
              }
            });
          }
        }
      },
      child: MouseRegion(
        onEnter: _isDesktop
            ? (_) {
                if (mounted) setState(() => _hoveredProject = index);
              }
            : null,
        onExit: _isDesktop
            ? (_) {
                if (mounted) setState(() => _hoveredProject = null);
              }
            : null,
        cursor: _isDesktop ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTap: () => _launchUrl(url),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            width: cardWidth,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  projectColor.withValues(alpha: shouldExpand ? 0.35 : 0.18),
                  projectColor.withValues(alpha: shouldExpand ? 0.25 : 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(shouldExpand ? 28 : 24),
              border: Border.all(
                color: projectColor.withValues(alpha: shouldExpand ? 1.0 : 0.6),
                width: shouldExpand ? 3.5 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      projectColor.withValues(alpha: shouldExpand ? 0.8 : 0.4),
                  blurRadius: shouldExpand ? 60 : 25,
                  offset: Offset(0, shouldExpand ? 25 : 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            projectColor,
                            projectColor.withValues(alpha: .7)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: shouldExpand
                            ? [
                                BoxShadow(
                                  color: projectColor.withValues(alpha: 0.7),
                                  blurRadius: 25,
                                  spreadRadius: 3,
                                )
                              ]
                            : [],
                      ),
                      child: const Icon(
                        Icons.phone_android,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        displayTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  constraints: BoxConstraints(
                    minHeight: shouldExpand ? 140 : 80,
                    maxHeight: shouldExpand ? 350 : 100,
                  ),
                  child: SingleChildScrollView(
                    physics: shouldExpand
                        ? const ClampingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: Text(
                      currentSummary,
                      style: TextStyle(
                        color: shouldExpand
                            ? Colors.white.withValues(alpha: 0.95)
                            : Colors.white.withValues(alpha: 0.75),
                        fontSize: 14,
                        height: 1.7,
                        letterSpacing: 0.3,
                      ),
                      maxLines: shouldExpand ? null : 4,
                      overflow: shouldExpand ? null : TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (language != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: projectColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: projectColor.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.code, size: 16, color: projectColor),
                        const SizedBox(width: 6),
                        Text(
                          language,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        projectColor,
                        projectColor.withValues(alpha: 0.8)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: projectColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.code, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'View on GitHub',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
