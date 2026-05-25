import 'package:la_repe/models/models.dart';

abstract interface class ICollectionDatasource {
  Future<Map<String, UserSticker>> loadCollection();
  Future<void> saveSticker(UserSticker sticker);
  Future<void> removeSticker(String stickerId);
  Future<void> clearCollection();
}
