import 'dart:ui';

class QuadTree<T> {
  final Size bounds;
  final Offset anchor;
  final int maxPoints;
  List<QuadTreePoint<T>> points = [];
  QuadTree({
    required this.bounds,
    required this.anchor,
    required this.maxPoints,
  });
  QuadTree<T>? northWest;
  QuadTree<T>? northEast;
  QuadTree<T>? southWest;
  QuadTree<T>? southEast;

  List<QuadTreePoint<T>> query(Offset position, double size) {
    List<QuadTreePoint<T>> founded = [];
    final isInX = position.dx + size >= anchor.dx &&
        position.dx - size <= anchor.dx + bounds.width;
    if (!isInX) return founded;
    final isInY = position.dy + size >= anchor.dy &&
        position.dy - size <= anchor.dy + bounds.height;
    if (!isInY) return founded;

    for (final point in points) {
      if (point.isInside(
        Offset(
          position.dx - size,
          position.dy - size,
        ),
        Size(
          size * 2,
          size * 2,
        ),
      )) {
        founded.add(point);
      }
    }
    if (northWest == null) return founded;
    founded.addAll(northWest?.query(position, size) ?? []);
    founded.addAll(northEast?.query(position, size) ?? []);
    founded.addAll(southWest?.query(position, size) ?? []);
    founded.addAll(southEast?.query(position, size) ?? []);
    return founded;
  }

  addAll(List<QuadTreePoint<T>> newPoints) {
    for (final point in newPoints) {
      add(point);
    }
  }

  bool add(QuadTreePoint<T> point) {
    if (!point.isInside(anchor, bounds)) return false;
    if (points.length < maxPoints && northWest == null) {
      points.add(point);
      return true;
    }
    if (northWest == null) {
      subdivide();
    }
    if (northWest?.add(point) ?? false) return true;
    if (northEast?.add(point) ?? false) return true;
    if (southWest?.add(point) ?? false) return true;
    if (southEast?.add(point) ?? false) return true;
    return false;
  }

  subdivide() {
    final newBounds = bounds / 2;
    northWest = QuadTree<T>(
      bounds: newBounds,
      anchor: anchor,
      maxPoints: maxPoints,
    );
    northEast = QuadTree<T>(
      bounds: newBounds,
      anchor: Offset(
        anchor.dx + bounds.width / 2,
        anchor.dy,
      ),
      maxPoints: maxPoints,
    );
    southWest = QuadTree<T>(
      bounds: newBounds,
      anchor: Offset(
        anchor.dx,
        anchor.dy + bounds.height / 2,
      ),
      maxPoints: maxPoints,
    );
    southEast = QuadTree<T>(
      bounds: newBounds,
      anchor: Offset(
        anchor.dx + bounds.width / 2,
        anchor.dy + bounds.height / 2,
      ),
      maxPoints: maxPoints,
    );
  }

  List<(Offset anc, Size s)> paint() {
    List<(Offset anc, Size s)> quads = [(anchor, bounds)];
    quads.addAll(northWest?.paint() ?? []);
    quads.addAll(northEast?.paint() ?? []);
    quads.addAll(southWest?.paint() ?? []);
    quads.addAll(southEast?.paint() ?? []);
    return quads;
  }
}

class QuadTreePoint<T> {
  final Offset position;
  final T data;
  const QuadTreePoint({
    required this.position,
    required this.data,
  });

  bool isInside(Offset anchor, Size bounds) {
    final isInX =
        position.dx >= anchor.dx && position.dx <= anchor.dx + bounds.width;
    final isInY =
        position.dy >= anchor.dy && position.dy <= anchor.dy + bounds.height;
    return isInX && isInY;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is QuadTreePoint &&
        other.position == position &&
        other.data == data;
  }

  @override
  int get hashCode => position.hashCode ^ data.hashCode;
}
