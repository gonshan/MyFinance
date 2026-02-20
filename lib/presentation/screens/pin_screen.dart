import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart'; // Биометрия
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import 'main_wrapper.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String? _storedPin;
  bool _isLoading = true;
  bool _isError = false;
  late AnimationController _shakeController;

  // Биометрия
  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false; // Есть ли "железо"
  bool _isBiometricsEnabled = false; // Включил ли юзер в настройках

  // Блокировка
  int _failedAttempts = 0;
  DateTime? _lockoutEndTime;
  Timer? _timer;
  String _timerText = "";

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isError = false;
          _enteredPin = '';
          _shakeController.reset();
        });
      }
    });

    _checkLoginStatus();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString('user_pin');

    // Читаем настройку пользователя (по умолчанию false)
    final useBio = prefs.getBool('use_biometrics') ?? false;

    // Проверка блокировки
    final lockoutMillis = prefs.getInt('lockout_end_time');
    final attempts = prefs.getInt('failed_attempts') ?? 0;

    // Проверка доступности биометрии ("железо")
    bool canCheck = false;
    try {
      canCheck =
          await auth.canCheckBiometrics && await auth.isDeviceSupported();
    } catch (e) {
      debugPrint("Ошибка биометрии: $e");
    }

    if (!mounted) return;

    setState(() {
      _storedPin = pin;
      _failedAttempts = attempts;
      _canCheckBiometrics = canCheck;
      _isBiometricsEnabled = useBio; // Сохраняем настройку в состояние
      _isLoading = false;
    });

    if (lockoutMillis != null) {
      final endTime = DateTime.fromMillisecondsSinceEpoch(lockoutMillis);
      if (DateTime.now().isBefore(endTime)) {
        _lockoutEndTime = endTime;
        _startTimer();
      } else {
        _resetLockout(prefs);
      }
    } else {
      // АВТОЗАПУСК: Если есть пин, железо позволяет И юзер включил настройку
      if (_storedPin != null && _canCheckBiometrics && _isBiometricsEnabled) {
        _authenticate();
      }
    }
  }

  // Метод вызова биометрии
  Future<void> _authenticate() async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Сканируйте отпечаток или лицо для входа',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        _navigateToHome();
      }
    } on PlatformException catch (e) {
      debugPrint("Ошибка авторизации: $e");
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockoutEndTime == null) return;

      final now = DateTime.now();
      if (now.isAfter(_lockoutEndTime!)) {
        timer.cancel();
        _unlockApp();
      } else {
        final remaining = _lockoutEndTime!.difference(now);
        final minutes = remaining.inMinutes.toString().padLeft(2, '0');
        final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
        setState(() {
          _timerText = "$minutes:$seconds";
        });
      }
    });
  }

  Future<void> _unlockApp() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetLockout(prefs);
    setState(() {
      _lockoutEndTime = null;
    });
  }

  Future<void> _resetLockout(SharedPreferences prefs) async {
    await prefs.remove('lockout_end_time');
    await prefs.setInt('failed_attempts', 0);
    setState(() {
      _failedAttempts = 0;
    });
  }

  void _onKeyTap(String value) {
    if (_lockoutEndTime != null || _enteredPin.length >= 4 || _isError) return;

    setState(() {
      _enteredPin += value;
    });

    if (_enteredPin.length == 4) {
      _validatePin();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty && !_isError && _lockoutEndTime == null) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _validatePin() async {
    await Future.delayed(const Duration(milliseconds: 150));

    if (_storedPin == null) {
      // Создание нового пина
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_pin', _enteredPin);
      _navigateToHome();
    } else {
      // Проверка существующего
      if (_enteredPin == _storedPin) {
        final prefs = await SharedPreferences.getInstance();
        await _resetLockout(prefs);
        _navigateToHome();
      } else {
        final prefs = await SharedPreferences.getInstance();
        _failedAttempts++;
        await prefs.setInt('failed_attempts', _failedAttempts);

        if (_failedAttempts >= 5) {
          final endTime = DateTime.now().add(const Duration(minutes: 2));
          await prefs.setInt(
            'lockout_end_time',
            endTime.millisecondsSinceEpoch,
          );

          setState(() {
            _lockoutEndTime = endTime;
            _isError = true;
          });
          _startTimer();

          Future.delayed(const Duration(milliseconds: 500), () {
            setState(() {
              _enteredPin = '';
              _isError = false;
            });
          });
        } else {
          setState(() {
            _isError = true;
          });
          _shakeController.forward();
        }
      }
    }
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(backgroundColor: AppColors.background);

    final isCreating = _storedPin == null;
    final isLocked = _lockoutEndTime != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              if (isLocked) ...[
                const Icon(
                  Icons.lock_clock_rounded,
                  size: 80,
                  color: AppColors.secondarySalmon,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Приложение заблокировано",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondarySalmon,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Попробуйте через $_timerText",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textGrey,
                  ),
                ),
              ] else ...[
                Icon(
                  isCreating
                      ? Icons.lock_outline_rounded
                      : Icons.lock_open_rounded,
                  size: 40,
                  color: _isError
                      ? AppColors.secondarySalmon
                      : AppColors.primaryMint,
                ),
                const SizedBox(height: 20),
                Text(
                  _isError
                      ? "Неверный код (${5 - _failedAttempts} поп.)"
                      : (isCreating ? "Придумайте код" : "Введите код"),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isError
                        ? AppColors.secondarySalmon
                        : AppColors.textDark,
                  ),
                ),
              ],

              const SizedBox(height: 30),

              if (!isLocked)
                AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    final sineValue = sin(3 * 2 * pi * _shakeController.value);
                    return Transform.translate(
                      offset: Offset(sineValue * 10, 0),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < _enteredPin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isFilled
                              ? (_isError
                                    ? AppColors.secondarySalmon
                                    : AppColors.textDark)
                              : Colors.transparent,
                          border: Border.all(
                            color: _isError
                                ? AppColors.secondarySalmon
                                : AppColors.textDark,
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                ),

              const Spacer(flex: 3),

              if (!isLocked)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildRow(['1', '2', '3']),
                    const SizedBox(height: 15),
                    _buildRow(['4', '5', '6']),
                    const SizedBox(height: 15),
                    _buildRow(['7', '8', '9']),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: 240,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Кнопка биометрии (слева от 0)
                          // Показываем только если ПИН создан, железо есть И ВКЛЮЧЕНО В НАСТРОЙКАХ
                          SizedBox(
                            width: 65,
                            height: 65,
                            child:
                                (_storedPin != null &&
                                    _canCheckBiometrics &&
                                    _isBiometricsEnabled)
                                ? InkWell(
                                    onTap: _authenticate,
                                    borderRadius: BorderRadius.circular(35),
                                    child: const Icon(
                                      Icons.fingerprint_rounded,
                                      size: 36,
                                      color: AppColors.primaryMint,
                                    ),
                                  )
                                : null, // Иначе пустое место
                          ),

                          _buildKey('0'),
                          _buildBackspace(),
                        ],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return SizedBox(
      width: 240,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: keys.map((k) => _buildKey(k)).toList(),
      ),
    );
  }

  Widget _buildKey(String val) {
    return InkWell(
      onTap: () => _onKeyTap(val),
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 65,
        height: 65,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(2, 2),
            ),
            const BoxShadow(
              color: Colors.white,
              blurRadius: 5,
              offset: Offset(-2, -2),
            ),
          ],
        ),
        child: Text(
          val,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildBackspace() {
    return InkWell(
      onTap: _onBackspace,
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 65,
        height: 65,
        alignment: Alignment.center,
        child: const Icon(
          Icons.backspace_rounded,
          color: AppColors.textGrey,
          size: 28,
        ),
      ),
    );
  }
}
