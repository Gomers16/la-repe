import 'package:la_repe/models/models.dart';

abstract interface class IUserDatasource {
  Future<AppUser?> loadUser();
  Future<void> saveUser(AppUser user);
  Future<void> clearUser();
}
