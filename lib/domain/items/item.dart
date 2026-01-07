import 'package:uuid/uuid.dart';

final _uuid = Uuid();

class Item {
  final String id;
  final String name;
  final DateTime? bestBefore;
  final DateTime? openedAt;
  final int? openShelfLifeDays;
  final DateTime createdAt;
  final DateTime? consumedAt;

  Item({
    String? id,
    required this.name,
    this.bestBefore,
    this.openedAt,
    this.openShelfLifeDays,
    DateTime? createdAt,
    this.consumedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  DateTime? get effectiveExpiryDate {
    final dates = <DateTime>[];

    if (bestBefore != null) {
      dates.add(bestBefore!);
    }

    if (openedAt != null && openShelfLifeDays != null) {
      dates.add(openedAt!.add(Duration(days: openShelfLifeDays!)));
    }

    if (dates.isEmpty) return null;
    dates.sort();
    return dates.first;
  }

  int? get daysLeft {
    final expiry = effectiveExpiryDate;
    if (expiry == null) return null;
    return expiry.difference(DateTime.now()).inDays;
  }

  int? get daysSinceOpened {
  if (openedAt == null) return null;
  final openedDate = DateTime(openedAt!.year, openedAt!.month, openedAt!.day);
  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  return today.difference(openedDate).inDays;
  }

  bool get isExpired => daysLeft != null && daysLeft! < 0;

  String get duartionLabel {
    if (openedAt != null && openShelfLifeDays == null) {
      final openedDays = daysSinceOpened ?? 0;
      if (openedDays == 0) return 'Opened today';
      if (openedDays == 1) return 'Opened 1 day ago';
      return 'Opened $openedDays days ago';
    } else {
      final d = daysLeft;
      if (d != null) {
        if (d < 0) return 'Expired';
        if (d == 0) return 'Expires today';
        if (d == 1) return '1 day left';
        return '$d days left';
      }
    }
    return 'No expiration date';
  }

  Item copyWith({
    String? name,
    DateTime? bestBefore,
    DateTime? openedAt,
    int? openShelfLifeDays,
    DateTime? consumedAt,
    bool clearBestBefore = false,
    bool clearOpened = false,
    bool clearShelfLife = false,
    bool clearConsumedAt = false,
  }) {
    return Item(
      id: id,
      name: name ?? this.name,
      bestBefore: clearBestBefore ? null : (bestBefore ?? this.bestBefore),
      openedAt: clearOpened ? null : (openedAt ?? this.openedAt),
      openShelfLifeDays: clearShelfLife ? null : (openShelfLifeDays ?? this.openShelfLifeDays),
      createdAt: createdAt,
      consumedAt: clearConsumedAt ? null : (consumedAt ?? this.consumedAt),
    );
  }
}
