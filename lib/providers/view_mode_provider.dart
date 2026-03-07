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
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final saved = prefs.getString(_prefsKey);
      if (saved == 'kanban' || saved == 'list') {
        state = saved!;
      }
    } catch (_) {
      // SharedPreferences may be unavailable in test environments.
      // Swallow the error — the default 'list' mode is fine.
    }
  }

  void toggle() {
    final next = state == 'kanban' ? 'list' : 'kanban';
    state = next;
    _persist(next);
  }

  void set(String mode) {
    if (mode != 'kanban' && mode != 'list') return;
    state = mode;
    _persist(mode);
  }

  void _persist(String mode) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_prefsKey, mode);
    }).catchError((_) {});
  }
}
