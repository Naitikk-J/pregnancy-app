import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_spacing.dart';

/// A photo or short video the user picked for a memory (or a photo for their
/// avatar).
class PickedPhoto {
  const PickedPhoto({
    required this.bytes,
    required this.extension,
    this.mediaType = 'image',
  });

  final Uint8List bytes;
  final String extension;

  /// 'image' or 'video'.
  final String mediaType;

  bool get isVideo => mediaType == 'video';
}

enum _MediaSource { photoCamera, photoGallery, videoCamera, videoGallery }

/// Lets the user take/choose a photo or a short video from the camera or
/// gallery (no PDF, unlike the document scanner). Set [allowVideo] to false for
/// image-only pickers like the avatar. Returns null if they cancel.
class PhotoPicker {
  const PhotoPicker._();

  static Future<PickedPhoto?> pick(
    BuildContext context, {
    bool allowVideo = true,
  }) async {
    final source = await showModalBottomSheet<_MediaSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, _MediaSource.photoCamera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose photo from gallery'),
              onTap: () => Navigator.pop(ctx, _MediaSource.photoGallery),
            ),
            if (allowVideo) ...[
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Record a video'),
                onTap: () => Navigator.pop(ctx, _MediaSource.videoCamera),
              ),
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: const Text('Choose video from gallery'),
                onTap: () => Navigator.pop(ctx, _MediaSource.videoGallery),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (source == null) return null;

    final picker = ImagePicker();
    switch (source) {
      case _MediaSource.photoCamera:
      case _MediaSource.photoGallery:
        final file = await picker.pickImage(
          source: source == _MediaSource.photoCamera
              ? ImageSource.camera
              : ImageSource.gallery,
          imageQuality: 88,
          maxWidth: 1600,
          maxHeight: 1600,
        );
        if (file == null) return null;
        return PickedPhoto(
          bytes: await file.readAsBytes(),
          extension: _extOf(file.path, 'jpg'),
        );
      case _MediaSource.videoCamera:
      case _MediaSource.videoGallery:
        final file = await picker.pickVideo(
          source: source == _MediaSource.videoCamera
              ? ImageSource.camera
              : ImageSource.gallery,
          maxDuration: const Duration(minutes: 2),
        );
        if (file == null) return null;
        return PickedPhoto(
          bytes: await file.readAsBytes(),
          extension: _extOf(file.path, 'mp4'),
          mediaType: 'video',
        );
    }
  }

  static String _extOf(String path, String fallback) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return fallback;
    return path.substring(dot + 1).toLowerCase();
  }
}
