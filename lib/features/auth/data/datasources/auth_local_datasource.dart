import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String userBoxName = 'user_box';
  static const String userKey = 'cached_user';

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      final box = await Hive.openBox(userBoxName);
      await box.put(userKey, user.toJson());
    } catch (e) {
      throw CacheException('Failed to cache user');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final box = await Hive.openBox(userBoxName);
      final userData = box.get(userKey);
      if (userData == null) return null;
      return UserModel.fromJson(Map<String, dynamic>.from(userData));
    } catch (e) {
      throw CacheException('Failed to get cached user');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final box = await Hive.openBox(userBoxName);
      await box.clear();
    } catch (e) {
      throw CacheException('Failed to clear cache');
    }
  }
}
