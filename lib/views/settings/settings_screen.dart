// lib/views/settings/settings_screen.dart (ĐÃ HOÀN THIỆN)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/buttton.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/theme/theme_bloc.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String _role = 'user';

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeBloc>().state.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cài đặt',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Chế độ tối'),
                  value: isDarkMode,
                  activeColor: Colors.blue, // Màu khi công tắc BẬT
                  inactiveThumbColor: Colors.grey, // Màu của núm tròn khi TẮT
                  inactiveTrackColor: Colors.grey[300], // Màu của thanh trượt khi TẮT
                  onChanged: (bool value) {
                    context.read<ThemeBloc>().add(ThemeChanged(isDarkMode: value));
                  },
                ),
                ListTile(
                  title: const Text('Vai trò'),
                  trailing: DropdownButton<String>(
                    value: _role,
                    onChanged: (String? newValue) {
                      setState(() {
                        _role = newValue!;
                      });
                    },
                    items: <String>['user', 'admin']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                            value[0].toUpperCase() + value.substring(1)),
                      );
                    }).toList(),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Gợi ý: Với Admin, thẻ cảnh báo sẽ phát sáng mạnh hơn.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                 Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    child: Text('Đăng xuất'),
                    onPressed: () {
                      context.read<AuthBloc>().add(LogoutRequested());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      textStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      alignment: Alignment.center,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}