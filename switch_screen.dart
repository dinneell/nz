import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';


abstract class ThemeEvent {}
class ToggleTheme extends ThemeEvent {}
class SetTheme extends ThemeEvent {
  final bool isDark;
  SetTheme(this.isDark);
}


enum AppTheme { light, dark }


class ThemeBloc extends Bloc<ThemeEvent, AppTheme> {
  ThemeBloc() : super(AppTheme.light) {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkTheme') ?? false;
    emit(isDark ? AppTheme.dark : AppTheme.light);
  }

  void _saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkTheme', isDark);
  }

  @override
  Stream<AppTheme> mapEventToState(ThemeEvent event) async* {
    if (event is ToggleTheme) {
      final newTheme = state == AppTheme.light ? AppTheme.dark : AppTheme.light;
      _saveTheme(newTheme == AppTheme.dark);
      yield newTheme;
    } else if (event is SetTheme) {
      _saveTheme(event.isDark);
      yield event.isDark ? AppTheme.dark : AppTheme.light;
    }
  }
}


class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Профиль")),
      body: BlocBuilder<ThemeBloc, AppTheme>(
        builder: (context, theme) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Настройки", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: Icon(Icons.brightness_6, color: Colors.yellow),
                title: Text("Тема"),
                trailing: Text(theme == AppTheme.light ? "Светлая" : "Тёмная"),
                onTap: () => _showThemeDialog(context, theme),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showThemeDialog(BuildContext context, AppTheme currentTheme) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        bool isDark = currentTheme == AppTheme.dark;
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Выберите тему", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _themeOption(context, "Светлая", false, isDark, setState),
                      SizedBox(width: 20),
                      _themeOption(context, "Тёмная", true, isDark, setState),
                    ],
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.black,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      context.read<ThemeBloc>().add(SetTheme(isDark));
                      Navigator.pop(context);
                    },
                    child: Text("Сохранить"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _themeOption(BuildContext context, String text, bool darkValue, bool currentDark, Function setState) {
    return GestureDetector(
      onTap: () {
        setState(() => currentDark = darkValue);
      },
      child: Column(
        children: [
          Container(
            width: 100,
            height: 150,
            decoration: BoxDecoration(
              color: darkValue ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: currentDark == darkValue ? Colors.yellow : Colors.grey,
                width: 3,
              ),
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<bool>(
                value: darkValue,
                groupValue: currentDark,
                onChanged: (value) {
                  setState(() => currentDark = value!);
                },
              ),
              Text(text),
            ],
          ),
        ],
      ),
    );
  }
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ThemeBloc(),
      child: BlocBuilder<ThemeBloc, AppTheme>(
        builder: (context, theme) {
          return MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: theme == AppTheme.light ? ThemeMode.light : ThemeMode.dark,
            home: SettingsScreen(),
          );
        },
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}
