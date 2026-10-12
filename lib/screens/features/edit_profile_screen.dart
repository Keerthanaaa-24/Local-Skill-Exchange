import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/profile_models.dart';
import '../../providers/profile_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/skill_picker_modal.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  late TextEditingController _avatarUrlController;
  late TextEditingController _latController;
  late TextEditingController _lngController;

  List<String> _skillsOffered = [];
  List<String> _skillsWanted = [];
  bool _isLoading = false;

  final List<String> _avatarPresets = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
  ];

  @override
  void initState() {
    super.initState();
    final profileState = ref.read(profileProvider);
    final profile = profileState.value;

    _nameController = TextEditingController(text: profile?.name ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _avatarUrlController = TextEditingController(text: profile?.profileImageUrl ?? '');
    _latController = TextEditingController(text: profile?.lat != null ? profile!.lat.toString() : '');
    _lngController = TextEditingController(text: profile?.lng != null ? profile!.lng.toString() : '');

    _skillsOffered = List.from(profile?.skills ?? []);
    _skillsWanted = List.from(profile?.wantedSkills ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _avatarUrlController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final latVal = double.tryParse(_latController.text.trim());
        final lngVal = double.tryParse(_lngController.text.trim());

        final request = UpdateProfileRequest(
          name: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
          avatarUrl: _avatarUrlController.text.trim().isNotEmpty ? _avatarUrlController.text.trim() : null,
          skills: _skillsOffered,
          wantedSkills: _skillsWanted,
          lat: latVal,
          lng: lngVal,
        );

        await ref.read(profileProvider.notifier).updateProfile(request);
        // Refresh user provider for home / explore sync
        ref.invalidate(userProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Profile updated successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _openSkillPickerForOffered() async {
    final selected = await SkillPickerModal.show(
      context,
      title: 'Add Skill You Can Teach',
      alreadySelectedSkills: _skillsOffered,
    );
    if (selected != null && selected.isNotEmpty && !_skillsOffered.contains(selected)) {
      setState(() {
        _skillsOffered.add(selected);
      });
    }
  }

  void _openSkillPickerForWanted() async {
    final selected = await SkillPickerModal.show(
      context,
      title: 'Add Skill You Want to Learn',
      alreadySelectedSkills: _skillsWanted,
    );
    if (selected != null && selected.isNotEmpty && !_skillsWanted.contains(selected)) {
      setState(() {
        _skillsWanted.add(selected);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Save Changes',
            onPressed: _isLoading ? null : _onSave,
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Avatar Preview & Presets
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: primaryColor.withAlpha(30),
                        backgroundImage: _avatarUrlController.text.isNotEmpty
                            ? NetworkImage(_avatarUrlController.text)
                            : null,
                        child: _avatarUrlController.text.isEmpty
                            ? Icon(Icons.person, size: 50, color: primaryColor)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Select Avatar Preset',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _avatarPresets.map((url) {
                    final isSelected = _avatarUrlController.text == url;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _avatarUrlController.text = url;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: primaryColor, width: 2.5) : null,
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(url),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppConstants.paddingL),

                // Name & Bio
                CustomTextField(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline,
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: AppConstants.paddingM),
                CustomTextField(
                  label: 'Headline / Bio',
                  hint: 'e.g. Full-Stack Developer | Guitar Enthusiast',
                  controller: _bioController,
                  prefixIcon: Icons.info_outline_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: AppConstants.paddingM),
                CustomTextField(
                  label: 'Phone Number (Optional)',
                  hint: 'Enter your phone number',
                  controller: _phoneController,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppConstants.paddingL),

                // Location Coordinates
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Latitude (Optional)',
                        hint: 'e.g. 12.9716',
                        controller: _latController,
                        prefixIcon: Icons.location_on_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingM),
                    Expanded(
                      child: CustomTextField(
                        label: 'Longitude (Optional)',
                        hint: 'e.g. 77.5946',
                        controller: _lngController,
                        prefixIcon: Icons.map_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingL),

                // Skills I Can Teach Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Skills I Can Teach (${_skillsOffered.length})',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: _openSkillPickerForOffered,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Browse Skills'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (_skillsOffered.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha(15),
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                    child: Center(
                      child: Text(
                        'No teaching skills added yet. Tap "Browse Skills" to select from 1,500+ skills.',
                        style: TextStyle(color: primaryColor, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _skillsOffered.map((skill) {
                      return Chip(
                        label: Text(skill),
                        avatar: CircleAvatar(
                          backgroundColor: primaryColor,
                          child: const Icon(Icons.school, size: 12, color: Colors.white),
                        ),
                        onDeleted: () {
                          setState(() {
                            _skillsOffered.remove(skill);
                          });
                        },
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        backgroundColor: primaryColor.withAlpha(25),
                        labelStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                const SizedBox(height: AppConstants.paddingL),

                // Skills I Want to Learn Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Skills I Want to Learn (${_skillsWanted.length})',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: _openSkillPickerForWanted,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Browse Skills'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (_skillsWanted.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(15),
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                    child: const Center(
                      child: Text(
                        'No learning goals added yet. Tap "Browse Skills" to select what you want to learn.',
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _skillsWanted.map((skill) {
                      return Chip(
                        label: Text(skill),
                        avatar: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.lightbulb_outline, size: 12, color: Colors.white),
                        ),
                        onDeleted: () {
                          setState(() {
                            _skillsWanted.remove(skill);
                          });
                        },
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        backgroundColor: Colors.orange.withAlpha(25),
                        labelStyle: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),

                const SizedBox(height: AppConstants.paddingXL),
                CustomButton(
                  text: 'Save Profile Changes',
                  isLoading: _isLoading,
                  onPressed: _onSave,
                ),
                const SizedBox(height: AppConstants.paddingL),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
