import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'view_mode';

final viewModeProvider =
    StateNotifierProvider<ViewModeNotifier, String>((ref) {
  return ViewModeNotifier();
});

class ViewModeNotifier extends StateNotifier<String> {
  ViewModeNotifier() : super('list') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == 'kanban' || saved == 'list') {
      state = saved!;
    }
  }

  void toggle() {
    final next = state == 'kanban' ? 'list' : 'kanban';
    state = next;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_prefsKey, next);
    });
  }

  void set(String mode) {
    if (mode != 'kanban' && mode != 'list') return;
    state = mode;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_prefsKey, mode);
    });
  }
}
