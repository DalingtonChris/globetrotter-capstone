import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/itinerary.dart';
import '../../services/api_client.dart';
import '../../services/itinerary_service.dart';
import '../../state/auth_controller.dart';
import '../../widgets/destination_image.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import 'create_itinerary_screen.dart';
import 'itinerary_detail_screen.dart';

class ItinerariesScreen extends StatefulWidget {
  const ItinerariesScreen({super.key});

  @override
  State<ItinerariesScreen> createState() => _ItinerariesScreenState();
}

class _ItinerariesScreenState extends State<ItinerariesScreen> {
  late final ItineraryService _service = ItineraryService(context.read<ApiClient>());
  List<Itinerary> _itineraries = [];
  bool _isLoading = true;
  String? _error;
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_bootstrapped) {
      _bootstrapped = true;
      _load();
    }
  }

  Future<void> _load() async {
    final token = context.read<AuthController>().token;
    if (token == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await _service.list(token);
      if (!mounted) return;
      setState(() => _itineraries = results);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not reach the server. Is the API running?');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateItineraryScreen()),
    );
    if (created == true) _load();
  }

  Future<void> _openDetail(Itinerary itinerary) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ItineraryDetailScreen(itinerary: itinerary)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: _openCreate),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New trip'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [ErrorBanner(message: _error!)],
      );
    }
    if (_itineraries.isEmpty) {
      return ListView(
        children: [
          EmptyState(
            icon: Icons.card_travel_rounded,
            title: 'No trips yet',
            message: 'Start planning by adding a destination to a new itinerary.',
            action: ElevatedButton(onPressed: _openCreate, child: const Text('Plan a trip')),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _itineraries.length,
      itemBuilder: (context, index) {
        final itinerary = _itineraries[index];
        return _ItineraryCard(itinerary: itinerary, onTap: () => _openDetail(itinerary));
      },
    );
  }
}

class _ItineraryCard extends StatelessWidget {
  final Itinerary itinerary;
  final VoidCallback onTap;

  const _ItineraryCard({required this.itinerary, required this.onTap});

  String get _dateRange {
    final format = DateFormat('MMM d');
    if (itinerary.startDate == null) return 'Dates not set';
    final start = format.format(DateTime.parse(itinerary.startDate!));
    if (itinerary.endDate == null) return start;
    final end = format.format(DateTime.parse(itinerary.endDate!));
    return '$start – $end';
  }

  @override
  Widget build(BuildContext context) {
    final preview = itinerary.items.take(3).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(itinerary.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 5),
                  Text(_dateRange, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  const SizedBox(width: 14),
                  const Icon(Icons.place_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text('${itinerary.items.length} stop${itinerary.items.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    ...preview.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: DestinationImage(
                              path: item.destination?.image,
                              category: item.destination?.category ?? 'Landmark',
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (itinerary.items.length > preview.length)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.center,
                        child: Text('+${itinerary.items.length - preview.length}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
