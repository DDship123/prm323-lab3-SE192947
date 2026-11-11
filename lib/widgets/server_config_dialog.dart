import 'package:flutter/material.dart';
import '../models/server_config_model.dart';
import '../services/server_config_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'ktx_button.dart';
import 'ktx_text_field.dart';

/// Hộp thoại cấu hình địa chỉ IP máy chủ Backend động (Localhost, Emulator, VPS, Custom)
class ServerConfigDialog extends StatefulWidget {
  final ServerConfigModel currentConfig;
  final ValueChanged<ServerConfigModel> onSaved;

  const ServerConfigDialog({
    super.key,
    required this.currentConfig,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required ServerConfigModel currentConfig,
    required ValueChanged<ServerConfigModel> onSaved,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => ServerConfigDialog(
        currentConfig: currentConfig,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late TextEditingController _urlController;
  late ServerEnvironmentPreset _selectedPreset;
  final ServerConfigService _service = ServerConfigService();
  bool _isTesting = false;
  String? _pingResult;
  bool? _isSuccess;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.currentConfig.preset;
    _urlController = TextEditingController(text: widget.currentConfig.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _pingResult = null;
      _isSuccess = null;
    });

    final ok = await _service.pingServer(_urlController.text.trim());

    if (mounted) {
      setState(() {
        _isTesting = false;
        _isSuccess = ok;
        _pingResult = ok
            ? 'Kết nối máy chủ thành công (HTTP 200 OK)!'
            : 'Không thể kết nối tới máy chủ. Vui lòng kiểm tra IP & Port!';
      });
    }
  }

  void _save() {
    final newUrl = _urlController.text.trim();
    if (newUrl.isEmpty) return;

    final updated = widget.currentConfig.copyWith(
      baseUrl: newUrl,
      preset: _selectedPreset,
    );
    _service.saveConfig(updated);
    widget.onSaved(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.dns_rounded, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Cấu hình Máy chủ Backend',
                    style: AppTypography.heading3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Chọn nhanh môi trường hoặc nhập IP máy chủ để chấm bài trên thiết bị thật:',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            ...ServerEnvironmentPreset.values.map((preset) {
              return RadioListTile<ServerEnvironmentPreset>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: preset,
                groupValue: _selectedPreset,
                activeColor: AppColors.primary,
                title: Text(preset.label, style: AppTypography.bodyMedium),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedPreset = val;
                      if (val.defaultUrl.isNotEmpty) {
                        _urlController.text = val.defaultUrl;
                      }
                    });
                  }
                },
              );
            }),
            const SizedBox(height: AppSpacing.sm),
            KtxTextField(
              label: 'Base URL Endpoint Backend',
              controller: _urlController,
              hintText: 'http://127.0.0.1:8088/api/v1',
              prefixIcon: Icons.link_rounded,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_pingResult != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: (_isSuccess == true ? AppColors.success : AppColors.error).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccess == true ? AppColors.success : AppColors.error,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess == true ? Icons.check_circle_outline : Icons.error_outline,
                      color: _isSuccess == true ? AppColors.success : AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _pingResult!,
                        style: TextStyle(
                          color: _isSuccess == true ? AppColors.success : AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.network_ping_rounded, size: 18),
                    label: const Text('Kiểm tra Ping'),
                    onPressed: _isTesting ? null : _testConnection,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: KtxButton(
                    label: 'Áp dụng',
                    icon: Icons.check_rounded,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
