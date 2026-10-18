import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/config.dart';
import '../../../core/mock/mock_catalog.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/network/json_parse.dart';
import '../../../core/network/result.dart';
import '../models/client_report.dart';

class ReportsRepository {
  ReportsRepository(this._api);

  final ApiClient _api;

  Future<Result<List<ClientReport>>> reports() {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 150));
        return mockReports;
      }
      return asList(await _api.get(Endpoints.reports), ClientReport.fromJson);
    });
  }

  /// App-private folder: Android `app_flutter/reports`, iOS `Documents/reports`.
  /// No storage permission is needed and files go away with the app.
  Future<Directory> _folder() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}reports');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _fileFor(ClientReport report) async {
    final dir = await _folder();
    final name = 'report_${report.id}_${report.version}.${report.extension}';
    return File('${dir.path}${Platform.pathSeparator}$name');
  }

  /// Saved copy of this exact version, or null when it must be downloaded.
  Future<File?> cached(ClientReport report) async {
    final file = await _fileFor(report);
    if (await file.exists() && await file.length() > 0) return file;
    return null;
  }

  /// Downloads the report (or returns the saved copy) and drops older versions.
  Future<Result<File>> fetch(
    ClientReport report, {
    void Function(double progress)? onProgress,
  }) {
    return guard(() async {
      final existing = await cached(report);
      if (existing != null) return existing;

      final file = await _fileFor(report);
      final partial = File('${file.path}.part');
      if (AppConfig.useMock) {
        final data = await rootBundle.load('assets/mock/sample_report.pdf');
        for (var step = 1; step <= 5; step++) {
          await Future.delayed(const Duration(milliseconds: 120));
          onProgress?.call(step / 5);
        }
        await partial.writeAsBytes(data.buffer.asUint8List(), flush: true);
      } else {
        await _api.download(
          Endpoints.reportDownload(report.id),
          partial.path,
          onProgress: (received, total) {
            if (total > 0) onProgress?.call(received / total);
          },
        );
      }
      await partial.rename(file.path);
      await _dropOldVersions(report, keep: file);
      return file;
    });
  }

  Future<void> _dropOldVersions(ClientReport report, {required File keep}) async {
    final dir = await _folder();
    await for (final entity in dir.list()) {
      if (entity is! File || entity.path == keep.path) continue;
      final name = entity.uri.pathSegments.last;
      if (name.startsWith('report_${report.id}_')) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }
}
