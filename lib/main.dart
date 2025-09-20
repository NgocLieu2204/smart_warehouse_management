// lib/main.dart (ĐÃ SỬA LỖI VÀ HOÀN THIỆN MÀU SẮC)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'repositories/auth_repository.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'views/auth/login_screen.dart';
import 'views/main/main_screen.dart';
import 'views/main/splash_screen.dart';
import 'blocs/theme/theme_bloc.dart'; // Đảm bảo bạn đã tạo file BLoC cho theme

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),

      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(authRepository)
          ),
         
          BlocProvider<ThemeBloc>(
            create: (context) => ThemeBloc(),
          ),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            // Định nghĩa Light Theme
            final lightTheme = ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.deepPurple,
              textTheme: GoogleFonts.poppinsTextTheme(),
              scaffoldBackgroundColor: const Color(0xFFF5F5F7),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.black),
                titleTextStyle: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 1,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              colorScheme: ColorScheme.fromSwatch(
                primarySwatch: Colors.deepPurple,
                brightness: Brightness.light,
              ).copyWith(
                secondary: const Color(0xFFFFC107),
                tertiary: const Color(0xFF00BFFF),
                error: Colors.red.shade400,
              ),
            );

            // Định nghĩa Dark Theme (ĐÃ TINH CHỈNH)
            final darkTheme = ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.teal,
              scaffoldBackgroundColor: const Color(0xFF121212),
              textTheme:
                  GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
              appBarTheme: AppBarTheme(
                backgroundColor: const Color(0xFF1F1F1F),
                elevation: 0,
                titleTextStyle: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                color: const Color(0xFF1E1E1E), 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              switchTheme: SwitchThemeData(
                thumbColor: MaterialStateProperty.all(Colors.white),
                trackColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.tealAccent.withOpacity(0.5);
                  }
                  return Colors.grey.shade700;
                }),
              ),
              colorScheme: ColorScheme.fromSwatch(
                primarySwatch: Colors.teal,
                brightness: Brightness.dark,
              ).copyWith(
                secondary: Colors.yellowAccent,
                tertiary: Colors.cyanAccent,
                error: Colors.red.shade800,
              ),
            );

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Smart Warehouse',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeState.themeMode, 
              home: const AuthWrapper(),
            );
          },
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return const MainScreen();
        } else if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}