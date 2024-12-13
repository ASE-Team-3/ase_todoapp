import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app/utils/app_colors.dart';

class AIFeedbackWidget extends StatefulWidget {
  final Future<Map<String, String>> Function({bool forceRefresh})
      onRefresh; // Fetch AI feedback with optional force

  const AIFeedbackWidget({
    super.key,
    required this.onRefresh,
  });

  @override
  State<AIFeedbackWidget> createState() => _AIFeedbackWidgetState();
}

class _AIFeedbackWidgetState extends State<AIFeedbackWidget> {
  bool _showFullMessage = false;
  bool _showFullRecommendation = false;
  bool _isRefreshing = false;
  bool _isCooldownActive = false;
  int _remainingTime = 0;
  static const int _cooldownDuration = 60;
  static const int _maxPreviewLength = 300;

  Timer? _cooldownTimer;
  String _feedbackMessage = "";
  String _recommendation = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeedback(); // Initial fetch
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel(); // Cancel the cooldown timer
    super.dispose();
  }

  /// Fetch AI feedback (initial or refresh)
  Future<void> _fetchFeedback({bool forceRefresh = false}) async {
    if (!mounted) return; // Ensure widget is still in the tree

    setState(() {
      _isLoading = true;
      _isRefreshing = false; // Ensure refresh spinner is inactive initially
    });

    try {
      final feedback = await widget.onRefresh(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _feedbackMessage =
              feedback['message'] ?? "No motivational message available.";
          _recommendation =
              feedback['recommendation'] ?? "No recommendation available.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _feedbackMessage = "Error fetching feedback.";
          _recommendation = "Error fetching recommendation.";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  /// Start the cooldown timer
  void _startCooldown() {
    if (!mounted) return;

    setState(() {
      _isCooldownActive = true;
      _remainingTime = _cooldownDuration;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingTime > 1) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isCooldownActive = false;
            _remainingTime = 0;
          });
        }
      }
    });
  }

  String _shortenText(String text, bool isExpanded) {
    if (isExpanded || text.length <= _maxPreviewLength) return text;
    return "${text.substring(0, _maxPreviewLength)}...";
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AI Feedback",
                      style:
                          Theme.of(context).textTheme.headlineMedium!.copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Motivational Message:",
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _shortenText(_feedbackMessage, _showFullMessage),
                      style: TextStyle(
                        fontSize: size.width < 600 ? 14 : 16,
                        color: Colors.black87,
                      ),
                    ),
                    if (_feedbackMessage.length > _maxPreviewLength)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showFullMessage = !_showFullMessage;
                          });
                        },
                        child: Text(
                          _showFullMessage ? "Show Less" : "Read More",
                          style: TextStyle(color: AppColors.primaryColor),
                        ),
                      ),
                    const SizedBox(height: 15),
                    Text(
                      "Recommendation:",
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _shortenText(_recommendation, _showFullRecommendation),
                      style: TextStyle(
                        fontSize: size.width < 600 ? 14 : 16,
                        color: Colors.black54,
                      ),
                    ),
                    if (_recommendation.length > _maxPreviewLength)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showFullRecommendation = !_showFullRecommendation;
                          });
                        },
                        child: Text(
                          _showFullRecommendation ? "Show Less" : "Read More",
                          style: TextStyle(color: AppColors.primaryColor),
                        ),
                      ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      icon: _isRefreshing
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        _isRefreshing
                            ? "Refreshing..."
                            : _isCooldownActive
                                ? "Wait $_remainingTime sec"
                                : "Refresh Recommendation",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCooldownActive || _isRefreshing
                            ? Colors.grey
                            : AppColors.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isRefreshing || _isCooldownActive
                          ? null
                          : () async {
                              setState(() {
                                _isRefreshing = true;
                              });
                              await _fetchFeedback(forceRefresh: true);
                              _startCooldown();
                            },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
