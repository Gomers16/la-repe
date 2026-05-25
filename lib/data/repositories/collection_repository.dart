import 'package:la_repe/data/datasources/i_collection_datasource.dart';
import 'package:la_repe/models/models.dart';

class CollectionRepository {
  final ICollectionDatasource _datasource;

  CollectionRepository(this._datasource);

  Future<Map<String, UserSticker>> loadCollection() =>
      _datasource.loadCollection();

  Future<void> saveSticker(UserSticker sticker) =>
      _datasource.saveSticker(sticker);

  Future<void> removeSticker(String stickerId) =>
      _datasource.removeSticker(stickerId);

  Future<void> clearCollection() => _datasource.clearCollection();
}
