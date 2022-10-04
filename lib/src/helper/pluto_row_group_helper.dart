import 'package:collection/collection.dart';
import 'package:pluto_grid/pluto_grid.dart';

class PlutoRowGroupHelper {
  static Iterable<PlutoRow> iterateWithFilter(
    Iterable<PlutoRow> rows, [
    bool Function(PlutoRow)? filter,
    Iterator<PlutoRow>? Function(PlutoRow)? childrenFilter,
  ]) sync* {
    if (rows.isEmpty) return;

    final List<Iterator<PlutoRow>> stack = [];

    Iterator<PlutoRow>? currentIter = rows.iterator;

    Iterator<PlutoRow>? defaultChildrenFilter(PlutoRow row) {
      return row.type.isGroup
          ? row.type.group.children.originalList.iterator
          : null;
    }

    final filterChildren = childrenFilter ?? defaultChildrenFilter;

    while (currentIter != null || stack.isNotEmpty) {
      bool hasChildren = false;

      if (currentIter != null) {
        while (currentIter!.moveNext()) {
          if (filter == null || filter(currentIter.current)) {
            yield currentIter.current;
          }

          final Iterator<PlutoRow>? children = filterChildren(
            currentIter.current,
          );

          if (children != null) {
            stack.add(currentIter);
            currentIter = children;
            hasChildren = true;
            break;
          }
        }
      }

      if (!hasChildren) {
        currentIter = stack.lastOrNull;
        if (currentIter != null) stack.removeLast();
      }
    }
  }

  static void applyFilter({
    required FilteredList<PlutoRow> rows,
    required FilteredListFilter<PlutoRow>? filter,
  }) {
    if (rows.originalList.isEmpty) return;

    isGroup(PlutoRow row) => row.type.isGroup;

    if (filter == null) {
      rows.setFilter(null);

      final children = PlutoRowGroupHelper.iterateWithFilter(
        rows.originalList,
        isGroup,
      );

      for (final child in children) {
        child.type.group.children.setFilter(null);
      }
    } else {
      isNotEmptyGroup(PlutoRow row) =>
          row.type.isGroup &&
          row.type.group.children.filterOrOriginalList.isNotEmpty;

      filterOrHasChildren(PlutoRow row) => filter(row) || isNotEmptyGroup(row);

      final children = PlutoRowGroupHelper.iterateWithFilter(
        rows.originalList,
        isGroup,
      );

      for (final child in children.toList().reversed) {
        child.type.group.children.setFilter(filterOrHasChildren);
      }

      rows.setFilter(filterOrHasChildren);
    }
  }
}