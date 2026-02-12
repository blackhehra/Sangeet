import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// GitHub repository owner and name
const _kGitHubOwner = 'blackhehra';
const _kGitHubRepo = 'Sangeet';

/// Model for a GitHub release
class AppUpdateInfo {
  final String tagName;
  final String version;
  final String htmlUrl;
  final String body; // release notes
  final String? apkDownloadUrl;
  final String? exeDownloadUrl;
  final DateTime publishedAt;

  const AppUpdateInfo({
    required this.tagName,
    required this.version,
    required this.htmlUrl,
    required this.body,
    this.apkDownloadUrl,
    this.exeDownloadUrl,
    required this.publishedAt,
  });
}

/// State for the update checker
class AppUpdateState {
  final bool isChecking;
  final bool isDownloading;
  final double downloadProgress;
  final AppUpdateInfo? updateInfo;
  final String? error;
  final String? downloadedFilePath;

  const AppUpdateState({
    this.isChecking = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.updateInfo = null,
    this.error = null,
    this.downloadedFilePath = null,
  });

  bool get hasUpdate => updateInfo != null;

  AppUpdateState copyWith({
    bool? isChecking,
    bool? isDownloading,
    double? downloadProgress,
    AppUpdateInfo? updateInfo,
    String? error,
    String? downloadedFilePath,
  }) {
    return AppUpdateState(
      isChecking: isChecking ?? this.isChecking,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      updateInfo: updateInfo ?? this.updateInfo,
      error: error,
      downloadedFilePath: downloadedFilePath ?? this.downloadedFilePath,
    );
  }
}

/// Riverpod provider for app update state
final appUpdateProvider =
    StateNotifierProvider<AppUpdateNotifier, AppUpdateState>(
  (ref) => AppUpdateNotifier(),
);

