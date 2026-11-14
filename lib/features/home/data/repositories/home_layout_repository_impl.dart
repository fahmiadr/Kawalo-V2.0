import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/features/home/data/datasources/home_layout_remote_data_source.dart';
import 'package:kawalo_mobile/features/home/data/models/home_layout_model.dart';
import 'package:kawalo_mobile/features/home/domain/entities/home_layout.dart';
import 'package:kawalo_mobile/features/home/domain/repositories/home_layout_repository.dart';

/// Local copy first, server when reachable. The local entry is
/// `{"layout": <PUT body>, "pending": bool}`; `pending` marks a change the
/// server has not accepted yet, which [load] sends before reading.
class HomeLayoutRepositoryImpl implements HomeLayoutRepository {
  const HomeLayoutRepositoryImpl({
    required this.remoteDataSource,
    required this.storage,
  });

  final HomeLayoutRemoteDataSource remoteDataSource;
  final SecureStorageService storage;

  @override
  Future<HomeLayout?> cached(String scope) async =>
      (await _readLocal(scope))?.layout;

  @override
  Future<HomeLayout> load(String scope) async {
    final local = await _readLocal(scope);
    if (local != null && local.pending) {
      return await _send(scope, local.layout);
    }
    try {
      final layout = (await remoteDataSource.get()).toEntity();
      await _writeLocal(scope, layout, pending: false);
      return layout;
    } on Exception catch (e) {
      // 404 until the endpoint is deployed, or offline.
      debugPrint('[HomeLayout] load failed: $e');
      return local?.layout ?? HomeLayout.fallback;
    }
  }

  @override
  Future<HomeLayout> save(String scope, HomeLayout layout) async {
    await _writeLocal(scope, layout, pending: true);
    return await _send(scope, layout);
  }

  Future<HomeLayout> _send(String scope, HomeLayout layout) async {
    try {
      final saved = (await remoteDataSource.put(
        HomeLayoutModel.fromEntity(layout),
      )).toEntity();
      await _writeLocal(scope, saved, pending: false);
      return saved;
    } on Exception catch (e) {
      final failure = NetworkErrorHandler.handleExceptionToFailure(e);
      debugPrint('[HomeLayout] save failed: ${failure.message}');
      // A 422 will be refused again on every retry: keep the layout on this
      // device but stop resending it.
      if (failure.statusCode == 422) {
        await _writeLocal(scope, layout, pending: false);
      }
      return layout;
    }
  }

  Future<({HomeLayout layout, bool pending})?> _readLocal(String scope) async {
    try {
      final raw = await storage.getHomeLayout(scope);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (
        layout: HomeLayoutModel.fromJson(
          json['layout'] as Map<String, dynamic>,
        ).toEntity(),
        pending: json['pending'] == true,
      );
    } on Object catch (_) {
      return null;
    }
  }

  Future<void> _writeLocal(
    String scope,
    HomeLayout layout, {
    required bool pending,
  }) async {
    try {
      await storage.saveHomeLayout(
        scope,
        jsonEncode({
          'layout': HomeLayoutModel.fromEntity(layout).toJson(),
          'pending': pending,
        }),
      );
    } on Object catch (_) {}
  }
}
