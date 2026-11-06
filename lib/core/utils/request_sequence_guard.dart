import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';

/// Mixin untuk melindungi State Management (Cubit / Bloc) dari:
/// 1. Out-of-Order asynchronous responses dan race condition.
/// 2. In-flight duplicate invocations (mencegah pemanggilan ganda paralel).
/// 3. Superseded search/filter cancellation via [AppCancellationToken].
mixin RequestSequenceGuard {
  int _latestRequestId = 0;
  bool _isFetching = false;
  AppCancellationToken? _activeSearchCancelToken;

  /// Menghasilkan ID unik berurutan untuk request baru yang diluncurkan.
  int nextRequestId() => ++_latestRequestId;

  /// Memvalidasi apakah [requestId] yang diberikan masih merupakan
  /// request paling mutakhir yang valid untuk di-emit ke state UI.
  bool isLatest(int requestId) => requestId == _latestRequestId;

  /// Status apakah ada operasi request yang sedang berlangsung.
  bool get isFetching => _isFetching;

  /// Memperbarui status aktivitas request.
  set isFetching(bool value) => _isFetching = value;

  /// Membatalkan token pencarian aktif sebelumnya dan mengembalikan token baru.
  AppCancellationToken renewSearchCancelToken() {
    _activeSearchCancelToken?.cancel('superseded');
    final token = DioCancellationToken();
    _activeSearchCancelToken = token;
    return token;
  }

  /// Token pencarian aktif saat ini (opsional).
  AppCancellationToken? get activeSearchCancelToken => _activeSearchCancelToken;

  /// Membatalkan request pencarian aktif jika ada.
  void cancelActiveSearch() {
    _activeSearchCancelToken?.cancel('superseded');
    _activeSearchCancelToken = null;
  }

  /// Menggugurkan seluruh request yang sedang berjalan dengan menaikkan
  /// counter ID, sehingga callback async yang belum selesai akan diabaikan.
  void invalidateRequests() {
    _latestRequestId++;
    _isFetching = false;
    cancelActiveSearch();
  }
}
