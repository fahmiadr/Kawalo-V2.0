import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/bootstrap.dart';
import 'package:kawalo_mobile/core/config/env_config.dart';
import 'package:kawalo_mobile/core/config/environment.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/auth_interceptor.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/routes/app_route_observer.dart';
import 'package:kawalo_mobile/core/security/jwks_service.dart';
import 'package:kawalo_mobile/core/security/models/security_violation_type.dart';
import 'package:kawalo_mobile/core/security/presentation/app_security_blocked_screen.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/upload/upload_remote_data_source.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';
import 'package:kawalo_mobile/core/upload/upload_repository_impl.dart';
import 'package:kawalo_mobile/features/attendance/attendance_module.dart';
import 'package:kawalo_mobile/features/attendance/presentation/cubit/attendance_cubit.dart';
import 'package:kawalo_mobile/features/auth/auth_module.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawalo_mobile/features/group/group_module.dart';
import 'package:kawalo_mobile/features/guest/guest_module.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_cubit.dart';
import 'package:kawalo_mobile/features/incident/incident_module.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_cubit.dart';
import 'package:kawalo_mobile/features/information/information_module.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/operational/operational_module.dart';
import 'package:kawalo_mobile/features/operational/presentation/cubit/operational_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/ptt_module.dart';
import 'package:kawalo_mobile/features/splash/presentation/screens/splash_screen.dart';

void main() => bootstrap(AppEnvironment.dev);

class MyApp extends StatefulWidget {
  const MyApp({this.isar, this.securityViolation, super.key});

  final Isar? isar;
  final SecurityViolationType? securityViolation;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final SecureStorageService _storageService;
  late final ApiClient _apiClient;
  late final CacheWiper _cacheWiper;
  late final JwksService _jwksService;
  late final NetworkInfoImpl _networkInfo;
  late final UploadRepository _uploadRepository;
  late final GuestModule _guestModule;
  late final InformationModule _informationModule;
  late final AttendanceModule _attendanceModule;
  late final OperationalModule _operationalModule;
  late final IncidentModule _incidentModule;
  late final AuthBloc _authBloc;
  late final UserSessionCubit _userSessionCubit;
  StreamSubscription<AuthState>? _authSubscription;

  /// Handed to the app so code outside the widget tree (push notification
  /// handlers) can navigate via `AppRouter(() => _navigatorKey.currentState!)`.
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _routeObserver = AppRouteObserver();

  late final bool _isAppLocked;

  @override
  void initState() {
    super.initState();
    _isAppLocked = widget.securityViolation != null || widget.isar == null;
    if (_isAppLocked) {
      return;
    }

    final isar = widget.isar!;

    _storageService = SecureStorageService();
    _apiClient = ApiClient(storage: _storageService);
    _networkInfo = NetworkInfoImpl();
    _uploadRepository = UploadRepositoryImpl(
      remoteDataSource: UploadRemoteDataSource(apiClient: _apiClient),
      networkInfo: _networkInfo,
    );

    final syncStorage = SyncStorageService(storageService: _storageService);

    // Shared dependencies are assembled once here; each module builds its own
    // repository a single time and every cubit reuses it.
    final groupRepository = GroupModule.createRepository(
      apiClient: _apiClient,
      networkInfo: _networkInfo,
    );
    _guestModule = GuestModule(
      apiClient: _apiClient,
      isar: isar,
      networkInfo: _networkInfo,
      syncStorageService: syncStorage,
      groupRepository: groupRepository,
    );
    _informationModule = InformationModule(
      apiClient: _apiClient,
      isar: isar,
      networkInfo: _networkInfo,
      syncStorageService: syncStorage,
      groupRepository: groupRepository,
    );
    _attendanceModule = AttendanceModule(
      apiClient: _apiClient,
      isar: isar,
      networkInfo: _networkInfo,
      syncStorageService: syncStorage,
    );
    _operationalModule = OperationalModule(
      apiClient: _apiClient,
      isar: isar,
      networkInfo: _networkInfo,
      syncStorageService: syncStorage,
    );
    _incidentModule = IncidentModule(
      apiClient: _apiClient,
      isar: isar,
      networkInfo: _networkInfo,
      syncStorageService: syncStorage,
    );

    _cacheWiper = CacheWiper(
      wipeables: [
        for (final module in <CacheWipeableModule>[
          _guestModule,
          _informationModule,
          _attendanceModule,
          _operationalModule,
          _incidentModule,
        ])
          module.cacheWipeable,
      ],
      secureStorageService: _storageService,
      syncStorageService: syncStorage,
    );

    _jwksService = JwksService(
      storageService: _storageService,
      dio: _apiClient.dio,
    );
    _apiClient.jwksService = _jwksService;

    final authRepository = AuthModule.createRepository(
      apiClient: _apiClient,
      storageService: _storageService,
      jwksService: _jwksService,
    );

    _authBloc = AuthModule.createBloc(
      repository: authRepository,
      cacheWiper: _cacheWiper,
    );

    _userSessionCubit = UserSessionCubit();
    _authSubscription = _authBloc.stream.listen((state) {
      if (state is Authenticated) {
        _userSessionCubit.updateSession(state.session);
      } else {
        _userSessionCubit.clearSession();
      }
    });
    if (_authBloc.state is Authenticated) {
      _userSessionCubit.updateSession(
        (_authBloc.state as Authenticated).session,
      );
    }

    _apiClient.onSessionExpired = (reason) {
      final message = reason == SessionExpiredReason.securityAnomaly
          ? 'Sesi Anda tidak valid demi keamanan. Silakan masuk kembali.'
          : 'Sesi Anda telah berakhir demi keamanan. Silakan masuk kembali.';
      _authBloc.add(SessionExpiredRequested(message: message));
    };

    _apiClient.onConnectionFailed = () {
      _networkInfo.checkConnectivity();
    };
  }

