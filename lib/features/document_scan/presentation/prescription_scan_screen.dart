import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/enums.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../medicine/domain/medicine.dart';
import '../../medicine/presentation/medicine_providers.dart';
import '../domain/scan_models.dart';
import 'document_picker.dart';
import 'scan_providers.dart';

/// Scan a doctor's prescription (photo or PDF) and let the AI extract the
/// medicines and timings. The mother **reviews and edits** everything before it
/// is added to her medicine tracker — nothing is saved automatically.
class PrescriptionScanScreen extends ConsumerStatefulWidget {
  const PrescriptionScanScreen({super.key});

  @override
  ConsumerState<PrescriptionScanScreen> createState() =>
      _PrescriptionScanScreenState();
}

class _PrescriptionScanScreenState
    extends ConsumerState<PrescriptionScanScreen> {
  static const _uuid = Uuid();

  bool _busy = false;
  String? _error;
  List<String> _warnings = const [];
  List<_EditableMed> _meds = [];
  bool _scanned = false;

  Future<void> _pickAndScan() async {
    final doc = await DocumentPicker.pick(context);
    if (doc == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(documentAiRepositoryProvider)
          .scanPrescription(bytes: doc.bytes, mimeType: doc.mimeType);

      // Keep the original scan on the device + record it in local history.
      final id = _uuid.v4();
      final path = await ref.read(localScanStoreProvider).saveImage(
            id: id,
            bytes: doc.bytes,
            extension: doc.extension,
          );
      await ref.read(localScanStoreProvider).addRecord(ScanRecord(
            id: id,
            type: 'prescription',
            createdAt: DateTime.now(),
            imagePath: path,
            title: 'Prescription',
            summary: '${result.medicines.length} medicine(s) found',
          ));
      ref.invalidate(scanHistoryProvider);

      if (!mounted) return;
      setState(() {
        _scanned = true;
        _warnings = result.warnings;
        _meds = result.medicines.map(_EditableMed.from).toList();
        if (!result.isPrescription) {
          _error = 'That doesn\'t look like a prescription. Try a clearer photo '
              'of the medicines section.';
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = _msg(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _msg(Object e) =>
      e is StateError ? e.message : 'Could not read the prescription.';

  Future<void> _addSelected() async {
    final actions = ref.read(medicineActionsProvider);
    if (actions == null) {
      context.showSnack('Your pregnancy isn\'t set up yet.', isError: true);
      return;
    }
    final selected = _meds.where((m) => m.include).toList();
    if (selected.isEmpty) {
      context.showSnack('Select at least one medicine to add.', isError: true);
      return;
    }
    setState(() => _busy = true);
    try {
      for (final m in selected) {
        final med = m.toMedicine(_uuid.v4());
        await actions.save(med);
      }
      if (mounted) {
        context.showSnack('${selected.length} medicine(s) added to your tracker.');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        context.showSnack('Could not add the medicines.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan prescription')),
      body: _busy && !_scanned
          ? const LoadingView(message: 'Reading your prescription…')
          : _scanned
              ? _buildReview()
              : _buildIntro(),
    );
  }

  Widget _buildIntro() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          color: context.colors.primaryContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.document_scanner_outlined,
                  size: 40, color: context.colors.onPrimaryContainer),
              const SizedBox(height: AppSpacing.sm),
              Text('Scan a prescription',
                  style: context.textStyles.titleLarge
                      ?.copyWith(color: context.colors.onPrimaryContainer)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Take a photo or pick a PDF of your prescription. We\'ll read the '
                'medicines and suggested timings so you can review and add them.',
                style: context.textStyles.bodyMedium
                    ?.copyWith(color: context.colors.onPrimaryContainer),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_error != null) ...[
          _ErrorNote(_error!),
          const SizedBox(height: AppSpacing.lg),
        ],
        AppButton(
          label: 'Choose prescription',
          icon: Icons.add_a_photo_outlined,
          onPressed: _pickAndScan,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Always double-check names, doses and timings against the paper '
          'prescription. This is a reading aid, not medical advice.',
          style: context.textStyles.bodySmall
              ?.copyWith(color: context.colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildReview() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (_error != null) ...[
                _ErrorNote(_error!),
                const SizedBox(height: AppSpacing.md),
              ],
              if (_warnings.isNotEmpty) ...[
                AppCard(
                  color: context.colors.tertiaryContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.info_outline,
                            size: 18,
                            color: context.colors.onTertiaryContainer),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Please double-check',
                            style: context.textStyles.titleSmall?.copyWith(
                                color: context.colors.onTertiaryContainer)),
                      ]),
                      const SizedBox(height: AppSpacing.xs),
                      for (final w in _warnings)
                        Text('• $w',
                            style: context.textStyles.bodySmall?.copyWith(
                                color: context.colors.onTertiaryContainer)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text('Review the medicines',
                  style: context.textStyles.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text('Tick the ones to add, and edit anything that looks off.',
                  style: context.textStyles.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.md),
              if (_meds.isEmpty)
                const EmptyState(
                  icon: Icons.medication_outlined,
                  title: 'No medicines found',
                  message: 'Try a clearer photo of the prescription.',
                )
              else
                for (var i = 0; i < _meds.length; i++)
                  _MedCard(
                    med: _meds[i],
                    onChanged: () => setState(() {}),
                  ),
            ],
          ),
        ),
        if (_meds.isNotEmpty)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton(
                label:
                    'Add ${_meds.where((m) => m.include).length} to my medicines',
                icon: Icons.check,
                isLoading: _busy,
                onPressed: _busy ? () {} : _addSelected,
              ),
            ),
          ),
      ],
    );
  }
}

