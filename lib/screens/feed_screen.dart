import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/verse.dart';
import '../widgets/verse_card.dart';
import '../widgets/glass_container.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Verse> _verses = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showEnglish = false;
  final Set<String> _savedVerseIds = {};
  final PageController _pageController = PageController();
  final GlobalKey _globalKey = GlobalKey();
  bool _hideUI = false;

  @override
  void initState() {
    super.initState();
    _loadVerses();
  }

  Future<void> _loadVerses() async {
    try {
      final String response = await rootBundle.loadString('assets/data/verses.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        _verses = data.map((json) => Verse.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading verses: $e");
    }
  }

  Color _hexToColor(String hexCode) {
    String hex = hexCode.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add opacity if missing
    }
    return Color(int.parse('0x$hex'));
  }

  Future<void> _shareCurrentScreen() async {
    setState(() {
      _hideUI = true;
    });
    // Wait for frame to render
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/shared_verse.png').create();
        await imagePath.writeAsBytes(pngBytes);
        final verse = _verses[_currentIndex];
        await Share.shareXFiles(
          [XFile(imagePath.path)], 
          text: 'Check out Chapter ${verse.chapter}, Verse ${verse.verseNumber} from the Bhagavad Gita!'
        );
      }
    } catch (e) {
      debugPrint("Error sharing: $e");
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
  }

  void _showSavedVerses(BuildContext context) {
    final savedVerses = _verses.where((v) => _savedVerseIds.contains(v.id)).toList();
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
                    "Saved Verses",
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
                              "No saved verses yet.",
                              style: GoogleFonts.inter(color: Colors.white70),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: savedVerses.length,
                            itemBuilder: (context, index) {
                              final v = savedVerses[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                title: Text(
                                  "Chapter ${v.chapter}, Verse ${v.verseNumber}",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Text(
                                  v.translationEnglish,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(color: Colors.white70),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.bookmark_remove, color: Colors.white54),
                                  onPressed: () {
                                    _toggleSave(v.id);
                                    Navigator.pop(context); // Close to refresh currently
                                  },
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  final idx = _verses.indexOf(v);
                                  if (idx != -1 && _pageController.hasClients) {
                                    _pageController.animateToPage(
                                      idx,
                                      duration: const Duration(milliseconds: 500),
                                      curve: Curves.easeInOut,
                                    );
                                  }
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
        body: Center(child: Text("No verses found.")),
      );
    }

    // Determine current background color for smooth transition
    Color currentBgColor = _hexToColor(_verses[_currentIndex].backgroundHexColor);

    return Scaffold(
      body: RepaintBoundary(
        key: _globalKey,
        child: Stack(
          children: [
            // Dynamic Background Layer with smooth color transition
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

            // Content Layer (The "Reel")
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _verses.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
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

            // Top Header Overlay
            if (!_hideUI)
              Positioned(
                top: 60,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Language Toggle
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
                            Icon(Icons.translate, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _showEnglish ? "EN" : "सं",
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Saved list trigger
                    GestureDetector(
                      onTap: () => _showSavedVerses(context),
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        borderRadius: BorderRadius.circular(20),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bookmark, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "Saved",
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
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
