import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

/// ---------- Локальная "авторизация" (без Firebase) ----------
class UserData {
  final String login;
  final String password;
  final String fullName;
  final int cats;
  final String gender;
  final String? language;
  final String about;

  const UserData({
    required this.login,
    required this.password,
    required this.fullName,
    this.cats = 0,
    this.gender = 'М',
    this.language,
    this.about = '',
  });
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final Map<String, UserData> _users = {
    'admin': const UserData(
        login: 'admin', password: '1234', fullName: 'Администратор'),
  };

  UserData? currentUser;

  /// Возвращает true, если логин и пароль верные.
  bool signIn(String login, String password) {
    final user = _users[login.trim()];
    if (user != null && user.password == password) {
      currentUser = user;
      return true;
    }
    return false;
  }

  /// Возвращает false, если такой логин уже занят.
  bool register(UserData user) {
    if (_users.containsKey(user.login)) return false;
    _users[user.login] = user;
    currentUser = user;
    return true;
  }

  void signOut() => currentUser = null;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Что-то',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const LoginScreen(),
    );
  }
}

/// ---------- Экран авторизации ----------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _login() {
    if (AuthService.instance.signIn(_loginCtrl.text, _passCtrl.text)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный логин или пароль')),
      );
    }
  }

  void _openRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Авторизация',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
                const SizedBox(height: 40),
                TextField(
                  controller: _loginCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Login',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  onSubmitted: (_) => _login(),
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(onPressed: _login, child: const Text('Войти')),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _openRegistration,
                  child: const Text(
                    'Зарегистрироваться',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------- Главный экран ----------
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Главный экран'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () {
              AuthService.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Главный экран приложения\nПривет, ${user?.fullName ?? ''}!',
            textAlign: TextAlign.center),
      ),
    );
  }
}

/// ---------- Экран регистрации ----------
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();

  bool _isAdult = true;
  int _cats = 4;
  String _gender = 'М';
  String? _language;

  static const _languages = [
    'Dart',
    'Kotlin',
    'Swift',
    'Java',
    'Python',
    'JavaScript',
    'C#',
  ];

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _aboutCtrl.dispose();
    super.dispose();
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;
    if (!_isAdult) {
      _snack('Необходимо подтвердить возраст');
      return;
    }
    final ok = AuthService.instance.register(UserData(
      login: _loginCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      cats: _cats,
      gender: _gender,
      language: _language,
      about: _aboutCtrl.text.trim(),
    ));
    if (!ok) {
      _snack('Такой логин уже занят');
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (_) => false,
    );
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация на Что-то')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _loginCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Логин',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Введите логин' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Пароль',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) => (v == null || v.length < 4)
                      ? 'Минимум 4 символа'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ФИО',
                    hintText: 'Placeholder',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Введите ФИО' : null,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Мне исполнилось 14 лет'),
                  value: _isAdult,
                  onChanged: (v) => setState(() => _isAdult = v ?? false),
                ),
                Row(
                  children: [
                    const Text('Количество котов:'),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed:
                          _cats > 0 ? () => setState(() => _cats--) : null,
                    ),
                    Text('$_cats',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() => _cats++),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Пол:'),
                    const SizedBox(width: 12),
                    Radio<String>(
                      value: 'М',
                      groupValue: _gender,
                      onChanged: (v) => setState(() => _gender = v!),
                    ),
                    const Text('М'),
                    const SizedBox(width: 12),
                    Radio<String>(
                      value: 'Ж',
                      groupValue: _gender,
                      onChanged: (v) => setState(() => _gender = v!),
                    ),
                    const Text('Ж'),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _language,
                  isDense: true,
                  hint: const Text('Select'),
                  decoration: const InputDecoration(
                    labelText: 'Любимый язык программирования',
                    border: OutlineInputBorder(),
                  ),
                  items: _languages
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) => setState(() => _language = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _aboutCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Немного о себе',
                    hintText: 'Type here',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: FilledButton(
                    onPressed: _register,
                    child: const Text('Зарегистрироваться'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
