import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/security/encryption_service.dart';
import '../../core/storage/storage_service.dart';

/// Comprehensive attachment service for receipts, PDFs, and notes
class AttachmentService {
  final EncryptionService _encryptionService;
  final StorageService _storageService;
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  AttachmentService({
    required EncryptionService encryptionService,
    required StorageService storageService,
  })  : _encryptionService = encryptionService,
        _storageService = storageService;

  /// Pick and save an image attachment (receipt/photo)
  Future<AttachmentResult> pickImageAttachment({
    ImageSource source = ImageSource.camera,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile == null) {
        return AttachmentResult.cancelled();
      }

      final file = File(pickedFile.path);
      final fileSize = await file.length();

      if (fileSize > AppConstants.maxFileSize) {
        return AttachmentResult.error('File size exceeds ${AppConstants.maxFileSize ~/ (1024 * 1024)}MB limit');
      }

      final attachment = await _saveAttachment(
        file: file,
        originalName: pickedFile.name,
        type: AttachmentType.image,
      );

      return AttachmentResult.success(attachment);
    } catch (e) {
      return AttachmentResult.error('Failed to pick image: $e');
    }
  }

  /// Pick and save multiple image attachments
  Future<List<AttachmentResult>> pickMultipleImageAttachments({
    int imageQuality = 85,
    int? maxImages,
  }) async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFiles.isEmpty) {
        return [AttachmentResult.cancelled()];
      }

      final List<XFile> filesToProcess = maxImages != null
          ? pickedFiles.take(maxImages).toList()
          : pickedFiles;

      final List<AttachmentResult> results = [];

      for (final pickedFile in filesToProcess) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();

        if (fileSize > AppConstants.maxFileSize) {
          results.add(AttachmentResult.error(
              'File ${pickedFile.name} exceeds size limit'));
          continue;
        }

        try {
          final attachment = await _saveAttachment(
            file: file,
            originalName: pickedFile.name,
            type: AttachmentType.image,
          );
          results.add(AttachmentResult.success(attachment));
        } catch (e) {
          results.add(AttachmentResult.error(
              'Failed to save ${pickedFile.name}: $e'));
        }
      }

      return results;
    } catch (e) {
      return [AttachmentResult.error('Failed to pick images: $e')];
    }
  }

  /// Pick and save a document attachment (PDF, etc.)
  Future<AttachmentResult> pickDocumentAttachment({
    List<String>? allowedExtensions,
  }) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions ?? AppConstants.supportedDocumentFormats,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return AttachmentResult.cancelled();
      }

      final platformFile = result.files.first;
      
      if (platformFile.path == null) {
        return AttachmentResult.error('Invalid file path');
      }

      final file = File(platformFile.path!);
      final fileSize = platformFile.size;

      if (fileSize > AppConstants.maxFileSize) {
        return AttachmentResult.error('File size exceeds ${AppConstants.maxFileSize ~/ (1024 * 1024)}MB limit');
      }

      final attachment = await _saveAttachment(
        file: file,
        originalName: platformFile.name,
        type: AttachmentType.document,
      );

      return AttachmentResult.success(attachment);
    } catch (e) {
      return AttachmentResult.error('Failed to pick document: $e');
    }
  }

  /// Save a text note as attachment
  Future<AttachmentResult> saveTextNote({
    required String content,
    required String title,
  }) async {
    try {
      if (content.trim().isEmpty) {
        return AttachmentResult.error('Note content cannot be empty');
      }

      final attachment = await _saveTextAttachment(
        content: content,
        title: title,
        type: AttachmentType.note,
      );

      return AttachmentResult.success(attachment);
    } catch (e) {
      return AttachmentResult.error('Failed to save note: $e');
    }
  }

  /// Get attachment by ID
  Future<AttachmentModel?> getAttachment(String attachmentId) async {
    try {
      final filePath = _storageService.getAttachment(attachmentId);
      if (filePath == null) return null;

      final file = File(filePath);
      if (!await file.exists()) return null;

      // Read metadata from storage
      final metadataJson = _storageService.getSetting<Map<String, dynamic>>('attachment_metadata_$attachmentId');
      if (metadataJson == null) return null;

      return AttachmentModel.fromJson(metadataJson);
    } catch (e) {
      debugPrint('Failed to get attachment: $e');
      return null;
    }
  }

  /// Get attachment file data
  Future<Uint8List?> getAttachmentData(String attachmentId) async {
    try {
      final filePath = _storageService.getAttachment(attachmentId);
      if (filePath == null) return null;

      final file = File(filePath);
      if (!await file.exists()) return null;

      final encryptedData = await file.readAsBytes();
      final decryptedData = await _encryptionService.decryptBytes(encryptedData);

      return decryptedData;
    } catch (e) {
      debugPrint('Failed to get attachment data: $e');
      return null;
    }
  }

  /// Get text note content
  Future<String?> getTextNoteContent(String attachmentId) async {
    try {
      final data = await getAttachmentData(attachmentId);
      if (data == null) return null;

      return String.fromCharCodes(data);
    } catch (e) {
      debugPrint('Failed to get text note content: $e');
      return null;
    }
  }

  /// Delete attachment
  Future<bool> deleteAttachment(String attachmentId) async {
    try {
      await _storageService.deleteAttachment(attachmentId);
      await _storageService.deleteSetting('attachment_metadata_$attachmentId');
      return true;
    } catch (e) {
      debugPrint('Failed to delete attachment: $e');
      return false;
    }
  }

  /// Get all attachments for a transaction
  Future<List<AttachmentModel>> getTransactionAttachments(String transactionId) async {
    try {
      final attachmentIds = _storageService.getSetting<List<String>>('transaction_attachments_$transactionId') ?? [];
      final attachments = <AttachmentModel>[];

      for (final id in attachmentIds) {
        final attachment = await getAttachment(id);
        if (attachment != null) {
          attachments.add(attachment);
        }
      }

      return attachments;
    } catch (e) {
      debugPrint('Failed to get transaction attachments: $e');
      return [];
    }
  }

  /// Link attachment to transaction
  Future<void> linkAttachmentToTransaction(String attachmentId, String transactionId) async {
    try {
      final existingIds = _storageService.getSetting<List<String>>('transaction_attachments_$transactionId') ?? [];
      if (!existingIds.contains(attachmentId)) {
        existingIds.add(attachmentId);
        await _storageService.saveSetting('transaction_attachments_$transactionId', existingIds);
      }
    } catch (e) {
      debugPrint('Failed to link attachment to transaction: $e');
    }
  }

  /// Unlink attachment from transaction
  Future<void> unlinkAttachmentFromTransaction(String attachmentId, String transactionId) async {
    try {
      final existingIds = _storageService.getSetting<List<String>>('transaction_attachments_$transactionId') ?? [];
      existingIds.remove(attachmentId);
      await _storageService.saveSetting('transaction_attachments_$transactionId', existingIds);
    } catch (e) {
      debugPrint('Failed to unlink attachment from transaction: $e');
    }
  }

  /// Get attachment storage size
  Future<int> getAttachmentStorageSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory('${appDir.path}/attachments');
      
      if (!await attachmentsDir.exists()) return 0;
      
      int totalSize = 0;
      await for (final entity in attachmentsDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Cleanup orphaned attachments
  Future<int> cleanupOrphanedAttachments() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory('${appDir.path}/attachments');
      
      if (!await attachmentsDir.exists()) return 0;
      
      int cleanedCount = 0;
      await for (final entity in attachmentsDir.list()) {
        if (entity is File) {
          final fileName = entity.path.split('/').last;
          final attachmentId = fileName.split('.').first;
          
          // Check if attachment metadata exists
          final metadata = _storageService.getSetting<Map<String, dynamic>>('attachment_metadata_$attachmentId');
          if (metadata == null) {
            await entity.delete();
            cleanedCount++;
          }
        }
      }
      
      return cleanedCount;
    } catch (e) {
      debugPrint('Failed to cleanup orphaned attachments: $e');
      return 0;
    }
  }

  // Private methods

  Future<AttachmentModel> _saveAttachment({
    required File file,
    required String originalName,
    required AttachmentType type,
  }) async {
    final attachmentId = _uuid.v4();
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${appDir.path}/attachments');
    
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    // Read and encrypt file data
    final fileData = await file.readAsBytes();
    final encryptedData = await _encryptionService.encryptBytes(fileData);

    // Save encrypted file
    final extension = originalName.split('.').last.toLowerCase();
    final encryptedFile = File('${attachmentsDir.path}/$attachmentId.$extension');
    await encryptedFile.writeAsBytes(encryptedData);

    // Create attachment model
    final attachment = AttachmentModel(
      id: attachmentId,
      originalName: originalName,
      type: type,
      size: fileData.length,
      mimeType: _getMimeType(extension),
      createdAt: DateTime.now(),
      filePath: encryptedFile.path,
    );

    // Save metadata
    await _storageService.saveAttachment(attachmentId, encryptedFile.path);
    await _storageService.saveSetting('attachment_metadata_$attachmentId', attachment.toJson());

    return attachment;
  }

  Future<AttachmentModel> _saveTextAttachment({
    required String content,
    required String title,
    required AttachmentType type,
  }) async {
    final attachmentId = _uuid.v4();
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${appDir.path}/attachments');
    
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    // Encrypt text content
    final textData = Uint8List.fromList(content.codeUnits);
    final encryptedData = await _encryptionService.encryptBytes(textData);

    // Save encrypted file
    final encryptedFile = File('${attachmentsDir.path}/$attachmentId.txt');
    await encryptedFile.writeAsBytes(encryptedData);

    // Create attachment model
    final attachment = AttachmentModel(
      id: attachmentId,
      originalName: '$title.txt',
      type: type,
      size: textData.length,
      mimeType: 'text/plain',
      createdAt: DateTime.now(),
      filePath: encryptedFile.path,
    );

    // Save metadata
    await _storageService.saveAttachment(attachmentId, encryptedFile.path);
    await _storageService.saveSetting('attachment_metadata_$attachmentId', attachment.toJson());

    return attachment;
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}

