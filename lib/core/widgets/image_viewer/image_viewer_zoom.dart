import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Membatasi pergeseran matriks transformasi agar foto tidak pernah keluar
/// dari area penglihatan, baik secara horizontal maupun vertikal.
Matrix4 clampImageViewerMatrix(
  Matrix4 matrix,
  Size? imageSize,
  Size viewportSize,
) {
  if (viewportSize.width <= 0 || viewportSize.height <= 0) return matrix;

  final scale = matrix.getMaxScaleOnAxis();
  if (scale <= 1.0) {
    return Matrix4.identity();
  }

  final resolvedImageSize = imageSize ?? viewportSize;
  final fittedSizes = applyBoxFit(
    BoxFit.contain,
    resolvedImageSize,
    viewportSize,
  );
  final destSize = fittedSizes.destination;

  final unscaledLeft = (viewportSize.width - destSize.width) / 2;
  final unscaledTop = (viewportSize.height - destSize.height) / 2;

  var tx = matrix.storage[12];
  var ty = matrix.storage[13];

  // ── Batasan Horizontal (Smooth Clamping) ─────────────────────────
  final boundX1 = -unscaledLeft * scale;
  final boundX2 = viewportSize.width - (unscaledLeft + destSize.width) * scale;
  final minTx = math.min(boundX1, boundX2);
  final maxTx = math.max(boundX1, boundX2);
  tx = tx.clamp(minTx, maxTx);

  // ── Batasan Vertikal (Smooth Clamping Tanpa Reset) ───────────────
  final boundY1 = -unscaledTop * scale;
  final boundY2 = viewportSize.height - (unscaledTop + destSize.height) * scale;
  final minTy = math.min(boundY1, boundY2);
  final maxTy = math.max(boundY1, boundY2);
  ty = ty.clamp(minTy, maxTy);

  return matrix.clone()
    ..storage[12] = tx
    ..storage[13] = ty;
}
