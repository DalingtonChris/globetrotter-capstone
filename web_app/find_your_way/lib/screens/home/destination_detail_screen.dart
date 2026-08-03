import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/destination.dart';
import '../../services/api_client.dart';
import '../../services/destination_service.dart';
import '../../widgets/destination_image.dart';
import '../itineraries/create_itinerary_screen.dart';

class DestinationDetailScreen extends StatefulWidget {
  final String destinationId;

  const DestinationDetailScreen({super.key, required this.destinationId});

  @override
  State<DestinationDetailScreen> createState() => _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  late final DestinationService _service = DestinationService(context.read<ApiClient>());
  Destination? _destination;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final destination = await _service.getById(widget.destinationId);
      if (mounted) setState(() => _destination = destination);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load this destination.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.background),
        backgroundColor: AppColors.background,
        body: Center(child: Text(_error!)),
      );
    }

    final destination = _destination;
    if (destination == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _CircleButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).pop()),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  DestinationImage(path: destination.image, category: destination.category),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
              ),
              transform: Matrix4.translationValues(0, -20, 0),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          destination.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
                            const SizedBox(width: 3),
                            Text(
                              destination.rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(destination.location, style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
                      const SizedBox(width: 14),
                      const Icon(Icons.local_offer_rounded, size: 15, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(destination.category, style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
                      if (destination.priceLevel > 0) ...[
                        const SizedBox(width: 14),
                        Text(
                          destination.priceLabel,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                    destination.description,
                    style: const TextStyle(fontSize: 14, height: 1.55, color: AppColors.textSecondary),
                  ),
                  if (destination.tags.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const Text('Highlights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: destination.tags
                          .map((tag) => Chip(label: Text(tag), backgroundColor: AppColors.surface))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CreateItineraryScreen(initialDestination: destination)),
              );
            },
            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
            label: const Text('Add to an itinerary'),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
