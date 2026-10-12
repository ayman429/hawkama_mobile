import '../../../core/network/json_parse.dart';
import '../../../l10n/strings.dart';

class ClientReport {
  final int id;
  final String title;
  final String meta;
  final String createdAt;
  final bool available;
  final bool unread;

  const ClientReport({
    required this.id,
    required this.title,
    this.meta = '',
    this.createdAt = '',
    this.available = true,
    this.unread = false,
  });

  factory ClientReport.fromJson(Map<String, dynamic> json) {
    final fileName = asString(json['file_name']);
    final size = asString(json['file_size_formatted']);
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
      available: fileName.isNotEmpty || json['download_url'] != null,
      unread: json['first_downloaded_at'] == null,
    );
  }
}
