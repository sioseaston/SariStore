import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/daos/product_dao.dart';
import '../../state/license_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final license = context.watch<LicenseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sari-Sari POS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (license.state == LicenseState.warning)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text(
                'Your subscription is expiring soon. Connect to the internet to renew.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          FutureBuilder<int>(
            future: ProductDao().getLowStock().then((l) => l.length),
            builder: (ctx, snap) {
              final count = snap.data ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                color: Colors.red.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('$count product(s) low on stock', style: const TextStyle(fontSize: 12)),
              );
            },
          ),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _tile(
                  context,
                  icon: Icons.qr_code_scanner,
                  label: 'New Sale',
                  enabled: license.canTransact,
                  onTap: () => Navigator.pushNamed(context, '/sale/scan'),
                ),
                _tile(
                  context,
                  icon: Icons.inventory_2,
                  label: 'Inventory',
                  enabled: true,
                  onTap: () => Navigator.pushNamed(context, '/inventory'),
                ),
                _tile(
                  context,
                  icon: Icons.receipt_long,
                  label: 'History',
                  enabled: true,
                  onTap: () => Navigator.pushNamed(context, '/history'),
                ),
                _tile(
                  context,
                  icon: Icons.book,
                  label: 'Collectibles',
                  enabled: true,
                  onTap: () => Navigator.pushNamed(context, '/credit/collectibles'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
