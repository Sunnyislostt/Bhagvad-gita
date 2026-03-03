import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/verse.dart';
import '../widgets/verse_card.dart';
import '../widgets/glass_container.dart';
import '../services/notification_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  static const String _savedVersesKey = 'saved_verse_ids';
  static const String _lastReadIndexKey = 'last_read_verse_index';
  static const String _recentVerseIdsKey = 'recent_verse_ids';

  final PageController _pageController = PageController();
  final GlobalKey _globalKey = GlobalKey();

  List<Verse> _verses = <Verse>[];
  Set<String> _savedVerseIds = <String>{};
  List<String> _recentVerseIds = <String>[];

  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showEnglish = false;
  bool _hideUI = false;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _loadPersistedState();
    await _loadVerses();
    await _loadNotificationState();
  }

  Future<void> _loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }

    setState(() {
      _savedVerseIds = (prefs.getStringList(_savedVersesKey) ?? <String>[]).toSet();
      _recentVerseIds = prefs.getStringList(_recentVerseIdsKey) ?? <String>[];
      _currentIndex = prefs.getInt(_lastReadIndexKey) ?? 0;
    });
  }

  Future<void> _persistSavedVerses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedVersesKey, _savedVerseIds.toList());
  }

  Future<void> _persistCurrentIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastReadIndexKey, index);
  }

  Future<void> _persistRecentVerses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentVerseIdsKey, _recentVerseIds);
  }

  void _recordVerseInHistory(String verseId) {
    _recentVerseIds.remove(verseId);
    _recentVerseIds.insert(0, verseId);

    if (_recentVerseIds.length > 30) {
      _recentVerseIds = _recentVerseIds.sublist(0, 30);
    }

    _persistRecentVerses();
  }

  Future<void> _loadNotificationState() async {
    final enabled = await NotificationService().areNotificationsEnabled();
    if (!mounted) {
      return;
    }

    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  Future<void> _toggleNotifications() async {
    final newState = !_notificationsEnabled;
    await NotificationService().toggleNotifications(newState);

    if (!mounted) {
      return;
    }

    setState(() {
      _notificationsEnabled = newState;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newState
              ? "Daily notifications enabled (Today's Verse + Random Verse)"
              : 'Daily notifications disabled',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadVerses() async {
    try {
      final response = await rootBundle.loadString('assets/data/verses.json');
      final data = json.decode(response) as List<dynamic>;
      final loadedVerses = data
          .map((verseJson) => Verse.fromJson(verseJson as Map<String, dynamic>))
          .toList();

      if (!mounted) {
        return;
      }

      final safeIndex = loadedVerses.isEmpty
          ? 0
          : _currentIndex.clamp(0, loadedVerses.length - 1).toInt();

      setState(() {
        _verses = loadedVerses;
        _currentIndex = safeIndex;
        _isLoading = false;
      });

      if (loadedVerses.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(safeIndex);
          }
        });

        _recordVerseInHistory(loadedVerses[safeIndex].id);
        _persistCurrentIndex(safeIndex);
      }
    } catch (e) {
      debugPrint('Error loading verses: $e');
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _hexToColor(String hexCode) {
    var hex = hexCode.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse('0x$hex'));
  }

  Future<void> _shareCurrentScreen() async {
    setState(() {
      _hideUI = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Could not capture screen');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to encode image');
      }

      final pngBytes = byteData.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/bhagavad_gita_verse_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      final verse = _verses[_currentIndex];
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path)],
          text: 'Chapter ${verse.chapter}, Verse ${verse.verseNumber} - Bhagavad Gita',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to share. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _hideUI = false;
        });
      }
    }
  }

  void _toggleSave(String id) {
    setState(() {
      if (_savedVerseIds.contains(id)) {
        _savedVerseIds.remove(id);
      } else {
        _savedVerseIds.add(id);
      }
    });
    _persistSavedVerses();
  }

  List<Verse> _recentVerses() {
    final verseById = <String, Verse>{
      for (final verse in _verses) verse.id: verse,
    };
    return _recentVerseIds
        .map((id) => verseById[id])
        .whereType<Verse>()
        .toList();
  }

  bool _matchesSearchQuery(Verse verse, String query) {
    final lowerQuery = query.toLowerCase();
    final chapterVerse = '${verse.chapter}:${verse.verseNumber}';
    final chapterVerseSpaced = '${verse.chapter} ${verse.verseNumber}';

    return chapterVerse.contains(lowerQuery) ||
        chapterVerseSpaced.contains(lowerQuery) ||
        verse.id.toLowerCase().contains(lowerQuery) ||
        verse.translationEnglish.toLowerCase().contains(lowerQuery) ||
        verse.transliteration.toLowerCase().contains(lowerQuery) ||
        verse.originalScript.contains(query);
  }

  void _jumpToVerseById(String verseId) {
    final targetIndex = _verses.indexWhere((verse) => verse.id == verseId);
    if (targetIndex == -1) {
      return;
    }

    _pageController.animateToPage(
      targetIndex,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _showSearchSheet() {
    final searchController = TextEditingController();
    var searchResults = _recentVerses();
    if (searchResults.isEmpty) {
      searchResults = _verses.take(30).toList();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                void updateSearchResults(String value) {
                  final query = value.trim();
                  List<Verse> nextResults;

                  if (query.isEmpty) {
                    final recent = _recentVerses();
                    nextResults = recent.isNotEmpty ? recent : _verses.take(30).toList();
                  } else {
                    nextResults = _verses
                        .where((verse) => _matchesSearchQuery(verse, query))
                        .take(60)
                        .toList();
                  }

                  setModalState(() {
                    searchResults = nextResults;
                  });
                }

                return GlassContainer(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  opacity: 0.15,
                  blur: 25,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          controller: searchController,
                          style: GoogleFonts.inter(color: Colors.white),
                          onChanged: updateSearchResults,
                          decoration: InputDecoration(
                            hintText: 'Search chapter, verse, Sanskrit, or English',
                            hintStyle: GoogleFonts.inter(color: Colors.white70),
                            prefixIcon: const Icon(Icons.search, color: Colors.white70),
                            suffixIcon: searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white70),
                                    onPressed: () {
                                      searchController.clear();
                                      updateSearchResults('');
                                    },
                                  ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.08),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: searchResults.isEmpty
                            ? Center(
                                child: Text(
                                  'No verses found',
                                  style: GoogleFonts.inter(color: Colors.white70),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: searchResults.length,
                                itemBuilder: (context, index) {
                                  final verse = searchResults[index];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 6,
                                    ),
                                    title: Text(
                                      'Chapter ${verse.chapter}, Verse ${verse.verseNumber}',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      verse.translationEnglish,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(color: Colors.white70),
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _jumpToVerseById(verse.id);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(searchController.dispose);
  }

  void _showSavedVerses(BuildContext context) {
    final savedVerses = _verses.where((verse) => _savedVerseIds.contains(verse.id)).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return GlassContainer(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              opacity: 0.15,
              blur: 25,
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Saved Verses',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: savedVerses.isEmpty
                        ? Center(
                            child: Text(
                              'No saved verses yet.',
                              style: GoogleFonts.inter(color: Colors.white70),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: savedVerses.length,
                            itemBuilder: (context, index) {
                              final verse = savedVerses[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                title: Text(
                                  'Chapter ${verse.chapter}, Verse ${verse.verseNumber}',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Text(
                                  verse.translationEnglish,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(color: Colors.white70),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.info_outline, color: Colors.white54),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        VerseCard.showDetailsBottomSheet(context, verse);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.bookmark_remove, color: Colors.white54),
                                      onPressed: () {
                                        _toggleSave(verse.id);
                                        Navigator.pop(context);
                                        _showSavedVerses(context);
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  VerseCard.showDetailsBottomSheet(context, verse);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_verses.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No verses found.')),
      );
    }

    final currentBgColor = _hexToColor(_verses[_currentIndex].backgroundHexColor);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: RepaintBoundary(
        key: _globalKey,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    currentBgColor.withValues(alpha: 0.8),
                    currentBgColor.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _verses.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _persistCurrentIndex(index);
                _recordVerseInHistory(_verses[index].id);
              },
              itemBuilder: (context, index) {
                final verse = _verses[index];
                return VerseCard(
                  verse: verse,
                  isEnglish: _showEnglish,
                  isSaved: _savedVerseIds.contains(verse.id),
                  onSave: () => _toggleSave(verse.id),
                  onShare: _shareCurrentScreen,
                  hideUI: _hideUI,
                );
              },
            ),
            if (!_hideUI)
              Positioned(
                top: 60,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showEnglish = !_showEnglish;
                        });
                      },
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        borderRadius: BorderRadius.circular(20),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.translate, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _showEnglish ? 'EN' : 'SA',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _toggleNotifications,
                          child: GlassContainer(
                            padding: const EdgeInsets.all(10),
                            borderRadius: BorderRadius.circular(20),
                            child: Icon(
                              _notificationsEnabled
                                  ? Icons.notifications_active
                                  : Icons.notifications_off_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _showSearchSheet,
                          child: GlassContainer(
                            padding: const EdgeInsets.all(10),
                            borderRadius: BorderRadius.circular(20),
                            child: const Icon(
                              Icons.search,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _showSavedVerses(context),
                          child: GlassContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            borderRadius: BorderRadius.circular(20),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bookmark, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Saved',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
