import 'package:la_repe/data/datasources/i_user_datasource.dart';
import 'package:la_repe/models/models.dart';

class UserRepository {
  final IUserDatasource _datasource;

  UserRepository(this._datasource);

  Future<AppUser?> loadUser() => _datasource.loadUser();
  Future<void> saveUser(AppUser user) => _datasource.saveUser(user);
  Future<void> clearUser() => _datasource.clearUser();
}
