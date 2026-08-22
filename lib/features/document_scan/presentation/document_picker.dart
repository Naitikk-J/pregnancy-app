import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_spacing.dart';

/// A document the user selected to analyse: raw bytes plus its MIME type and a
/// file extension for local storage.
class PickedDocument {
  const PickedDocument({
    required this.bytes,
    required this.mimeType,
    required this.extension,
  });

  final Uint8List bytes;
  final String mimeType;
  final String extension;
}

/// Lets the user choose where a prescription / lab report comes from — the
/// camera, the photo gallery, or a PDF file — and returns its bytes. Returns
/// null if they cancel.
class DocumentPicker {
  const DocumentPicker._();

  static Future<PickedDocument?> pick(BuildContext context) async {
    final source = await showModalBottomSheet<_Source>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, _Source.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, _Source.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Pick a PDF'),
              onTap: () => Navigator.pop(ctx, _Source.pdf),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (source == null) return null;

    switch (source) {
      case _Source.camera:
      case _Source.gallery:
        return _pickImage(source == _Source.camera
            ? ImageSource.camera
            : ImageSource.gallery);
      case _Source.pdf:
        return _pickPdf();
    }
  }

  static Future<PickedDocument?> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    // Higher resolution + quality improves OCR of prescriptions & lab reports.
    final file = await picker.pickImage(
      source: source,
      imageQuality: 92,
      maxWidth: 3200,
      maxHeight: 3200,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final ext = _extOf(file.path, fallback: 'jpg');
    return PickedDocument(
      bytes: bytes,
      mimeType: _mimeForExt(ext),
      extension: ext,
    );
  }

  static Future<PickedDocument?> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    final file = result?.files.singleOrNull;
    final bytes = file?.bytes;
    if (bytes == null) return null;
    return PickedDocument(
      bytes: bytes,
      mimeType: 'application/pdf',
      extension: 'pdf',
    );
  }

  static String _extOf(String path, {required String fallback}) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return fallback;
    return path.substring(dot + 1).toLowerCase();
  }

  static String _mimeForExt(String ext) => switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'heic' => 'image/heic',
        'heif' => 'image/heif',
        'pdf' => 'application/pdf',
        _ => 'image/jpeg',
      };
}

enum _Source { camera, gallery, pdf }
