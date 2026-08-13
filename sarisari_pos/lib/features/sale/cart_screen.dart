import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final overStock = cart.overStockLines;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear cart?'),
                    content: const Text('This removes all items from the current sale.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          cart.clear();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Clear'),
            ),
        ],
      ),
      body: cart.isEmpty
          ? const Center(child: Text('Cart is empty. Scan a product to begin.'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.lines.length,
                    itemBuilder: (ctx, i) {
                      final line = cart.lines[i];
                      final isOver = line.qty > line.product.stockQty;
                      return ListTile(
                        title: Text(line.product.name),
                        subtitle: Text(
                          '₱${line.product.sellPrice.toStringAsFixed(2)} × ${line.qty} ${line.product.unit}'
                          '${isOver ? '  ⚠ only ${line.product.stockQty} in stock' : ''}',
                          style: TextStyle(color: isOver ? Colors.red : null),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => cart.updateQty(line.product.id, line.qty - 1),
                            ),
                            Text('${line.qty}'),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => cart.updateQty(line.product.id, line.qty + 1),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => cart.removeLine(line.product.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            '₱${cart.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (overStock.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Some items exceed available stock. Adjust quantity before checkout.',
                            style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      FilledButton(
                        onPressed: overStock.isNotEmpty
                            ? null
                            : () => Navigator.pushNamed(context, '/sale/checkout'),
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        child: const Text('Proceed to Checkout'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
