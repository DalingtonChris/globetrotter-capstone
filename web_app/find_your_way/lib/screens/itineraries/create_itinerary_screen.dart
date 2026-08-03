import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/destination.dart';
import '../../services/api_client.dart';
import '../../services/destination_service.dart';
import '../../services/itinerary_service.dart';
import '../../state/auth_controller.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/destination_image.dart';
import '../../widgets/error_banner.dart';

class _SelectedDestination {
  final Destination destination;
  String note = '';

  _SelectedDestination(this.destination);
}

class CreateItineraryScreen extends StatefulWidget {
  final Destination? initialDestination;

  const CreateItineraryScreen({super.key, this.initialDestination});

  @override
  State<CreateItineraryScreen> createState() => _CreateItineraryScreenState();
}

class _CreateItineraryScreenState extends State<CreateItineraryScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateFormat = DateFormat('MMM d, yyyy');

  DateTime? _startDate;
  DateTime? _endDate;
  final List<_SelectedDestination> _selected = [];

  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialDestination != null) {
      _selected.add(_SelectedDestination(widget.initialDestination!));
      _titleController.text = 'Trip to ${widget.initialDestination!.name}';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _openDestinationPicker() async {
    final picked = await showModalBottomSheet<Destination>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DestinationPickerSheet(),
    );
    if (picked == null) return;
    if (_selected.any((s) => s.destination.id == picked.id)) return;
    setState(() => _selected.add(_SelectedDestination(picked)));
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'Please give your itinerary a title.');
      return;
    }
    if (_selected.isEmpty) {
      setState(() => _error = 'Add at least one destination.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final auth = context.read<AuthController>();
    final service = ItineraryService(context.read<ApiClient>());

    try {
      await service.create(
        auth.token!,
        title: _titleController.text.trim(),
        startDate: _startDate == null ? null : DateFormat('yyyy-MM-dd').format(_startDate!),
        endDate: _endDate == null ? null : DateFormat('yyyy-MM-dd').format(_endDate!),
        notes: _notesController.text.trim(),
        items: _selected
            .map((s) => {'destinationId': s.destination.id, 'note': s.note})
            .toList(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not reach the server. Is the API running?');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('New itinerary')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          AppTextField(
            label: 'Title',
            hint: 'e.g. Weekend in Yaoundé',
            icon: Icons.edit_note_rounded,
            controller: _titleController,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _DateField(label: 'Start date', date: _startDate, format: _dateFormat, onTap: () => _pickDate(isStart: true))),
              const SizedBox(width: 12),
              Expanded(child: _DateField(label: 'End date', date: _endDate, format: _dateFormat, onTap: () => _pickDate(isStart: false))),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Notes',
            hint: 'Anything you want to remember…',
            icon: Icons.sticky_note_2_outlined,
            controller: _notesController,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Destinations', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              TextButton.icon(
                onPressed: _openDestinationPicker,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_selected.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: const Text(
                'No destinations yet. Tap "Add" to build your trip.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            )
          else
            ..._selected.map(
              (s) => _SelectedDestinationTile(
                selected: s,
                onRemove: () => setState(() => _selected.remove(s)),
                onNoteChanged: (v) => s.note = v,
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            ErrorBanner(message: _error!),
          ],
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : const Text('Create itinerary'),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final DateFormat format;
  final VoidCallback onTap;

  const _DateField({required this.label, required this.date, required this.format, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 17, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Text(
                  date == null ? 'Select' : format.format(date!),
                  style: TextStyle(fontSize: 13.5, color: date == null ? AppColors.textMuted : AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectedDestinationTile extends StatelessWidget {
  final _SelectedDestination selected;
  final VoidCallback onRemove;
  final ValueChanged<String> onNoteChanged;

  const _SelectedDestinationTile({required this.selected, required this.onRemove, required this.onNoteChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 54,
              height: 54,
              child: DestinationImage(path: selected.destination.image, category: selected.destination.category),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(selected.destination.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                TextFormField(
                  initialValue: selected.note,
                  onChanged: onNoteChanged,
                  style: const TextStyle(fontSize: 12.5),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Add a note (optional)',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _DestinationPickerSheet extends StatefulWidget {
  const _DestinationPickerSheet();

  @override
  State<_DestinationPickerSheet> createState() => _DestinationPickerSheetState();
}

class _DestinationPickerSheetState extends State<_DestinationPickerSheet> {
  late final DestinationService _service = DestinationService(context.read<ApiClient>());
  List<Destination> _all = [];
  List<Destination> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await _service.search();
      if (!mounted) return;
      setState(() {
        _all = results;
        _filtered = results;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    final needle = query.trim().toLowerCase();
    setState(() {
      _filtered = needle.isEmpty
          ? _all
          : _all.where((d) => d.name.toLowerCase().contains(needle) || d.category.toLowerCase().contains(needle)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 42, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Add a destination', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: _onSearch,
                  decoration: const InputDecoration(
                    hintText: 'Search…',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final destination = _filtered[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 46,
                                height: 46,
                                child: DestinationImage(path: destination.image, category: destination.category),
                              ),
                            ),
                            title: Text(destination.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: Text(destination.category, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                            trailing: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                            onTap: () => Navigator.of(context).pop(destination),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
