import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../profile/presentation/controllers/profile_providers.dart';
import '../domain/photo_entry.dart';
import 'memory_providers.dart';
import 'photo_picker.dart';

/// A private, on-device photo timeline — "Memories". The user adds a picture at
/// any point in the pregnancy (a bump photo, a scan snapshot, a moment), tags it
/// with a date, week and note, and the screen tracks them all as a timeline
/// grouped by month. Everything stays on this phone.
class MemoriesScreen extends ConsumerWidget {
  const MemoriesScreen({super.key});

  static const _uuid = Uuid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(memoryPhotosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memories'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Add photo or video'),
      ),
      body: photosAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => EmptyState(
          title: 'Couldn\'t load memories',
          message: '$e',
          icon: Icons.broken_image_outlined,
        ),
        data: (photos) {
          if (photos.isEmpty) {
            return EmptyState(
              title: 'Capture your journey',
              message:
                  'Add bump photos and special moments over time — they stay '
                  'private on this device.',
              icon: Icons.photo_camera_back_outlined,
              actionLabel: 'Add your first photo',
              onAction: () => _add(context, ref),
            );
          }
          return _Timeline(photos: photos);
        },
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final picked = await PhotoPicker.pick(context);
    if (picked == null || !context.mounted) return;

    final defaultWeek =
        ref.read(activePregnancyProvider).valueOrNull?.currentWeek;
    final details = await _PhotoDetailsSheet.show(
      context,
      initialDate: DateTime.now(),
      initialWeek: defaultWeek,
    );
    if (details == null) return;

    await ref.read(localMediaStoreProvider).addPhoto(
          id: _uuid.v4(),
          bytes: picked.bytes,
          extension: picked.extension,
          mediaType: picked.mediaType,
          takenAt: details.date,
          week: details.week,
          note: details.note,
        );
    ref.invalidate(memoryPhotosProvider);
    if (context.mounted) context.showSnack('Memory saved');
  }
}

/// The scrollable timeline, grouped by "MMMM yyyy".
class _Timeline extends ConsumerWidget {
  const _Timeline({required this.photos});
  final List<PhotoEntry> photos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = <String, List<PhotoEntry>>{};
    final monthFmt = DateFormat('MMMM yyyy');
    for (final p in photos) {
      groups.putIfAbsent(monthFmt.format(p.takenAt), () => []).add(p);
    }

    final children = <Widget>[];
    var index = 0;
    for (final entry in groups.entries) {
      children.add(Padding(
        padding: const EdgeInsets.only(
            top: AppSpacing.sm, bottom: AppSpacing.sm),
        child: SectionHeader(title: entry.key),
      ));
      children.add(
        GridView.count(
          crossAxisCount: context.isCompact ? 2 : 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          children: [
            for (final p in entry.value)
              AnimatedEntrance(
                index: index++,
                child: _PhotoTile(photo: p),
              ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl),
      children: children,
    );
  }
}

class _PhotoTile extends ConsumerWidget {
  const _PhotoTile({required this.photo});
  final PhotoEntry photo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _openViewer(context, ref),
      child: Hero(
        tag: photo.id,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photo.isVideo)
                Container(
                  color: Colors.black87,
                  child: const Center(
                    child: Icon(Icons.play_circle_fill,
                        size: 40, color: Colors.white),
                  ),
                )
              else
                Image.file(File(photo.path), fit: BoxFit.cover),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.65),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    photo.week != null
                        ? 'Week ${photo.week}'
                        : DateFormat('d MMM').format(photo.takenAt),
                    style: context.textStyles.labelMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openViewer(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _PhotoViewer(photo: photo),
      fullscreenDialog: true,
    ));
  }
}

