import 'package:shared_preferences/shared_preferences.dart';
import 'package:la_repe/data/datasources/i_user_datasource.dart';
import 'package:la_repe/models/models.dart';

class UserLocalDatasource implements IUserDatasource {
  static const _keyName = 'user_name';
  static const _keyCity = 'user_city';
  static const _keyCountry = 'user_country';
  static const _keyWhatsapp = 'user_whatsapp';

  @override
  Future<AppUser?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyName);
    if (name == null || name.isEmpty) return null;
    return AppUser(
      name: name,
      city: prefs.getString(_keyCity) ?? '',
      country: prefs.getString(_keyCountry) ?? '',
      whatsapp: prefs.getString(_keyWhatsapp) ?? '',
    );
  }

  @override
  Future<void> saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_keyName, user.name),
      prefs.setString(_keyCity, user.city),
      prefs.setString(_keyCountry, user.country),
      prefs.setString(_keyWhatsapp, user.whatsapp),
    ]);
  }

  @override
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_keyName),
      prefs.remove(_keyCity),
      prefs.remove(_keyCountry),
      prefs.remove(_keyWhatsapp),
    ]);
  }
}
