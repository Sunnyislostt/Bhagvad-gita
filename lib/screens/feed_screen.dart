import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/verse.dart';
import '../widgets/verse_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Verse> _verses = [];
  int _currentIndex = 0;
  bool _isLoading = true;

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
      body: Stack(
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
            scrollDirection: Axis.vertical,
            itemCount: _verses.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return VerseCard(verse: _verses[index]);
            },
          ),
        ],
      ),
    );
  }
}
