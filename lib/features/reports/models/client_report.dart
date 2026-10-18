import '../../../core/network/json_parse.dart';
import '../../../l10n/strings.dart';

class ClientReport {
  final int id;
  final String title;
  final String meta;
  final String createdAt;
  final String updatedAt;
  final String fileName;
  final String mimeType;
  final bool available;
  final bool unread;

  const ClientReport({
    required this.id,
    required this.title,
    this.meta = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.fileName = '',
    this.mimeType = '',
    this.available = true,
    this.unread = false,
  });

  /// Lower-case extension without the dot; `pdf` when the server gives none.
  String get extension {
    final dot = fileName.lastIndexOf('.');
    if (dot != -1 && dot < fileName.length - 1) {
      return fileName.substring(dot + 1).toLowerCase();
    }
    if (mimeType.contains('word')) return 'docx';
    return 'pdf';
  }

  bool get isPdf => extension == 'pdf';

  /// Changes whenever the server replaces the file, so a stale cache is never opened.
  String get version {
    final stamp = updatedAt.isNotEmpty ? updatedAt : createdAt;
    return stamp.replaceAll(RegExp(r'[^0-9]'), '');
  }

  factory ClientReport.fromJson(Map<String, dynamic> json) {
    final file = asMap(json['file']);
    final fileName = asString(file['name'], asString(json['file_name']));
    final size = asString(file['size_human'], asString(json['file_size_formatted']));
    final created = asString(json['created_at']);
    final createdDate =
        locDate(created.length >= 10 ? created.substring(0, 10) : created);
    final metaParts = <String>[
      if (created.isNotEmpty) createdDate,
      if (fileName.isNotEmpty) fileName.split('.').last.toUpperCase(),
      if (size.isNotEmpty) size,
    ];
    return ClientReport(
      id: asInt(json['id']),
      title: asString(json['title'], tr('fallbackReport')),
      meta: metaParts.join(' · '),
      createdAt: created,
      updatedAt: asString(json['updated_at']),
      fileName: fileName,
      mimeType: asString(file['mime_type']),
      available: fileName.isNotEmpty || json['download_url'] != null,
      unread: json['first_downloaded_at'] == null,
    );
  }
}