/// Attachment model
class AttachmentModel {
  final String id;
  final String originalName;
  final AttachmentType type;
  final int size;
  final String mimeType;
  final DateTime createdAt;
  final String filePath;

  AttachmentModel({
    required this.id,
    required this.originalName,
    required this.type,
    required this.size,
    required this.mimeType,
    required this.createdAt,
    required this.filePath,
  });

  /// Get human-readable file size
  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Check if attachment is an image
  bool get isImage => type == AttachmentType.image;

  /// Check if attachment is a document
  bool get isDocument => type == AttachmentType.document;

  /// Check if attachment is a note
  bool get isNote => type == AttachmentType.note;

  /// Get appropriate icon for attachment type
  IconData get icon {
    switch (type) {
      case AttachmentType.image:
        return Icons.image;
      case AttachmentType.document:
        if (mimeType == 'application/pdf') return Icons.picture_as_pdf;
        return Icons.description;
      case AttachmentType.note:
        return Icons.note;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalName': originalName,
        'type': type.toString(),
        'size': size,
        'mimeType': mimeType,
        'createdAt': createdAt.toIso8601String(),
        'filePath': filePath,
      };

  factory AttachmentModel.fromJson(Map<String, dynamic> json) => AttachmentModel(
        id: json['id'],
        originalName: json['originalName'],
        type: AttachmentType.values.firstWhere(
          (e) => e.toString() == json['type'],
        ),
        size: json['size'],
        mimeType: json['mimeType'],
        createdAt: DateTime.parse(json['createdAt']),
        filePath: json['filePath'],
      );
}

/// Attachment type enum
enum AttachmentType {
  image,
  document,
  note,
}

/// Attachment operation result
class AttachmentResult {
  final bool isSuccess;
  final AttachmentModel? attachment;
  final String? error;
  final bool isCancelled;

  AttachmentResult._({
    required this.isSuccess,
    this.attachment,
    this.error,
    this.isCancelled = false,
  });

  factory AttachmentResult.success(AttachmentModel attachment) =>
      AttachmentResult._(isSuccess: true, attachment: attachment);

  factory AttachmentResult.error(String error) =>
      AttachmentResult._(isSuccess: false, error: error);

  factory AttachmentResult.cancelled() =>
      AttachmentResult._(isSuccess: false, isCancelled: true);
}
