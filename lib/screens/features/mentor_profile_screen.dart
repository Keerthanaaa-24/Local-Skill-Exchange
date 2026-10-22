import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../models/recommendation_model.dart';
import '../../models/chat_model.dart';
import '../../models/community_models.dart';
import '../../providers/booking_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/community_provider.dart';
import '../../repositories/community_repository.dart';
import '../../core/widgets/custom_avatar.dart';
import '../conversation_screen.dart';
import '../../routes/app_routes.dart';
import '../../core/utils/guest_guard.dart';

class MentorProfileScreen extends ConsumerStatefulWidget {
  final RecommendationModel recommendation;

  const MentorProfileScreen({super.key, required this.recommendation});

  @override
  ConsumerState<MentorProfileScreen> createState() => _MentorProfileScreenState();
}

class _MentorProfileScreenState extends ConsumerState<MentorProfileScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _meetingType = 'online';
  final TextEditingController _notesController = TextEditingController();
  bool _isBooking = false;

  void _showBookingSheet() {
    if (!GuestGuard.check(context, ref, actionName: 'book a mentoring session')) {
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: AppConstants.paddingL,
                  left: AppConstants.paddingL,
                  right: AppConstants.paddingL,
                ),
                child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Book a Session', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    
                    // Date Selection
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.calendar_today_rounded, color: Theme.of(context).primaryColor),
                      title: Text(_selectedDate == null ? 'Select Date' : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (date != null) setModalState(() => _selectedDate = date);
                      },
                    ),
                    
                    // Time Selection
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.access_time_rounded, color: Theme.of(context).primaryColor),
                      title: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) setModalState(() => _selectedTime = time);
                      },
                    ),
                    
                    // Meeting Type
                    const SizedBox(height: AppConstants.paddingM),
                    const Text('Meeting Type', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Online'),
                            value: 'online',
                            groupValue: _meetingType,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setModalState(() => _meetingType = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Offline'),
                            value: 'offline',
                            groupValue: _meetingType,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setModalState(() => _meetingType = val!),
                          ),
                        ),
                      ],
                    ),
                    
                    // Notes
                    const SizedBox(height: AppConstants.paddingM),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: AppConstants.paddingXL),
                    CustomButton(
                      text: 'Confirm Booking',
                      isLoading: _isBooking,
                      onPressed: () async {
                        if (_selectedDate == null || _selectedTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select date and time')));
                          return;
                        }
                        
                        setModalState(() => _isBooking = true);
                        try {
                          final bookingDateTime = DateTime(
                            _selectedDate!.year,
                            _selectedDate!.month,
                            _selectedDate!.day,
                            _selectedTime!.hour,
                            _selectedTime!.minute,
                          );
                          final bookingData = {
                            'skill_id': widget.recommendation.skillId,
                            'skill_title': widget.recommendation.skillTitle,
                            'mentor_id': widget.recommendation.mentorId,
                            'mentor_name': widget.recommendation.mentorName,
                            'date': bookingDateTime.toIso8601String(),
                            'booking_date': '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                            'booking_time': '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                            'location': _meetingType,
                            'meeting_type': _meetingType,
                            'credits_cost': 10,
                            'credits': 10,
                            'duration': 60,
                            'booking_status': 'upcoming',
                            'notes': _notesController.text,
                          };

                          await ref.read(bookingNotifierProvider.notifier).createBooking(bookingData);
                          
                          if (context.mounted) {
                            Navigator.pop(context); // Close sheet
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking confirmed successfully!')));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
                          }
                        } finally {
                          if (mounted) {
                            setModalState(() => _isBooking = false);
                          }
                        }
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingL),
                  ],
                ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openChat(BuildContext context) {
    if (!GuestGuard.check(context, ref, actionName: 'chat with mentors')) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationScreen(
          chatId: widget.recommendation.mentorId,
          chat: ChatModel(
            chatId: widget.recommendation.mentorId,
            mentorId: widget.recommendation.mentorId,
            learnerId: 1,
            partnerName: widget.recommendation.mentorName,
            partnerAvatar: widget.recommendation.mentorProfileImage ?? '',
            lastMessage: 'Let\'s start a conversation!',
            lastMessageTime: DateTime.now().toIso8601String(),
            unreadCount: 0,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
            isOnline: true,
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    String selectedReason = 'Inappropriate content';
    final descController = TextEditingController();
    final reasons = ['Inappropriate content', 'Harassment', 'Spam', 'Scam / Fraud', 'Other'];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.report_problem_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Report User', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select reason:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  isExpanded: true,
                  items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedReason = val);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Additional details (optional):', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Describe the issue...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  await ref.read(communityRepositoryProvider).reportUser(
                    widget.recommendation.mentorId,
                    selectedReason,
                    description: descController.text.trim(),
                  );
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report submitted. Thank you for keeping our community safe.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to submit report: $e')),
                    );
                  }
                }
              },
              child: const Text('Submit Report', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Block User?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Are you sure you want to block ${widget.recommendation.mentorName}? They will no longer be able to message or interact with you.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ref.read(communityRepositoryProvider).blockUser(widget.recommendation.mentorId);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${widget.recommendation.mentorName} has been blocked.')),
                  );
                  Navigator.pop(context); // return to previous screen
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to block user: $e')),
                  );
                }
              }
            },
            child: const Text('Block', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(userReviewsProvider(widget.recommendation.mentorId));
    final communityProfileAsync = ref.watch(communityProfileProvider(widget.recommendation.mentorId));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(context),
                  const SizedBox(height: AppConstants.paddingM),
                  _buildTrustIndicatorsSection(context, communityProfileAsync),
                  const SizedBox(height: AppConstants.paddingL),
                  _buildBioSection(context),
                  const SizedBox(height: AppConstants.paddingL),
                  _buildSkillsSection(context),
                  const SizedBox(height: AppConstants.paddingL),
                  _buildReviewsSection(context, reviewsAsync),
                  const SizedBox(height: AppConstants.paddingXL),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () => _openChat(context),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: 'Book a Session',
                  icon: Icons.calendar_month_rounded,
                  onPressed: _showBookingSheet,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustIndicatorsSection(BuildContext context, AsyncValue<CommunityProfileModel> profileAsync) {
    return profileAsync.maybeWhen(
      data: (profile) {
        final trust = profile.trustIndicators;
        return Container(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  const Text('Community Trust Signals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  if (trust.isVerifiedMentor)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Text(
                        'Verified Mentor',
                        style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildTrustChip(
                    Icons.workspace_premium_rounded,
                    Colors.amber.shade700,
                    '${trust.verifiedCertificatesCount} Verified Certs',
                  ),
                  _buildTrustChip(
                    Icons.handshake_outlined,
                    Colors.blue.shade700,
                    '${trust.completedExchanges} Completed Exchanges',
                  ),
                  _buildTrustChip(
                    Icons.star_rounded,
                    Colors.amber.shade800,
                    '${trust.rating.toStringAsFixed(1)} Rating (${trust.reviewCount} reviews)',
                  ),
                ],
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildTrustChip(IconData icon, Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.badge_outlined),
          tooltip: 'View Skill Passport',
          onPressed: () {
            Navigator.pushNamed(
              context,
              AppRoutes.passport,
              arguments: widget.recommendation.mentorId,
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (val) {
            if (val == 'report') {
              _showReportDialog(context);
            } else if (val == 'block') {
              _showBlockDialog(context);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.report_outlined, size: 18, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Report Mentor'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block_outlined, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Block Mentor', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: widget.recommendation.skillImageUrl != null && widget.recommendation.skillImageUrl!.isNotEmpty
            ? Image.network(
                widget.recommendation.skillImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Theme.of(context).primaryColor.withOpacity(0.1)),
              )
            : Container(color: Theme.of(context).primaryColor.withOpacity(0.1)),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          transform: Matrix4.translationValues(0, -40, 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 4),
          ),
          child: CustomAvatar(
            radius: 40,
            imageUrl: widget.recommendation.mentorProfileImage,
            name: widget.recommendation.mentorName,
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.recommendation.mentorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
              Text(widget.recommendation.skillTitle, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, child) {
                  final reviewsAsync = ref.watch(userReviewsProvider(widget.recommendation.mentorId));
                  return reviewsAsync.maybeWhen(
                    data: (state) => Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                        Text(' ${state.stats.averageRating.toStringAsFixed(1)} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('(${state.stats.totalReviews} reviews)', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                    orElse: () => Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                        Text(' ${widget.recommendation.mentorRating ?? widget.recommendation.rating ?? 0.0} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('(${widget.recommendation.mentorReviewCount ?? 0} reviews)', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.chat_bubble_rounded, color: Theme.of(context).primaryColor),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConversationScreen(
                  chatId: widget.recommendation.skillId,
                  chat: ChatModel(
                    chatId: widget.recommendation.skillId, // For demo, assuming chat id correlates with skill id or something
                    mentorId: widget.recommendation.mentorId,
                    learnerId: 1, // Current User ID
                    partnerName: widget.recommendation.mentorName,
                    partnerAvatar: widget.recommendation.mentorProfileImage ?? '',
                    lastMessage: '',
                    lastMessageTime: DateTime.now().toIso8601String(),
                    unreadCount: 0,
                    createdAt: DateTime.now().toIso8601String(),
                    updatedAt: DateTime.now().toIso8601String(),
                  ),
                ),
              ),
            );
          },
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          ),
        ),
      ],
    ).animate().fade().slideY(begin: 0.1);
  }

  Widget _buildBioSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('About Skill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: AppConstants.paddingM),
        Text(
          widget.recommendation.skillDescription ?? '',
          style: const TextStyle(color: Colors.grey, height: 1.5),
        ),
      ],
    ).animate().fade().slideY(begin: 0.1, delay: 100.ms);
  }

  Widget _buildSkillsSection(BuildContext context) {
    final tags = widget.recommendation.skillCategory != null && widget.recommendation.skillCategory!.isNotEmpty
        ? [widget.recommendation.skillCategory!]
        : ['General'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: AppConstants.paddingM),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            return Chip(
              label: Text(tag),
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              labelStyle: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
              side: BorderSide.none,
            );
          }).toList(),
        ),
      ],
    ).animate().fade().slideY(begin: 0.1, delay: 200.ms);
  }

  Widget _buildReviewsSection(BuildContext context, AsyncValue<UserReviewState> reviewsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Reviews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: AppConstants.paddingM),
        reviewsAsync.when(
          data: (state) {
            if (state.reviews.isEmpty) {
              return const Text('No reviews yet. Be the first to review this mentor!');
            }
            return Column(
              children: state.reviews.map((review) {
                return Container(
                  margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CustomAvatar(radius: 12, imageUrl: review.reviewerImageUrl, name: review.reviewerName),
                              const SizedBox(width: 8),
                              Text(review.reviewerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            children: List.generate(5, (index) => Icon(
                              index < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: Colors.amber, size: 14,
                            )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(review.comment.isNotEmpty ? review.comment : 'No comment provided.', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => const Text('Failed to load reviews.'),
        ),
      ],
    ).animate().fade().slideY(begin: 0.1, delay: 300.ms);
  }
}
