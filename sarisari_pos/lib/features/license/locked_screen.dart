import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/license_provider.dart';

class LockedScreen extends StatelessWidget {
  const LockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final license = context.watch<LicenseProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Subscription Expired',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'New sales and inventory changes are paused. '
                'Connect to the internet to renew your subscription.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              if (license.amountDue != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Amount due: ₱${license.amountDue!.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
              if (license.lastError != null) ...[
                const SizedBox(height: 12),
                Text(
                  license.lastError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.wifi),
                label: license.isChecking
                    ? const Text('Checking...')
                    : const Text('Connect to Internet & Renew'),
                onPressed: license.isChecking
                    ? null
                    : () async {
                        final ok = await license.checkStatus();
                        if (ok && context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
                        }
                      },
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/history'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('View Past Records (Read-only)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
