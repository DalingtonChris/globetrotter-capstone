import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/destination.dart';
import '../../services/api_client.dart';
import '../../services/destination_service.dart';
import '../../state/auth_controller.dart';
import '../../widgets/destination_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import 'destination_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final DestinationService _service = DestinationService(context.read<ApiClient>());
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<String> _categories = const ['All'];
  String _selectedCategory = 'All';

  List<Destination> _destinations = [];
  List<Destination> _recommendations = [];

  bool _isLoadingDestinations = true;
  bool _isLoadingRecommendations = true;
  String? _error;

  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_bootstrapped) {
      _bootstrapped = true;
      _loadCategories();
      _loadDestinations();
      _loadRecommendations();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _service.categories();
      if (!mounted) return;
      setState(() => _categories = ['All', ...categories]);
    } catch (_) {
      // Non-critical: filters simply fall back to "All" only.
    }
  }

  Future<void> _loadDestinations() async {
    setState(() {
      _isLoadingDestinations = true;
      _error = null;
    });
    try {
      final results = await _service.search(
        query: _searchController.text.trim(),
        category: _selectedCategory,
      );
      if (!mounted) return;
      setState(() => _destinations = results);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not reach the server. Is the API running?');
    } finally {
      if (mounted) setState(() => _isLoadingDestinations = false);
    }
  }

  Future<void> _loadRecommendations() async {
    final token = context.read<AuthController>().token;
    setState(() => _isLoadingRecommendations = true);
    try {
      final results = await _service.recommendations(token: token, limit: 6);
      if (!mounted) return;
      setState(() => _recommendations = results);
    } catch (_) {
      // Recommendations are a bonus section; fail silently and just hide it.
    } finally {
      if (mounted) setState(() => _isLoadingRecommendations = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _loadDestinations);
  }

  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
    _loadDestinations();
  }

  void _openDestination(Destination destination) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DestinationDetailScreen(destinationId: destination.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthController>().user?.name.split(' ').first;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await Future.wait([_loadDestinations(), _loadRecommendations()]);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(userName: userName, searchController: _searchController, onSearchChanged: _onSearchChanged)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: _CategoryChips(
                categories: _categories,
                selected: _selectedCategory,
                onSelected: _onCategorySelected,
              ),
            ),
          ),
          if (_isLoadingRecommendations || _recommendations.isNotEmpty)
            SliverToBoxAdapter(
              child: _RecommendationsSection(
                isLoading: _isLoadingRecommendations,
                destinations: _recommendations,
                onTap: _openDestination,
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            sliver: SliverToBoxAdapter(
              child: Text(
                _selectedCategory == 'All' ? 'All destinations' : _selectedCategory,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
          ),
          if (_error != null)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              sliver: SliverToBoxAdapter(child: ErrorBanner(message: _error!)),
            )
          else if (_isLoadingDestinations)
            const SliverPadding(
              padding: EdgeInsets.only(top: 60),
              sliver: SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
            )
          else if (_destinations.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.travel_explore_rounded,
                title: 'No destinations found',
                message: 'Try a different search term or category.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final destination = _destinations[index];
                    return DestinationCard(destination: destination, onTap: () => _openDestination(destination));
                  },
                  childCount: _destinations.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String? userName;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const _Header({required this.userName, required this.searchController, required this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName != null ? 'Hi $userName 👋' : 'Welcome 👋',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            const Text(
              'Where to next?',
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: const TextStyle(fontSize: 14.5),
                decoration: const InputDecoration(
                  hintText: 'Search destinations, hotels, food…',
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryChips({required this.categories, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selected;
          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) => onSelected(category),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

class _RecommendationsSection extends StatelessWidget {
  final bool isLoading;
  final List<Destination> destinations;
  final ValueChanged<Destination> onTap;

  const _RecommendationsSection({required this.isLoading, required this.destinations, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: const [
                Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.accent),
                SizedBox(width: 6),
                Text(
                  'Recommended for you',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 210,
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: destinations.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final destination = destinations[index];
                      return SizedBox(
                        width: 160,
                        child: DestinationCard(destination: destination, onTap: () => onTap(destination)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
