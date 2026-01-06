import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/items/item.dart';

class ItemsNotifier extends StateNotifier<List<Item>> {
  ItemsNotifier() : super(_sorted(_initialItems));

  static final _initialItems = <Item>[
    Item(
      name: 'Milk',
      bestBefore: DateTime.now().add(const Duration(days: 2)),
    ),
    Item(
      name: 'Cheese',
      openedAt: DateTime.now().subtract(const Duration(days: 3)),
      openShelfLifeDays: 7,
    ),
    Item(
      name: 'Frozen peas',
    ),
  ];

  void add(Item item) {
    state = _sorted([...state, item]);
  }

  void remove(String id) {
    state = _sorted(
      state.where((item) => item.id != id).toList(),
    );
  }

  void update(Item updated) {
    state = _sorted([
      for (final item in state)
        if (item.id == updated.id) updated else item
    ]);
  }

  Item? removeById(String id) {
    final index = state.indexWhere((i) => i.id == id);
    if (index == -1) return null;

    final removed = state[index];
    state = _sorted(state.where((i) => i.id != id).toList());
    return removed;
  }

  void insert(Item item) {
    state = _sorted([...state, item]);
  }

}

final itemsProvider =
    StateNotifierProvider<ItemsNotifier, List<Item>>(
  (ref) => ItemsNotifier(),
);

List<Item> _sorted(List<Item> items) {
  final copy = [...items];

  copy.sort((a, b) {
    final aDate = a.effectiveExpiryDate;
    final bDate = b.effectiveExpiryDate;

    // Items without expiry date go last
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;

    // Earlier expiry comes first
    return aDate.compareTo(bDate);
  });

  return copy;
}
