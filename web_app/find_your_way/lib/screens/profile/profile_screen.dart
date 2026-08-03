import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../services/api_client.dart';
import '../../services/destination_service.dart';
import '../../state/auth_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final DestinationService _destinationService = DestinationService(context.read<ApiClient>());
  List<String> _categories = [];
  Set<String> _selected = {};
  bool _isSaving = false;
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_bootstrapped) {
      _bootstrapped = true;
      _selected = context.read<AuthController>().user?.preferences.toSet() ?? {};
      _loadCategories();
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _destinationService.categories();
      if (mounted) setState(() => _categories = categories);
    } catch (_) {
      // Preference editor simply stays empty if categories can't be fetched.
    }
  }

  Future<void> _toggle(String category) async {
    setState(() {
      if (_selected.contains(category)) {
        _selected.remove(category);
      } else {
        _selected.add(category);
      }
    });

    setState(() => _isSaving = true);
    try {
      await context.read<AuthController>().updatePreferences(_selected.toList());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save preferences right now.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Log out?'),
        content: const Text('You can always log back in to see your trips.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthController>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(gradient: AppColors.heroGradient, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    (user?.name.isNotEmpty == true ? user!.name[0] : '?').toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 14),
                Text(user?.name ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(user?.email ?? '', style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Text('Travel interests', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(width: 8),
              if (_isSaving)
                const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Pick categories you love — we\'ll tailor your recommendations.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _categories.map((category) {
              final isSelected = _selected.contains(category);
              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (_) => _toggle(category),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 36),
          OutlinedButton.icon(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
            label: const Text('Log out', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text('Find Your Way · Phase 1 Monolith', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}
