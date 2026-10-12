import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../repositories/skill_repository.dart';
import '../../models/recommendation_model.dart';
import 'mentor_profile_screen.dart';

class AiMatchScreen extends ConsumerStatefulWidget {
  const AiMatchScreen({super.key});

  @override
  ConsumerState<AiMatchScreen> createState() => _AiMatchScreenState();
}

class _AiMatchScreenState extends ConsumerState<AiMatchScreen> {
  final List<String> _chatMessages = [
    "Hi there! I'm your AI Matchmaker. What kind of skill are you looking to learn or teach today?",
  ];
  final TextEditingController _textController = TextEditingController();
  bool _isTyping = false;
  bool _hasError = false;
  bool _showSuggestions = false;
  List<RecommendationModel> _matchedSkills = [];

  final List<String> _quickChips = [
    "I want to learn Flutter",
    "I can teach UI Design",
    "Help me find a Spanish tutor",
    "Looking for a Python expert"
  ];

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    setState(() {
      _chatMessages.add("USER:$message");
      _isTyping = true;
      _textController.clear();
      _showSuggestions = false;
    });
    try {
      // Call recommendations endpoint
      final recs = await ref.read(skillRepositoryProvider).getRecommendations();
      if (mounted) {
        setState(() {
          _isTyping = false;
          if (recs.isNotEmpty) {
            _matchedSkills = recs.take(3).toList();
            _chatMessages.add("I found some amazing matches for you based on your request. Check out these mentors below!");
            _showSuggestions = true;
          } else {
            _chatMessages.add("I couldn't find any direct matches for that right now. Try adjusting your request or browse the categories!");
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _hasError = true;
          _chatMessages.add("Oops, I encountered an error while searching.");
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('AI Matchmaker'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Error state UI
          if (_hasError) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    const Text('Failed to fetch matches. Please try again.'),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Retry',
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                itemCount: _chatMessages.length + (_isTyping ? 1 : 0) + (_showSuggestions ? _matchedSkills.length : 0),
                itemBuilder: (context, index) {
                  if (index < _chatMessages.length) {
                    final msg = _chatMessages[index];
                    final isUser = msg.startsWith("USER:");
                    return _buildChatBubble(isUser ? msg.substring(5) : msg, isUser);
                  } else if (_isTyping && index == _chatMessages.length) {
                    return _buildTypingIndicator();
                  } else {
                    final recIdx = index - _chatMessages.length - (_isTyping ? 1 : 0);
                    return _buildRecommendationCard(_matchedSkills[recIdx]);
                  }
                },
              ),
            ),
          ],
          
          if (!_showSuggestions && !_isTyping)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
                itemCount: _quickChips.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(_quickChips[index]),
                      onPressed: () => _sendMessage(_quickChips[index]),
                      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      side: BorderSide.none,
                    ),
                  );
                },
              ),
            ).animate().fade().slideY(begin: 0.2),
            
          const SizedBox(height: AppConstants.paddingM),
          
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
        padding: const EdgeInsets.all(AppConstants.paddingM),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).primaryColor : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ).animate().fade().scale(alignment: isUser ? Alignment.bottomRight : Alignment.bottomLeft),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
        padding: const EdgeInsets.all(AppConstants.paddingM),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.circle, size: 8, color: Colors.grey).animate(onPlay: (c) => c.repeat()).fade(duration: 400.ms),
            const SizedBox(width: 4),
            const Icon(Icons.circle, size: 8, color: Colors.grey).animate(onPlay: (c) => c.repeat()).fade(delay: 200.ms, duration: 400.ms),
            const SizedBox(width: 4),
            const Icon(Icons.circle, size: 8, color: Colors.grey).animate(onPlay: (c) => c.repeat()).fade(delay: 400.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(RecommendationModel rec) {
    return Container(
      margin: const EdgeInsets.only(top: AppConstants.paddingS, bottom: AppConstants.paddingL),
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor.withValues(alpha: 0.1), Colors.purple.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_rounded, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Match Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: AppConstants.paddingM),
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingS),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CustomAvatar(
                  radius: 32,
                  imageUrl: rec.mentorProfileImage,
                  name: rec.mentorName,
                ),
                const SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rec.mentorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(rec.skillTitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          Text(' ${rec.mentorRating ?? 0}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Score: ${rec.matchScore}', style: const TextStyle(fontSize: 12)),
                      Text('Explanation: ${rec.explanation}', style: const TextStyle(fontSize: 12)),
                      if (rec.distanceKm != null)
                        Text('Distance: ${rec.distanceKm?.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                CustomButton(
                  text: 'Connect',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MentorProfileScreen(recommendation: rec)),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade().slideY(begin: 0.2);
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM, vertical: AppConstants.paddingS),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: () => _sendMessage(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
