import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/itinerary.dart';
import '../../services/api_client.dart';
import '../../services/itinerary_service.dart';
import '../../state/auth_controller.dart';
import '../../widgets/destination_image.dart';
import '../../widgets/error_banner.dart';

class ItineraryDetailScreen extends StatefulWidget {
  final Itinerary itinerary;

  const ItineraryDetailScreen({super.key, required this.itinerary});

  @override
  State<ItineraryDetailScreen> createState() => _ItineraryDetailScreenState();
}

class _ItineraryDetailScreenState extends State<ItineraryDetailScreen> {
  bool _isDeleting = false;
  String? _error;

  String _formatDate(String? raw) {
    if (raw == null) return '—';
    return DateFormat('MMM d, yyyy').format(DateTime.parse(raw));
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete this trip?'),
        content: Text('"${widget.itinerary.title}" will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() {
      _isDeleting = true;
      _error = null;
    });

    final auth = context.read<AuthController>();
    final service = ItineraryService(context.read<ApiClient>());

    try {
      await service.remove(auth.token!, widget.itinerary.id);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not reach the server. Is the API running?');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itinerary = widget.itinerary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(itinerary.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: _isDeleting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error))
                : const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: _isDeleting ? null : _confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          if (_error != null) ...[
            ErrorBanner(message: _error!),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dates', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(itinerary.startDate)}  →  ${_formatDate(itinerary.endDate)}',
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    '${itinerary.items.length} stop${itinerary.items.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          if (itinerary.notes.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text('Notes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(itinerary.notes, style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5)),
          ],
          const SizedBox(height: 22),
          const Text('Itinerary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...itinerary.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _TimelineTile(
              index: index + 1,
              isLast: index == itinerary.items.length - 1,
              name: item.destination?.name ?? 'Unknown destination',
              category: item.destination?.category ?? '',
              image: item.destination?.image,
              note: item.note,
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final int index;
  final bool isLast;
  final String name;
  final String category;
  final String? image;
  final String note;

  const _TimelineTile({
    required this.index,
    required this.isLast,
    required this.name,
    required this.category,
    required this.image,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('$index', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: AppColors.border)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(width: 52, height: 52, child: DestinationImage(path: image, category: category)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          if (category.isNotEmpty) Text(category, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          if (note.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(note, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
