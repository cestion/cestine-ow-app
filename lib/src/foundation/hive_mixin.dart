import 'package:hive/hive.dart';

mixin HiveMixin<T> {
  String get boxName;
  Box<T>? _box;

  bool get isBoxOpen => _box?.isOpen ?? false;

  Future<void> initBox() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox<T>(boxName);
  }

  Box<T> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError(
        'Hive box "$boxName" is not open. Call initBox() first.',
      );
    }
    return _box!;
  }

  Future<void> disposeBox() async {
    await _box?.close();
    _box = null;
  }
}
