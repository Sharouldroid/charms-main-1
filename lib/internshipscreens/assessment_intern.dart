import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/internshipproviders/assessment_provider.dart';
import 'package:charms/internshipscreens/assesstment_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charms/main.dart';

class AssessmentInternPage extends StatefulWidget {
  final int internId;
  final String? photoUrl;
  final bool isAdmin;

  const AssessmentInternPage({
    super.key,
    required this.internId,
    this.photoUrl,
    this.isAdmin = false,
  });

  @override
  _AssessmentInternPageState createState() => _AssessmentInternPageState();
}

class _AssessmentInternPageState extends State<AssessmentInternPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  String? _resolvedPhotoUrl;

  final Map<String, String> _criterionLabels = {
    'criterion_1': 'Communication Skills',
    'criterion_2': 'Problem Solving',
    'criterion_3': 'Teamwork',
    'criterion_4': 'Punctuality',
    'criterion_5': 'Adaptability',
  };

  final Map<String, IconData> _criterionIcons = {
    'criterion_1': Icons.chat_bubble_outline_rounded,
    'criterion_2': Icons.lightbulb_outline_rounded,
    'criterion_3': Icons.group_outlined,
    'criterion_4': Icons.access_time_rounded,
    'criterion_5': Icons.shuffle_rounded,
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        Provider.of<AssessmentProvider>(context, listen: false)
            .loadAssessmentData(widget.internId),
        _loadPhoto(),
      ]);
      _animController.forward();
    });
  }

  Future<void> _loadPhoto() async {
    if (widget.photoUrl != null) {
      setState(() => _resolvedPhotoUrl = widget.photoUrl);
      return;
    }
    try {
      final response = await http.get(Uri.parse(
        '${AppConfig.hostname}/api/internship/registers/${widget.internId}/with-photo',
      ));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final filepath = data['filepath'];
        if (filepath != null && filepath.toString().isNotEmpty) {
          setState(() {
            _resolvedPhotoUrl =
                'https://devcms.com.my/charmsAPI/public/storage/$filepath';
          });
        }
      }
    } catch (e) {
      // fail silently
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _barColor(int score) {
    if (score >= 4) return const Color(0xFF1D9E75);
    if (score == 3) return const Color(0xFFEF9F27);
    return const Color(0xFFD85A30);
  }

  Color _badgeBg(int score) {
    if (score >= 4) return const Color(0xFFE1F5EE);
    if (score == 3) return const Color(0xFFFAEEDA);
    return const Color(0xFFFAECE7);
  }

  Color _badgeText(int score) {
    if (score >= 4) return const Color(0xFF0F6E56);
    if (score == 3) return const Color(0xFF854F0B);
    return const Color(0xFF993C1D);
  }

  String _badgeLabel(int score) {
    if (score == 5) return 'Excellent';
    if (score == 4) return 'Good';
    if (score == 3) return 'Average';
    return 'Needs work';
  }

  double _calculateAverage(Map<String, int> ratings) {
    if (ratings.isEmpty) return 0.0;
    return ratings.values.reduce((a, b) => a + b) / ratings.length;
  }

  Widget _starRow(int score, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < score ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: i < score ? const Color(0xFFEF9F27) : Colors.grey[300],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AssessmentProvider>(context);
    final ratings = provider.ratings;
    final isLoading = provider.isLoading;
    final errorMessage = provider.errorMessage;
    final avg = _calculateAverage(ratings);
    final hasData = ratings.isNotEmpty && errorMessage == null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Performance Overview'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // FAB: only shown to admin
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                Provider.of<AssessmentProvider>(context, listen: false)
                    .resetRatings();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NextPage(internId: widget.internId),
                  ),
                ).then((_) {
                  _animController.reset();
                  Provider.of<AssessmentProvider>(context, listen: false)
                      .loadAssessmentData(widget.internId)
                      .then((_) => _animController.forward());
                });
              },
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.rate_review),
              label: Text(hasData ? 'Re-assess Intern' : 'Assess Intern'),
            )
          : null,

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                children: [
                  // ── Header card ──────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar + title row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.blue[50],
                              backgroundImage: _resolvedPhotoUrl != null
                                  ? NetworkImage(_resolvedPhotoUrl!)
                                  : null,
                              child: _resolvedPhotoUrl == null
                                  ? Text(
                                      'A',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue[700],
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'My Assessment',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Internship performance',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        Divider(color: Colors.grey[100], height: 28),

                        // Score section: only show when data exists
                        if (hasData) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Overall score',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        avg.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '/ 5.0',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                  _starRow(avg.round()),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _badgeBg(avg.round()),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  _badgeLabel(avg.round()),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _badgeText(avg.round()),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // No data yet
                          Row(
                            children: [
                              Icon(Icons.pending_outlined,
                                  color: Colors.grey[400], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Not yet assessed',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          if (widget.isAdmin) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Tap "Assess Intern" below to submit an evaluation.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Error banner (non-blocking) ──────────────────────────
                  if (errorMessage != null &&
                      errorMessage != 'No assessment data found')
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: const TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── "No assessment" info banner ──────────────────────────
                  if (errorMessage == 'No assessment data found')
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.isAdmin
                                  ? 'No assessment submitted yet. Use the button below to assess this intern.'
                                  : 'No assessment data found.',
                              style: const TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Criterion cards (only when data exists) ──────────────
                  if (hasData)
                    ...ratings.keys.map((key) {
                      final score = ratings[key]!;
                      final label = _criterionLabels[key] ??
                          key.replaceAll('_', ' ').capitalize();
                      final icon =
                          _criterionIcons[key] ?? Icons.star_outline;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              // ── FIX: use Flexible to prevent overflow ──
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Left: icon + label (shrinks if needed)
                                  Flexible(
                                    child: Row(
                                      children: [
                                        Icon(icon,
                                            size: 18,
                                            color: Colors.grey[400]),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            label,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Right: stars + badge (fixed, min size)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _starRow(score, size: 14),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _badgeBg(score),
                                          borderRadius:
                                              BorderRadius.circular(99),
                                        ),
                                        child: Text(
                                          _badgeLabel(score),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: _badgeText(score),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Animated progress bar
                              AnimatedBuilder(
                                animation: _animController,
                                builder: (_, __) => ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: (score / 5) * _animController.value,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey[100],
                                    valueColor: AlwaysStoppedAnimation(
                                        _barColor(score)),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 6),

                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '$score / 5',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 8),

                  // ── Reload button ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        _animController.reset();
                        await Provider.of<AssessmentProvider>(context,
                                listen: false)
                            .loadAssessmentData(widget.internId);
                        _animController.forward();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Reload assessment'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueAccent,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}