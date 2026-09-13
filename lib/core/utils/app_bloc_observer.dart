import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (kDebugMode) {
      debugPrint('🔄 [BLOC] ${bloc.runtimeType}: ${change.currentState.runtimeType} -> ${change.nextState.runtimeType}');
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('🚨 [CUBIT/BLOC ERROR] in ${bloc.runtimeType}: $error');
    }
    super.onError(bloc, error, stackTrace);
  }
}
