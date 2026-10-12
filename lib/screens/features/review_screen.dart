import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/review_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final int bookingId;
  final int reviewedUserId;
  final String mentorName;
  final String skillName;

  const ReviewScreen({
    super.key,
    required this.bookingId,
    required this.reviewedUserId,
    required this.mentorName,
    required this.skillName,
  });

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _selectedRating = 0;
  bool _isSubmitted = false;
  bool _isLoading = false;
  final TextEditingController _feedbackController = TextEditingController();

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating of 1 to 5 stars.')),
      );
      return;
    }

    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please share some details in the comment field.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(userReviewsProvider(widget.reviewedUserId).notifier).submitReview(
            bookingId: widget.bookingId,
            rating: _selectedRating.toDouble(),
            comment: _feedbackController.text.trim(),
          );
      
      setState(() {
        _isSubmitted = true;
        _isLoading = false;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context, true); // Return true indicating success
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review. Please try again.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80)
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: AppConstants.paddingL),
              Text(
                'Review Submitted!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ).animate().fade().slideY(begin: 0.2, delay: 200.ms),
              const SizedBox(height: AppConstants.paddingS),
              const Text('Thank you for your feedback.', style: TextStyle(color: Colors.grey))
                  .animate()
                  .fade()
                  .slideY(begin: 0.2, delay: 300.ms),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Leave a Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Icon(Icons.person, size: 40, color: Theme.of(context).primaryColor),
              ),
            ).animate().scale(),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              'How was your session with ${widget.mentorName}?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ).animate().fade().slideY(begin: 0.1),
            Text(
              widget.skillName,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ).animate().fade().slideY(begin: 0.1, delay: 100.ms),
            const SizedBox(height: AppConstants.paddingXL),
            
            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedRating = index + 1;
                    });
                  },
                );
              }),
            ).animate().fade(delay: 200.ms),
            
            const SizedBox(height: AppConstants.paddingL),
            
            // Feedback Text Area
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _feedbackController,
                maxLength: 500,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Share details of your own experience at this session...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(AppConstants.paddingM),
                ),
              ),
            ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
            
            const SizedBox(height: AppConstants.paddingXL),
            
            CustomButton(
              text: _isLoading ? 'Submitting...' : 'Submit Review',
              onPressed: _isLoading ? () {} : _submitReview,
            ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }
}
