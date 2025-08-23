import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState(themeMode: ThemeMode.light)) {
    on<ThemeChanged>((event, emit) {
      final themeMode = event.isDarkMode ? ThemeMode.dark : ThemeMode.light;
      emit(ThemeState(themeMode: themeMode));
    });
  }
}