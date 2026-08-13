import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/daos/settings_dao.dart';
import '../../services/device_id_service.dart';
import '../../state/license_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsDao = SettingsDao();
  final _deviceIdService = DeviceIdService();

  bool _allowNegativeStock = false;
  String _deviceId = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final allowNegative = await _settingsDao.getBool('allow_negative_stock');
    final deviceId = await _deviceIdService.getOrCreate();
    if (!mounted) return;
    setState(() {
      _allowNegativeStock = allowNegative;
      _deviceId = deviceId;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final license = context.watch<LicenseProvider>();
    final token = license.token;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                SwitchListTile(
                  title: const Text('Allow selling below available stock'),
                  subtitle: const Text(
                    'When off, checkout is blocked if a cart quantity exceeds what\'s in stock. '
                    'When on, sales are allowed to go through with a warning (stock can go negative).',
                  ),
                  value: _allowNegativeStock,
                  onChanged: (v) async {
                    await _settingsDao.setBool('allow_negative_stock', v);
                    setState(() => _allowNegativeStock = v);
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('License', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  title: const Text('Plan Type'),
                  subtitle: Text(token?.isLifetime == true ? 'Lifetime' : 'Monthly Subscription'),
                ),
                if (token != null && !token.isLifetime)
                  ListTile(
                    title: const Text('Renews / Expires'),
                    subtitle: Text(token.expiresAt != null
                        ? _formatDate(token.expiresAt!)
                        : 'Unknown'),
                  ),
                ListTile(
                  title: const Text('Device ID'),
                  subtitle: Text(_deviceId, style: const TextStyle(fontSize: 12)),
                ),
                if (token != null && !token.isLifetime)
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('Check for renewal now'),
                    subtitle: const Text('Requires internet connection'),
                    onTap: license.isChecking
                        ? null
                        : () async {
                            final ok = await license.checkStatus();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'License is up to date'
                                    : (license.lastError ?? 'Check failed')),
                              ),
                            );
                          },
                  ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('Data', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_sync),
                  title: const Text('Sync now'),
                  subtitle: const Text('Backs up sales data. Not required for the app to work offline.'),
                  onTap: () {
                    // Wire up sync_service.dart here.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sync not yet implemented')),
                    );
                  },
                ),
              ],
            ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.month}/${dt.day}/${dt.year}';
}
