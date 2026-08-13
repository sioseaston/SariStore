import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/license_provider.dart';

class ActivateLicenseScreen extends StatefulWidget {
  const ActivateLicenseScreen({super.key});

  @override
  State<ActivateLicenseScreen> createState() => _ActivateLicenseScreenState();
}

class _ActivateLicenseScreenState extends State<ActivateLicenseScreen> {
  final _keyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final license = context.read<LicenseProvider>();
    final ok = await license.activate(licenseKey: _keyController.text.trim());
    if (ok && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final license = context.watch<LicenseProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront, size: 64, color: Colors.teal),
                const SizedBox(height: 16),
                const Text(
                  'Activate Sari-Sari POS',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the license key given to you when your store account was created. '
                  'This requires internet only once — after activation, the app works fully offline.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _keyController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'License Key',
                    hintText: 'e.g. SS-A1B2-C3D4-E5F6',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter your license key' : null,
                ),
                if (license.lastError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    license.lastError!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: license.isChecking ? null : _submit,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: license.isChecking
                      ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Activate'),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Don't have a license key? Contact the developer to set up your store account.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
