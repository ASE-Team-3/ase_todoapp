import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app/utils/app_colors.dart';

class AIFeedbackWidget extends StatefulWidget {
  final String feedbackMessage;
  final String recommendation;
  final Future<void> Function() onRefresh; // Callback for refresh action

  const AIFeedbackWidget({
    super.key,
    required this.feedbackMessage,
    required this.recommendation,
    required this.onRefresh,
  });

  @override
  State<AIFeedbackWidget> createState() => _AIFeedbackWidgetState();
}

class _AIFeedbackWidgetState extends State<AIFeedbackWidget> {
  bool _showFullMessage = false;
  bool _showFullRecommendation = false;
  bool _isRefreshing = false;
  bool _isCooldownActive = false; // Cooldown state
  int _remainingTime = 0; // Remaining cooldown time in seconds
  static const int _cooldownDuration = 60; // Cooldown duration in seconds
  static const int _maxPreviewLength = 300;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel(); // Ensure timer is cleaned up
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _isCooldownActive = true;
      _remainingTime = _cooldownDuration;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 1) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isCooldownActive = false;
          _remainingTime = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Utility to shorten text with "Read More" toggle
    String _shortenText(String text, bool isExpanded) {
      if (isExpanded || text.length <= _maxPreviewLength) {
        return text;
      }
      return "${text.substring(0, _maxPreviewLength)}...";
    }

    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                "AI Feedback",
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),

              // Motivational Message Section
              Text(
                "Motivational Message:",
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 5),
              Text(
                _shortenText(widget.feedbackMessage, _showFullMessage),
                style: TextStyle(
                  fontSize: size.width < 600 ? 14 : 16,
                  color: Colors.black87,
                ),
              ),
              if (widget.feedbackMessage.length > _maxPreviewLength)
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

              // Recommendation Section
              Text(
                "Recommendation:",
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 5),
              Text(
                _shortenText(widget.recommendation, _showFullRecommendation),
                style: TextStyle(
                  fontSize: size.width < 600 ? 14 : 16,
                  color: Colors.black54,
                ),
              ),
              if (widget.recommendation.length > _maxPreviewLength)
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

              // Refresh Recommendation Button
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
                      ? Colors.grey // Disabled button color
                      : AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isRefreshing || _isCooldownActive
                    ? null
                    : () async {
                        setState(() {
                          _isRefreshing = true;
                        });
                        await widget.onRefresh();
                        setState(() {
                          _isRefreshing = false;
                        });
                        _startCooldown(); // Start cooldown timer
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
