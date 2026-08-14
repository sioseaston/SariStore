import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/models/license_token.dart';
import 'data/models/product.dart';
import 'data/models/transaction.dart';
import 'data/remote/license_api.dart';
import 'features/credit/add_payment_screen.dart';
import 'features/credit/buyer_detail_screen.dart';
import 'features/credit/collectibles_screen.dart';
import 'features/history/transaction_detail_screen.dart';
import 'features/history/transaction_history_screen.dart';
import 'features/home/home_screen.dart';
import 'features/inventory/add_edit_product_screen.dart';
import 'features/inventory/product_list_screen.dart';
import 'features/inventory/qr_generate_screen.dart';
import 'features/inventory/restock_screen.dart';
import 'features/license/locked_screen.dart';
import 'features/onboarding/activate_license_screen.dart';
import 'features/sale/cart_screen.dart';
import 'features/sale/checkout_screen.dart';
import 'features/sale/receipt_screen.dart';
import 'features/sale/scan_screen.dart';
import 'features/settings/settings_screen.dart';
import 'state/cart_provider.dart';
import 'state/license_provider.dart';

// Point this at your deployed sarisari_admin instance.
const _licenseApiBaseUrl = 'http://10.0.2.2:3000';

class SariSariPosApp extends StatelessWidget {
  const SariSariPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(
          create: (_) => LicenseProvider(licenseApi: LicenseApi(baseUrl: _licenseApiBaseUrl))
            ..loadCachedState(),
        ),
      ],
      child: MaterialApp(
        title: 'Sari-Sari POS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          useMaterial3: true,
        ),
        // '/' resolves the license gate before showing Home vs Locked.
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => const _LicenseGate());
            case '/home':
              return MaterialPageRoute(builder: (_) => const HomeScreen());
            case '/sale/scan':
              return MaterialPageRoute(builder: (_) => const ScanScreen());
            case '/sale/cart':
              return MaterialPageRoute(builder: (_) => const CartScreen());
            case '/sale/checkout':
              return MaterialPageRoute(builder: (_) => const CheckoutScreen());
            case '/sale/receipt':
              final txn = settings.arguments as SaleTransaction;
              return MaterialPageRoute(builder: (_) => ReceiptScreen(transaction: txn));
            case '/inventory':
              return MaterialPageRoute(builder: (_) => const ProductListScreen());
            case '/inventory/add':
              // arguments may be a String (prefilled barcode from ScanScreen's
              // "not found" dialog) or null.
              final prefill = settings.arguments as String?;
              return MaterialPageRoute(
                builder: (_) => AddEditProductScreen(prefillBarcode: prefill),
              );
            case '/inventory/edit':
              final product = settings.arguments as Product;
              return MaterialPageRoute(
                builder: (_) => AddEditProductScreen(existingProduct: product),
              );
            case '/inventory/restock':
              return MaterialPageRoute(builder: (_) => const RestockScreen());
            case '/inventory/qr-generate':
              final product = settings.arguments as Product;
              return MaterialPageRoute(builder: (_) => QrGenerateScreen(product: product));
            case '/history':
              return MaterialPageRoute(builder: (_) => const TransactionHistoryScreen());
            case '/history/detail':
              final txn = settings.arguments as SaleTransaction;
              return MaterialPageRoute(builder: (_) => TransactionDetailScreen(transaction: txn));
            case '/credit/collectibles':
              return MaterialPageRoute(builder: (_) => const CollectiblesScreen());
            case '/credit/buyer':
              final buyer = settings.arguments as Buyer;
              return MaterialPageRoute(builder: (_) => BuyerDetailScreen(buyer: buyer));
            case '/credit/add-payment':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => AddPaymentScreen(
                  buyer: args['buyer'] as Buyer,
                  transaction: args['transaction'] as SaleTransaction,
                ),
              );
            case '/settings':
              return MaterialPageRoute(builder: (_) => const SettingsScreen());
            default:
              return MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Not Found')),
                  body: Center(child: Text('No route for ${settings.name}')),
                ),
              );
          }
        },
      ),
    );
  }
}

/// Decides Home vs Locked vs (eventually) Activation screen based on the
/// cached license state — evaluated purely locally, no network call blocks
/// this initial render.
class _LicenseGate extends StatelessWidget {
  const _LicenseGate();

  @override
  Widget build(BuildContext context) {
    final license = context.watch<LicenseProvider>();

    switch (license.state) {
      case LicenseState.active:
      case LicenseState.warning:
        return const HomeScreen();
      case LicenseState.locked:
        return const LockedScreen();
      case LicenseState.noLicense:
        return const ActivateLicenseScreen();
    }
  }
}
