import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/items/items_list_page.dart';

void main() {
  runApp(
    const ProviderScope(
      child: EatSoonApp(),
    ),
  );
}

class EatSoonApp extends StatelessWidget {
  const EatSoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ItemsListPage(),
    );
  }
}