  @override
  void dispose() {
    if (!_isAppLocked) {
      _authSubscription?.cancel();
      _userSessionCubit.close();
      _authBloc.close();
      _networkInfo.dispose();
      _apiClient.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAppLocked) {
      return _buildMaterialApp(
        home: AppSecurityBlockedScreen(
          violationType:
              widget.securityViolation ?? SecurityViolationType.rootOrJailbreak,
        ),
      );
    }

    final isar = widget.isar!;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiClient>.value(value: _apiClient),
        RepositoryProvider<CacheWiper>.value(value: _cacheWiper),
        RepositoryProvider<SecureStorageService>.value(value: _storageService),
        RepositoryProvider<NetworkInfo>.value(value: _networkInfo),
        RepositoryProvider<UploadRepository>.value(value: _uploadRepository),
        RepositoryProvider<Isar>.value(value: isar),
        RepositoryProvider<GuestModule>.value(value: _guestModule),
        RepositoryProvider<InformationModule>.value(value: _informationModule),
        RepositoryProvider<IncidentModule>.value(value: _incidentModule),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ConnectivityCubit>(
            create: (context) => ConnectivityCubit(networkInfo: _networkInfo),
          ),
          BlocProvider<UserSessionCubit>.value(value: _userSessionCubit),
          BlocProvider<AuthBloc>.value(value: _authBloc),
          BlocProvider<GuestCubit>(
            create: (context) => _guestModule.createCubit(),
          ),
          BlocProvider<OperationalCubit>(
            create: (context) => _operationalModule.createCubit(),
          ),
          BlocProvider<AttendanceCubit>(
            create: (context) => _attendanceModule.createCubit(),
          ),
          BlocProvider<InformationCubit>(
            create: (context) => _informationModule.createCubit(),
          ),
          BlocProvider<IncidentListCubit>(
            create: (context) => _incidentModule.createIncidentListCubit(),
          ),
          BlocProvider<PttCubit>(
            create: (context) => PttModule.createCubit(
              apiClient: _apiClient,
              storageService: _storageService,
            ),
          ),
        ],
        child: _buildMaterialApp(home: const SplashScreen()),
      ),
    );
  }

  /// Membangun root shell [M3EMaterialApp] dengan konfigurasi tema dan
  /// pelokalan terpusat (DRY).
  Widget _buildMaterialApp({required Widget home}) {
    return M3EMaterialApp(
      title: EnvConfig.appName,
      data: AppTheme.m3eLight(),
      fontFamily: AppTheme.defaultFontFamily,
      autoTheming: true,
      dynamicColoring: false,
      localizationsDelegates: AppTheme.localizationsDelegates,
      supportedLocales: AppTheme.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null) {
          for (final supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }
        }
        return supportedLocales.first;
      },
      navigatorKey: _navigatorKey,
      navigatorObservers: [_routeObserver],
      home: home,
    );
  }
}
