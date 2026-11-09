import 'package:flutter/foundation.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/widgets/app_selection.dart';

/// Selection state of a list screen.
///
/// Tracks selected item ids next to the index-based [controller] because the
/// list can be reordered or refreshed while items are selected;
/// [resync] re-derives the indices from the ids.
class ListSelectionController {
  ListSelectionController({required VoidCallback onChanged})
    : _onChanged = onChanged {
    controller.addListener(_onChanged);
  }

  final VoidCallback _onChanged;

  final AppSelectionController controller = AppSelectionController();

  final Set<String> _selectedIds = <String>{};

  bool get isSelectionMode => controller.isSelectionMode;

  bool isSelected(int index, String id) =>
      controller.isSelected(index) || _selectedIds.contains(id);

  void clear() {
    _selectedIds.clear();
    controller.clear();
  }

  void toggle(int index, String id) {
    controller.toggle(index);
    if (controller.isSelected(index)) {
      _selectedIds.add(id);
    } else {
      _selectedIds.remove(id);
    }
  }

  /// Selects every item for admins (or without a session); otherwise only the
  /// items [canSelect] accepts.
  void setAllSelected({
    required bool selectAll,
    required List<String> ids,
    required AuthSessionEntity? session,
    required bool Function(int index) canSelect,
  }) {
    clear();
    if (!selectAll) return;

    final isAdmin = session?.role == 'ADMIN' || session == null;
    if (isAdmin) {
      controller.selectAll(ids.length);
      _selectedIds.addAll(ids);
    } else {
      for (var i = 0; i < ids.length; i++) {
        if (canSelect(i)) {
          controller.select(i);
          _selectedIds.add(ids[i]);
        }
      }
    }
  }

  void resync(List<String> ids) {
    if (_selectedIds.isEmpty) return;
    _selectedIds.retainAll(ids);
    controller.clear();
    for (var i = 0; i < ids.length; i++) {
      if (_selectedIds.contains(ids[i])) {
        controller.select(i);
      }
    }
  }

  Set<String> selectedIds(List<String> ids) {
    final result = Set<String>.from(_selectedIds);
    for (final index in controller.selectedIndices) {
      if (index < ids.length) {
        result.add(ids[index]);
      }
    }
    return result;
  }

  void dispose() {
    controller.removeListener(_onChanged);
    controller.dispose();
  }
}
