import '../../../core/network/json_parse.dart';
import '../../../l10n/strings.dart';

class Consultant {
  final int id;
  final String name;
  final String title;
  final String specialization;
  final String? avatarUrl;
  final List<int> workingDays;
  final double rating;
  final String jobsLabel;

  const Consultant({
    required this.id,
    required this.name,
    required this.title,
    this.specialization = '',
    this.avatarUrl,
    this.workingDays = const [0, 1, 2, 3, 4],
    this.rating = 4.8,
    this.jobsLabel = '',
  });

  String get jobsText => jobsLabel.isEmpty ? tr('jobsFallback') : jobsLabel;

  factory Consultant.fromJson(Map<String, dynamic> json) => Consultant(
        id: asInt(json['id']),
        name: asString(json['name']),
        title: asString(json['title']),
        specialization: asString(json['specialization']),
        avatarUrl: (json['avatar_thumb_url'] ?? json['avatar_url']) as String?,
        workingDays: json['working_days'] is List
            ? (json['working_days'] as List).map(asInt).toList()
            : const [],
      );
}
