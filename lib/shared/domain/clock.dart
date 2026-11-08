/// Injectable time source so domain logic stays deterministic in tests.
typedef Clock = DateTime Function();

DateTime systemClock() => DateTime.now();
