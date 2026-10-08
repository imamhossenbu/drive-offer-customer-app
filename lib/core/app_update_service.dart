import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'constants.dart';
import 'sound_service.dart';

class AppUpdateService {
  static final AppUpdateService instance = AppUpdateService._();
  AppUpdateService._();

  bool _isChecking = false;
  bool _isDownloading = false;
  String _downloadProgress = '0%';
  double _progressValue = 0.0;
  bool _dialogOpen = false;

  /// Check for update either on app launch (auto) or via Profile screen (manual)
  Future<void> checkForUpdate(BuildContext context, {bool isManualCheck = false}) async {
    if (_isChecking || _dialogOpen) return;
    _isChecking = true;

    try {
      final res = await CustomerApiService.instance.getSettings();
      final data = res['data'] ?? res;
      final appVerData = data['appVersion']?['customer'] as Map? ?? {};

      if (appVerData.isEmpty) {
        if (isManualCheck && context.mounted) {
          _showToast(context, 'আপনার অ্যাপটি আপ-টু-ডেট আছে (সর্বশেষ সংস্করণ)', isSuccess: true);
        }
        _isChecking = false;
        return;
      }

      final serverVersion = (appVerData['latestVersion'] ?? '1.0.0').toString().trim();
      final serverBuild = int.tryParse(appVerData['buildNumber']?.toString() ?? '1') ?? 1;
      final downloadUrl = (appVerData['downloadUrl'] ?? '').toString().trim();
      final isForceUpdate = appVerData['forceUpdate'] == true;
      final releaseNotes = (appVerData['releaseNotes'] ?? 'নতুন ফিচার ও পারফরম্যান্স আপডেট।').toString().trim();

      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 1;
      final currentVersion = packageInfo.version;

      final bool hasUpdate = serverBuild > currentBuild ||
          (_isVersionHigher(serverVersion, currentVersion) && serverBuild >= currentBuild);

      if (hasUpdate && downloadUrl.isNotEmpty) {
        if (context.mounted) {
          _showUpdateModal(
            context,
            currentVersion: currentVersion,
            serverVersion: serverVersion,
            serverBuild: serverBuild,
            downloadUrl: downloadUrl,
            isForceUpdate: isForceUpdate,
            releaseNotes: releaseNotes,
          );
        }
      } else if (isManualCheck && context.mounted) {
        _showToast(context, 'আপনার অ্যাপটি ইতিমধ্যে সর্বশেষ সংস্করণে রয়েছে (v$currentVersion)', isSuccess: true);
      }
    } catch (e) {
      debugPrint('Check for update error: $e');
      if (isManualCheck && context.mounted) {
        _showToast(context, 'আপডেট তথ্য যাচাই করা সম্ভব হয়নি। আবার চেষ্টা করুন।', isSuccess: false);
      }
    } finally {
      _isChecking = false;
    }
  }

  bool _isVersionHigher(String serverVer, String currentVer) {
    try {
      final sParts = serverVer.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final cParts = currentVer.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      for (int i = 0; i < sParts.length && i < cParts.length; i++) {
        if (sParts[i] > cParts[i]) return true;
        if (sParts[i] < cParts[i]) return false;
      }
      return sParts.length > cParts.length;
    } catch (_) {
      return false;
    }
  }

  void _showToast(BuildContext context, String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showUpdateModal(
    BuildContext context, {
    required String currentVersion,
    required String serverVersion,
    required int serverBuild,
    required String downloadUrl,
    required bool isForceUpdate,
    required String releaseNotes,
  }) {
    _dialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (dialogCtx) {
        return PopScope(
          canPop: !isForceUpdate && !_isDownloading,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                titlePadding: EdgeInsets.zero,
                contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Rocket Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.system_update_rounded, color: Colors.white, size: 34),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      'নতুন আপডেট পাওয়া গেছে!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Version comparison badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        'v$currentVersion  ➔  v$serverVersion (Build $serverBuild)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Release notes
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'আপডেটের নতুন বিবরণ:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            releaseNotes,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3),
                          ),
                        ],
                      ),
                    ),

                    if (_isDownloading) ...[
                      const SizedBox(height: 18),
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _progressValue > 0 ? _progressValue : null,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ডাউনলোড হচ্ছে: $_downloadProgress (অনুগ্রহ করে অপেক্ষা করুন)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 22),

                    // Action Buttons
                    Row(
                      children: [
                        if (!isForceUpdate && !_isDownloading) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _dialogOpen = false;
                                Navigator.pop(dialogCtx);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                'পরে করব',
                                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isDownloading
                                ? null
                                : () => _startUpdateDownload(
                                      dialogCtx,
                                      downloadUrl,
                                      serverBuild,
                                      setModalState,
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Text(
                              _isDownloading ? 'ডাউনলোড চলছে...' : 'এখনই আপডেট করুন',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ).then((_) {
      _dialogOpen = false;
    });
  }

  Future<void> _startUpdateDownload(
    BuildContext dialogCtx,
    String downloadUrl,
    int serverBuild,
    StateSetter setModalState,
  ) async {
    SoundService.playTap();

    // If running on non-Android (iOS/Web) or if link is Play Store / web page, launch directly
    final isDirectApk = downloadUrl.toLowerCase().endsWith('.apk') ||
        downloadUrl.toLowerCase().contains('/apk') ||
        downloadUrl.toLowerCase().contains('download');

    if (!Platform.isAndroid || !isDirectApk) {
      try {
        final uri = Uri.parse(downloadUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Launch url error: $e');
      }
      return;
    }

    setModalState(() {
      _isDownloading = true;
      _downloadProgress = '0%';
      _progressValue = 0.0;
    });

    try {
      OtaUpdate()
          .execute(
        downloadUrl,
        destinationFilename: 'alokito_telecom_v$serverBuild.apk',
      )
          .listen(
        (OtaEvent event) {
          if (event.status == OtaStatus.DOWNLOADING) {
            final parsedVal = double.tryParse(event.value ?? '0') ?? 0.0;
            setModalState(() {
              _downloadProgress = '${event.value ?? 0}%';
              _progressValue = parsedVal / 100.0;
            });
          } else if (event.status == OtaStatus.INSTALLING) {
            setModalState(() {
              _downloadProgress = 'ইনস্টল হচ্ছে...';
              _progressValue = 1.0;
            });
            // System native installer dialog will automatically appear
          } else if (event.status == OtaStatus.ALREADY_RUNNING_ERROR) {
            // Already downloading
          } else {
            // Permission or other error -> Fallback to browser download so user is never stuck
            debugPrint('OtaUpdate status: ${event.status}');
            _fallbackToBrowserDownload(downloadUrl);
            setModalState(() {
              _isDownloading = false;
            });
          }
        },
        onError: (err) {
          debugPrint('OtaUpdate error: $err');
          _fallbackToBrowserDownload(downloadUrl);
          setModalState(() {
            _isDownloading = false;
          });
        },
      );
    } catch (e) {
      debugPrint('Failed to start OTA update: $e');
      _fallbackToBrowserDownload(downloadUrl);
      setModalState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> _fallbackToBrowserDownload(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
