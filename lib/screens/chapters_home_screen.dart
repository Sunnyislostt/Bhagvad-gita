import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/verse.dart';
import '../services/reading_progress_service.dart';
import '../services/verse_repository.dart';
import '../widgets/glass_container.dart';
import 'feed_screen.dart';

class ChaptersHomeScreen extends StatefulWidget {
  const ChaptersHomeScreen({super.key});

  @override
  State<ChaptersHomeScreen> createState() => _ChaptersHomeScreenState();
}

class _ChaptersHomeScreenState extends State<ChaptersHomeScreen> {
  final VerseRepository _verseRepository = const VerseRepository();
  final ReadingProgressService _progressService = ReadingProgressService();

  List<Verse> _verses = <Verse>[];
  Map<int, Set<String>> _chapterReadIds = <int, Set<String>>{};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final verses = await _verseRepository.loadVerses();
    final chapterReadIds = await _progressService.loadChapterReadIds();
    if (!mounted) {
      return;
    }

    setState(() {
      _verses = verses;
      _chapterReadIds = chapterReadIds;
      _isLoading = false;
    });
  }

  Map<int, List<Verse>> get _versesByChapter {
    final grouped = <int, List<Verse>>{};
    for (final verse in _verses) {
      grouped.putIfAbsent(verse.chapter, () => <Verse>[]).add(verse);
    }
    for (final entry in grouped.entries) {
      entry.value.sort(Verse.compareByReadingOrder);
    }
    return grouped;
  }

  Map<int, List<Verse>> get _progressVersesByChapter {
    final grouped = <int, List<Verse>>{};
    for (final verse in _verses) {
      if (!verse.countsTowardProgress) {
        continue;
      }
      grouped.putIfAbsent(verse.chapter, () => <Verse>[]).add(verse);
    }
    for (final entry in grouped.entries) {
      entry.value.sort(Verse.compareByReadingOrder);
    }
    return grouped;
  }

  Future<void> _openChapter(int chapter) async {
    final chapterVerses = _versesByChapter[chapter];
    if (chapterVerses == null || chapterVerses.isEmpty) {
      return;
    }

    final firstVerseId = chapterVerses.first.id;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FeedScreen(initialVerseId: firstVerseId),
      ),
    );
    if (!mounted) {
      return;
    }
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _progressVersesByChapter;
    final chapters = grouped.keys.toList()..sort();
    final readTotal = chapters.fold<int>(
      0,
      (sum, chapter) {
        final chapterVerses = grouped[chapter]!;
        final read = chapterVerses
            .where((verse) => (_chapterReadIds[chapter] ?? <String>{}).contains(verse.id))
            .length;
        return sum + read;
      },
    );
    final totalVerses = grouped.values.fold<int>(
      0,
      (sum, verses) => sum + verses.length,
    );
    final overallProgress = totalVerses == 0 ? 0.0 : readTotal / totalVerses;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF33211A),
              Color(0xFF1E2A34),
              Color(0xFF14181D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bhagavad Gita',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chapter Progress',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 14),
                      GlassContainer(
                        padding: const EdgeInsets.all(14),
                        borderRadius: BorderRadius.circular(20),
                        opacity: 0.14,
                        blur: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overall Reading',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: overallProgress,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(6),
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD27D)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$readTotal / $totalVerses verses read',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: GridView.builder(
                          itemCount: chapters.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.08,
                          ),
                          itemBuilder: (context, index) {
                            final chapter = chapters[index];
                            final chapterVerses = grouped[chapter]!;
                            final total = chapterVerses.length;
                            final read = chapterVerses
                                .where(
                                  (verse) =>
                                      (_chapterReadIds[chapter] ?? <String>{}).contains(verse.id),
                                )
                                .length;
                            final progress = total == 0 ? 0.0 : read / total;

                            return GestureDetector(
                              onTap: () => _openChapter(chapter),
                              child: GlassContainer(
                                borderRadius: BorderRadius.circular(18),
                                opacity: 0.14,
                                blur: 20,
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Chapter $chapter',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '$read / $total read',
                                      style: GoogleFonts.inter(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(6),
                                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD27D)),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${(progress * 100).toStringAsFixed(0)}%',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
