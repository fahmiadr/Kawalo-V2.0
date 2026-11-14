import 'package:kawalo_mobile/features/home/domain/entities/home_layout.dart';

/// Beranda layout of one user in one group (`scope`). Never fails: the
/// endpoint may be missing (older server) or offline, so every method falls
/// back to the local copy or [HomeLayout.fallback].
abstract interface class HomeLayoutRepository {
  /// The last layout stored on this device, without network.
  Future<HomeLayout?> cached(String scope);

  /// Server layout, or the cached one when the server cannot be reached.
  /// A local change not yet accepted by the server is sent first.
  Future<HomeLayout> load(String scope);

  /// Stores [layout] locally at once, then sends it. Returns the server's copy,
  /// or [layout] when sending failed (it is retried by the next [load]).
  Future<HomeLayout> save(String scope, HomeLayout layout);
}