/// Editable working copy of an extracted medicine.
class _EditableMed {
  _EditableMed({
    required this.name,
    required this.dosage,
    required this.times,
    required this.timing,
    required this.durationDays,
    required this.instructions,
  });

  final TextEditingController name;
  final TextEditingController dosage;
  final TextEditingController times; // comma-separated HH:mm
  MedicineTiming timing;
  final int? durationDays;
  final String instructions;
  bool include = true;

  factory _EditableMed.from(ExtractedMedicine e) => _EditableMed(
        name: TextEditingController(text: e.name),
        dosage: TextEditingController(text: e.dosage),
        times: TextEditingController(text: e.suggestedTimes.join(', ')),
        timing: e.timing,
        durationDays: e.durationDays,
        instructions: e.instructions,
      );

  List<String> get parsedTimes => times.text
      .split(',')
      .map((s) => s.trim())
      .where(isValidTime)
      .toList();

  Medicine toMedicine(String id) {
    final start = DateTime.now();
    final t = parsedTimes;
    return Medicine(
      id: id,
      name: name.text.trim().isEmpty ? 'Medicine' : name.text.trim(),
      dosage: dosage.text.trim(),
      timing: timing,
      times: t.isEmpty ? const ['09:00'] : t,
      startDate: start,
      endDate: durationDays != null && durationDays! > 0
          ? start.add(Duration(days: durationDays!))
          : null,
      notes: instructions.isEmpty ? null : instructions,
    );
  }
}

class _MedCard extends StatelessWidget {
  const _MedCard({required this.med, required this.onChanged});
  final _EditableMed med;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: med.include,
                  onChanged: (v) {
                    med.include = v ?? false;
                    onChanged();
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: med.name,
                    decoration: const InputDecoration(
                      labelText: 'Medicine name',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: med.dosage,
              decoration: const InputDecoration(
                labelText: 'Dosage (e.g. 1 tablet, 5 ml)',
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: med.times,
              decoration: const InputDecoration(
                labelText: 'Times (24h, comma-separated)',
                helperText: 'Reminders will be set for these times',
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<MedicineTiming>(
              initialValue: med.timing,
              decoration:
                  const InputDecoration(labelText: 'Timing', isDense: true),
              items: const [
                DropdownMenuItem(
                    value: MedicineTiming.beforeFood,
                    child: Text('Before food')),
                DropdownMenuItem(
                    value: MedicineTiming.afterFood, child: Text('After food')),
                DropdownMenuItem(
                    value: MedicineTiming.anytime, child: Text('Anytime')),
              ],
              onChanged: (v) {
                if (v != null) {
                  med.timing = v;
                  onChanged();
                }
              },
            ),
            if (med.instructions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Note: ${med.instructions}',
                  style: context.textStyles.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: context.colors.errorContainer,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: context.colors.onErrorContainer),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(message,
                style: context.textStyles.bodyMedium
                    ?.copyWith(color: context.colors.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}
