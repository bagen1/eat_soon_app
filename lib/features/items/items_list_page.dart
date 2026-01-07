import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'items_provider.dart';
import 'item_edit_page.dart';


class ItemsListPage extends ConsumerWidget {
  const ItemsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider);
    final messenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Eat Soon')),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (tileContext, index) {
          final item = items[index];

          return ListTile(
            title: Text(item.name),
            subtitle: Text(item.duartionLabel),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit item',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ItemEditPage(initialItem: item)),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete item',
                  onPressed: () {
                    final removed = ref.read(itemsProvider.notifier).removeById(item.id);
                    if (removed == null) return;

                    // Close any existing snackbars so you don't stack them.
                    messenger.removeCurrentSnackBar();

                    late final ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller;
                    controller = messenger.showSnackBar(
                      SnackBar(
                        duration: const Duration(seconds: 4),
                        content: Text('Deleted "${removed.name}"'),
                        action: SnackBarAction(
                          label: 'UNDO',
                          onPressed: () {
                            ref.read(itemsProvider.notifier).insert(removed);
                            controller.close(); // close immediately on undo
                          },
                        ),
                      ),
                    );

                    Future.delayed(const Duration(seconds: 4), () {
                      controller.close();
                    });
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ItemEditPage())
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
