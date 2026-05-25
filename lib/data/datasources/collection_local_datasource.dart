import 'package:hive/hive.dart';
import 'package:la_repe/data/datasources/i_collection_datasource.dart';
import 'package:la_repe/models/models.dart';

class CollectionLocalDatasource implements ICollectionDatasource {
  static const boxName = 'collection';

  // La box debe estar abierta antes de usar este datasource (se hace en main).
  Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  @override
  Future<Map<String, UserSticker>> loadCollection() async {
    final result = <String, UserSticker>{};
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw is! Map) continue;
      result[key as String] = _fromMap(key, raw);
    }
    return result;
  }

  @override
  Future<void> saveSticker(UserSticker sticker) async {
    await _box.put(sticker.stickerId, _toMap(sticker));
  }

  @override
  Future<void> removeSticker(String stickerId) async {
    await _box.delete(stickerId);
  }

  @override
  Future<void> clearCollection() async {
    await _box.clear();
  }

  Map<String, dynamic> _toMap(UserSticker s) => {
    'state': s.state.index,
    'isPriority': s.isPriority,
    'quantity': s.quantity,
  };

  UserSticker _fromMap(String id, Map raw) => UserSticker(
    stickerId: id,
    state: StickerState.values[(raw['state'] as int?) ?? 0],
    isPriority: (raw['isPriority'] as bool?) ?? false,
    quantity: (raw['quantity'] as int?) ?? 1,
  );
}