/// Full-screen viewer for a single memory, with edit + delete.
class _PhotoViewer extends ConsumerWidget {
  const _PhotoViewer({required this.photo});
  final PhotoEntry photo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('EEEE, d MMM yyyy');
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Edit details',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _edit(context, ref),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Hero(
                tag: photo.id,
                child: photo.isVideo
                    ? _VideoView(path: photo.path)
                    : InteractiveViewer(
                        child:
                            Image.file(File(photo.path), fit: BoxFit.contain),
                      ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.week != null
                      ? 'Week ${photo.week} · ${dateFmt.format(photo.takenAt)}'
                      : dateFmt.format(photo.takenAt),
                  style: context.textStyles.titleSmall
                      ?.copyWith(color: Colors.white),
                ),
                if (photo.note != null && photo.note!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(photo.note!,
                      style: context.textStyles.bodyMedium
                          ?.copyWith(color: Colors.white70)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final details = await _PhotoDetailsSheet.show(
      context,
      initialDate: photo.takenAt,
      initialWeek: photo.week,
      initialNote: photo.note,
      dateEditable: false,
    );
    if (details == null) return;
    await ref
        .read(localMediaStoreProvider)
        .updatePhoto(photo.id, week: details.week, note: details.note);
    ref.invalidate(memoryPhotosProvider);
    if (context.mounted) context.showSnack('Updated');
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this photo?'),
        content: const Text('This removes it from your device permanently.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    await ref.read(localMediaStoreProvider).deletePhoto(photo.id);
    ref.invalidate(memoryPhotosProvider);
    if (context.mounted) Navigator.of(context).pop();
  }
}

/// Simple tap-to-play/pause player for an on-device memory video.
class _VideoView extends StatefulWidget {
  const _VideoView({required this.path});
  final String path;

  @override
  State<_VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<_VideoView> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _ready = true);
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    return GestureDetector(
      onTap: () => setState(() =>
          _controller.value.isPlaying ? _controller.pause() : _controller.play()),
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio == 0
            ? 16 / 9
            : _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            VideoProgressIndicator(_controller, allowScrubbing: true),
            if (!_controller.value.isPlaying)
              const Icon(Icons.play_circle_fill,
                  size: 64, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

/// The captured date / week / note for a memory photo.
class _PhotoDetails {
  const _PhotoDetails({required this.date, this.week, this.note});
  final DateTime date;
  final int? week;
  final String? note;
}

/// A bottom sheet to capture a photo's date, week and caption.
class _PhotoDetailsSheet extends StatefulWidget {
  const _PhotoDetailsSheet({
    required this.initialDate,
    this.initialWeek,
    this.initialNote,
    this.dateEditable = true,
  });

  final DateTime initialDate;
  final int? initialWeek;
  final String? initialNote;
  final bool dateEditable;

  static Future<_PhotoDetails?> show(
    BuildContext context, {
    required DateTime initialDate,
    int? initialWeek,
    String? initialNote,
    bool dateEditable = true,
  }) {
    return showModalBottomSheet<_PhotoDetails>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PhotoDetailsSheet(
        initialDate: initialDate,
        initialWeek: initialWeek,
        initialNote: initialNote,
        dateEditable: dateEditable,
      ),
    );
  }

  @override
  State<_PhotoDetailsSheet> createState() => _PhotoDetailsSheetState();
}

class _PhotoDetailsSheetState extends State<_PhotoDetailsSheet> {
  late DateTime _date = widget.initialDate;
  late int? _week = widget.initialWeek;
  late final TextEditingController _note =
      TextEditingController(text: widget.initialNote);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 400)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text('Photo details', style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          if (widget.dateEditable)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Date'),
              subtitle: Text(DateFormat('d MMM yyyy').format(_date)),
              trailing: const Icon(Icons.edit_outlined, size: 18),
              onTap: _pickDate,
            ),
          const SizedBox(height: AppSpacing.sm),
          Text('Week (optional)', style: context.textStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              IconButton.outlined(
                onPressed: _week == null || _week! <= 1
                    ? (_week == null ? null : () => setState(() => _week = null))
                    : () => setState(() => _week = _week! - 1),
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Text(
                  _week == null ? 'Not set' : 'Week $_week',
                  textAlign: TextAlign.center,
                  style: context.textStyles.titleMedium,
                ),
              ),
              IconButton.outlined(
                onPressed: () => setState(
                    () => _week = (_week == null ? 1 : _week! + 1).clamp(1, 42)),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _note,
            label: 'Note (optional)',
            hint: 'A few words about this moment',
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Save',
            onPressed: () => Navigator.pop(
              context,
              _PhotoDetails(
                date: _date,
                week: _week,
                note: _note.text.trim().isEmpty ? null : _note.text.trim(),
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
