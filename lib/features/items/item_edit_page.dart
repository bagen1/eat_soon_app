import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/items/item.dart';
import 'items_provider.dart';

class ItemEditPage extends ConsumerStatefulWidget {
  final Item? initialItem;

  const ItemEditPage({super.key, this.initialItem});

  @override
  ConsumerState<ItemEditPage> createState() => _ItemEditPageState();
}

class _ItemEditPageState extends ConsumerState<ItemEditPage> {
  // Form key used for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _nameController = TextEditingController();
  final _shelfLifeController = TextEditingController();

  // Date-related state
  DateTime? _bestBefore;
  DateTime? _openedAt;

  // Whether the item has been opened
  bool _useOpened = false;

  @override
  void dispose() {
    _nameController.dispose();
    _shelfLifeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    final item = widget.initialItem;
    if (item != null) {
      _nameController.text = item.name;
      _bestBefore = item.bestBefore;

      // If the item has opened-data, enable the section and prefill
      if (item.openedAt != null) {
        _useOpened = true;
        _openedAt = item.openedAt;
      }

      if(item.openShelfLifeDays != null){
        _shelfLifeController.text = item.openShelfLifeDays.toString();
      }
      else{
        _shelfLifeController.clear();
      }
    }
  }

  // Pick a "best before" date
  Future<void> _pickBestBefore() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _bestBefore ?? now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 10, 12, 31),
    );

    if (picked != null) {
      setState(() => _bestBefore = _dateOnly(picked));
    }
  }

  // Pick the date when the item was opened
  Future<void> _pickOpenedAt() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _openedAt ?? now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );

    if (picked != null) {
      setState(() => _openedAt = _dateOnly(picked));
    }
  }

  // Remove time-of-day information from a DateTime
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // Simple YYYY-MM-DD formatter (can be replaced with intl later)
  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // Validate input and save the item
  void _save() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    // If "opened" logic is enabled, we require both a date and a shelf life
    DateTime? openedAt;
    int? openShelfLifeDays;

  if (_useOpened) {
    openedAt = _openedAt;
    if (openedAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick an opened date.')),
      );
      return;
    }

    final s = _shelfLifeController.text.trim();
    openShelfLifeDays = s.isEmpty ? null : int.tryParse(s);

    if (s.isNotEmpty && (openShelfLifeDays == null || openShelfLifeDays <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shelf life must be a number greater than 0.')),
      );
      return;
    }
  }

    // Create the domain model.
    // If both "best before" and "opened" data exist,
    // the earliest expiry date will be used automatically.
    final item = Item(
      name: _nameController.text.trim(),
      bestBefore: _bestBefore,
      openedAt: openedAt,
      openShelfLifeDays: openShelfLifeDays,
    );

    final existing = widget.initialItem;

  if (existing == null) {
    // Create new
    ref.read(itemsProvider.notifier).add(item);
  } else {
    // Update existing (keep same id/createdAt)
    final updated = existing.copyWith(
      name: item.name,
      bestBefore: item.bestBefore,
      openedAt: item.openedAt,
      openShelfLifeDays: item.openShelfLifeDays,
      clearBestBefore: item.bestBefore == null,
      clearOpened: item.openedAt == null,
      clearShelfLife: item.openShelfLifeDays == null,
    );

    ref.read(itemsProvider.notifier).update(updated);
  }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final openedEnabled = _useOpened;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialItem == null ? 'Add item' : 'Edit item'),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check),
            tooltip: 'Save',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Item name
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Potato gratin',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return 'Please enter a name';
                if (s.length < 2) return 'Name is too short';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Best before date (optional)
            _DateRow(
              label: 'Best before (optional)',
              value:
                  _bestBefore == null ? null : _formatDate(_bestBefore!),
              onPick: _pickBestBefore,
              onClear: _bestBefore == null
                  ? null
                  : () => setState(() => _bestBefore = null),
            ),

            const SizedBox(height: 16),

            // Toggle: item has been opened
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Item has been opened'),
              subtitle: const Text(
                'Calculate expiry from the opening date',
              ),
              value: _useOpened,
              onChanged: (v) {
                setState(() {
                  _useOpened = v;
                  if (!v) {
                    _openedAt = null;
                    _shelfLifeController.clear();
                  }
                });
              },
            ),

            const SizedBox(height: 8),

            // Opened date
            IgnorePointer(
              ignoring: !openedEnabled,
              child: Opacity(
                opacity: openedEnabled ? 1 : 0.5,
                child: _DateRow(
                  label: 'Opened date',
                  value: _openedAt == null
                      ? null
                      : _formatDate(_openedAt!),
                  onPick: _pickOpenedAt,
                  onClear: _openedAt == null
                      ? null
                      : () => setState(() => _openedAt = null),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Shelf life in days after opening
            IgnorePointer(
              ignoring: !openedEnabled,
              child: Opacity(
                opacity: openedEnabled ? 1 : 0.5,
                child: TextFormField(
                  controller: _shelfLifeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Shelf life after opening (days, optional)',
                    hintText: 'e.g. 7 (leave empty to only track days opened)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (!_useOpened) return null;

                    final s = (v ?? '').trim();
                    if (s.isEmpty) return null; // optional now

                    final n = int.tryParse(s);
                    if (n == null) return 'Enter a whole number';
                    if (n <= 0) return 'Must be greater than 0';
                    return null;
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save item'),
            ),

            const SizedBox(height: 8),

            const Text(
              'Tip: You can enter both a "best before" date and '
              'an opened date with shelf life. The earliest expiry '
              'will be used.',
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const _DateRow({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onClear != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                  tooltip: 'Clear',
                ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: onPick,
                tooltip: 'Pick date',
              ),
            ],
          ),
        ),
        child: Text(value ?? 'Select date'),
      ),
    );
  }
}
