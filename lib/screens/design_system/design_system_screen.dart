import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';

class DesignSystemScreen extends StatelessWidget {
  const DesignSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {}, // Theme toggle will be managed globally
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        children: [
          _buildSectionTitle(context, 'Typography'),
          Text('Display Large', style: Theme.of(context).textTheme.displayLarge),
          Text('Headline Large', style: Theme.of(context).textTheme.headlineLarge),
          Text('Title Large', style: Theme.of(context).textTheme.titleLarge),
          Text('Body Large', style: Theme.of(context).textTheme.bodyLarge),
          Text('Body Medium', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppConstants.paddingL),

          _buildSectionTitle(context, 'Colors'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildColorBox('Primary', AppColors.primary),
              _buildColorBox('Secondary', AppColors.secondary),
              _buildColorBox('Accent', AppColors.accent),
              _buildColorBox('Success', AppColors.success),
              _buildColorBox('Error', AppColors.error),
            ],
          ),
          const SizedBox(height: AppConstants.paddingL),

          _buildSectionTitle(context, 'Buttons'),
          CustomButton(text: 'Primary Button', onPressed: () {}),
          const SizedBox(height: 8),
          CustomButton(text: 'Secondary Button', type: ButtonType.secondary, onPressed: () {}),
          const SizedBox(height: 8),
          CustomButton(text: 'Outlined Button', type: ButtonType.outlined, onPressed: () {}),
          const SizedBox(height: 8),
          CustomButton(text: 'Loading Button', isLoading: true, onPressed: () {}),
          const SizedBox(height: AppConstants.paddingL),

          _buildSectionTitle(context, 'Inputs'),
          CustomTextField(
            label: 'Email Address',
            hint: 'Enter your email',
            prefixIcon: Icons.email_outlined,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Password',
            hint: 'Enter your password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: AppConstants.paddingL),
          
          _buildSectionTitle(context, 'Cards'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Card Title', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('This is a sample card utilizing the global CardTheme.', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.primary)),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildColorBox(String name, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
            ]
          ),
        ),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