class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  AppUpdateNotifier() : super(const AppUpdateState());

  /// Check GitHub releases for a newer version
  Future<void> checkForUpdate() async {
    if (state.isChecking) return;
    state = state.copyWith(isChecking: true, error: null);

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "2.0.0"

      final url = Uri.parse(
        'https://api.github.com/repos/$_kGitHubOwner/$_kGitHubRepo/releases/latest',
      );
      final response = await http.get(url, headers: {
        'Accept': 'application/vnd.github.v3+json',
      });

      if (response.statusCode != 200) {
        state = state.copyWith(
          isChecking: false,
          error: 'Failed to check for updates (${response.statusCode})',
        );
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      // Strip leading 'v' if present: "v2.1.0" -> "2.1.0"
      final latestVersion = tagName.startsWith('v') ? tagName.substring(1) : tagName;
      final htmlUrl = data['html_url'] as String? ?? '';
      final body = data['body'] as String? ?? '';
      final publishedAt = DateTime.tryParse(data['published_at'] ?? '') ?? DateTime.now();

      // Find platform-specific asset download URLs
      String? apkUrl;
      String? exeUrl;
      final assets = data['assets'] as List<dynamic>? ?? [];
      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        final downloadUrl = asset['browser_download_url'] as String? ?? '';
        if (name.endsWith('.apk')) {
          apkUrl = downloadUrl;
        } else if (name.endsWith('.exe')) {
          exeUrl = downloadUrl;
        }
      }

      // Compare versions
      if (_isNewerVersion(latestVersion, currentVersion)) {
        state = state.copyWith(
          isChecking: false,
          updateInfo: AppUpdateInfo(
            tagName: tagName,
            version: latestVersion,
            htmlUrl: htmlUrl,
            body: body,
            apkDownloadUrl: apkUrl,
            exeDownloadUrl: exeUrl,
            publishedAt: publishedAt,
          ),
        );
        print('AppUpdate: New version available: $latestVersion (current: $currentVersion)');
      } else {
        state = state.copyWith(isChecking: false);
        print('AppUpdate: App is up to date ($currentVersion)');
      }
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        error: 'Update check failed: $e',
      );
      print('AppUpdate: Check failed: $e');
    }
  }

  /// Download the update file (APK for Android, EXE for Windows)
  Future<void> downloadAndInstall() async {
    if (state.isDownloading || state.updateInfo == null) return;

    String? downloadUrl;
    String fileName;

    if (!kIsWeb && Platform.isAndroid) {
      downloadUrl = state.updateInfo!.apkDownloadUrl;
      fileName = 'sangeet-${state.updateInfo!.version}.apk';
    } else if (!kIsWeb && Platform.isWindows) {
      downloadUrl = state.updateInfo!.exeDownloadUrl;
      fileName = 'sangeet-${state.updateInfo!.version}-setup.exe';
    } else {
      // For other platforms, open the release page in browser
      _openReleasePage();
      return;
    }

    if (downloadUrl == null || downloadUrl.isEmpty) {
      // No direct download available, open release page
      _openReleasePage();
      return;
    }

    state = state.copyWith(isDownloading: true, downloadProgress: 0.0, error: null);

    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      // Download with progress tracking
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final streamedResponse = await http.Client().send(request);
      final totalBytes = streamedResponse.contentLength ?? 0;
      int receivedBytes = 0;

      final sink = file.openWrite();
      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          state = state.copyWith(
            downloadProgress: receivedBytes / totalBytes,
          );
        }
      }
      await sink.close();

      state = state.copyWith(
        isDownloading: false,
        downloadProgress: 1.0,
        downloadedFilePath: filePath,
      );

      print('AppUpdate: Downloaded to $filePath');

      // Install the update
      await _installUpdate(filePath);
    } catch (e) {
      state = state.copyWith(
        isDownloading: false,
        downloadProgress: 0.0,
        error: 'Download failed: $e',
      );
      print('AppUpdate: Download failed: $e');
    }
  }

  static const _nativeChannel = MethodChannel('com.example.flutter_app/native');

  /// Install the downloaded update
  Future<void> _installUpdate(String filePath) async {
    try {
      if (Platform.isAndroid) {
        // Use native MethodChannel to install APK via FileProvider
        final success = await _nativeChannel.invokeMethod<bool>(
          'installApk',
          {'filePath': filePath},
        );
        if (success == true) {
          print('AppUpdate: Install intent launched');
        } else {
          print('AppUpdate: Native install returned false, opening release page');
          _openReleasePage();
        }
      } else if (Platform.isWindows) {
        // Launch the installer EXE on Windows
        await Process.start(filePath, [], mode: ProcessStartMode.detached);
        print('AppUpdate: Launched Windows installer');
      }
    } catch (e) {
      print('AppUpdate: Install failed: $e, falling back');
      try {
        if (Platform.isWindows) {
          await Process.run('explorer', [filePath]);
        } else {
          _openReleasePage();
        }
      } catch (e2) {
        print('AppUpdate: Fallback also failed: $e2');
        _openReleasePage();
      }
    }
  }

  /// Open the GitHub release page in browser as fallback
  Future<void> _openReleasePage() async {
    final url = state.updateInfo?.htmlUrl ?? 
        'https://github.com/$_kGitHubOwner/$_kGitHubRepo/releases/latest';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      print('AppUpdate: Could not open release page: $e');
    }
  }

  /// Compare semantic versions. Returns true if [latest] is newer than [current].
  bool _isNewerVersion(String latest, String current) {
    try {
      // Strip any suffix like "-beta", "-rc1" etc for comparison
      final latestParts = latest.split('-').first.split('.').map(int.parse).toList();
      final currentParts = current.split('-').first.split('.').map(int.parse).toList();

      // Pad shorter list with zeros
      while (latestParts.length < 3) latestParts.add(0);
      while (currentParts.length < 3) currentParts.add(0);

      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }

      // Same base version — if current has a pre-release suffix but latest doesn't,
      // latest is newer (e.g. "2.0.0" > "2.0.0-beta")
      final currentHasSuffix = current.contains('-');
      final latestHasSuffix = latest.contains('-');
      if (currentHasSuffix && !latestHasSuffix) return true;

      return false;
    } catch (e) {
      // If parsing fails, do simple string comparison
      return latest != current;
    }
  }

  /// Dismiss the update notification
  void dismissUpdate() {
    state = const AppUpdateState();
  }
}

/// Shows the update dialog with release notes, download progress, and install button
Future<void> showUpdateDialog(BuildContext context, WidgetRef ref) async {
  final updateState = ref.read(appUpdateProvider);
  if (updateState.updateInfo == null) return;

  final info = updateState.updateInfo!;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(appUpdateProvider);
          final isDownloading = state.isDownloading;
          final progress = state.downloadProgress;
          final error = state.error;

          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.system_update,
                    color: Color(0xFF1DB954),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Update Available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'v${info.version}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1DB954),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Release notes
                  const Text(
                    "What's New",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF282828),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        info.body.isNotEmpty ? info.body : 'Bug fixes and improvements.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white60,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  // Download progress
                  if (isDownloading) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: const Color(0xFF282828),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF1DB954),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Downloading update...',
                      style: TextStyle(fontSize: 12, color: Colors.white38),
                    ),
                  ],
                  // Error message
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isDownloading
                    ? null
                    : () {
                        Navigator.of(dialogContext).pop();
                      },
                child: Text(
                  'Later',
                  style: TextStyle(
                    color: isDownloading ? Colors.grey : Colors.white60,
                  ),
                ),
              ),
              FilledButton(
                onPressed: isDownloading
                    ? null
                    : () {
                        ref.read(appUpdateProvider.notifier).downloadAndInstall();
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isDownloading ? 'Downloading...' : 'Update Now',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
