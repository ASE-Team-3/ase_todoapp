import 'package:flutter/material.dart';
import 'package:app/utils/app_colors.dart';

class AIFeedbackWidget extends StatefulWidget {
  final String feedbackMessage;
  final String recommendation;

  const AIFeedbackWidget({
    super.key,
    required this.feedbackMessage,
    required this.recommendation,
  });

  @override
  State<AIFeedbackWidget> createState() => _AIFeedbackWidgetState();
}

class _AIFeedbackWidgetState extends State<AIFeedbackWidget> {
  bool _showFullMessage = false;
  bool _showFullRecommendation = false;

  static const int _maxPreviewLength = 300;

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
            ],
          ),
        ),
      ),
    );
  }
}
