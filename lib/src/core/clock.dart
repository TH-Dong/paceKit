abstract interface class AppClock {
  DateTime now();
}

class SystemClock implements AppClock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

class FixedClock implements AppClock {
  const FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
