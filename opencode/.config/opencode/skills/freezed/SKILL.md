---
name: freezed
description: Expert guidance on using freezed for immutable data classes in Dart/Flutter. Covers @freezed models, copyWith, JSON serialization, union types, sealed classes, and pattern matching. Use when creating immutable models, API responses, or tagged unions in Flutter apps.
license: MIT
compatibility: opencode
---

# freezed

Immutable data classes with minimal boilerplate.

## Setup

```yaml
dependencies:
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0

dev_dependencies:
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  build_runner: ^2.4.0
```

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'model.freezed.dart';
part 'model.g.dart';
```

Run generator:
```bash
dart run build_runner watch -d
```

---

## Basic Model

```dart
@freezed
class Person with _$Person {
  const factory Person({
    required String firstName,
    required String lastName,
    required int age,
  }) = _Person;
}

// Usage
var person = Person(firstName: 'John', lastName: 'Doe', age: 30);
print(person.firstName);  // John

// toString, ==, hashCode auto-generated
print(person);  // Person(firstName: John, lastName: Doe, age: 30)
```

---

## JSON Serialization

```dart
@freezed
class Person with _$Person {
  const factory Person({
    required String firstName,
    required int age,
  }) = _Person;

  factory Person.fromJson(Map<String, dynamic> json) =>
      _$PersonFromJson(json);
}

// toJson / fromJson auto-generated
final json = person.toJson();
final fromJson = Person.fromJson({'firstName': 'John', 'age': 30});
```

---

## copyWith

Clone with new values:

```dart
var person = Person(firstName: 'John', age: 30);
var updated = person.copyWith(firstName: 'Jane');
// Person(firstName: Jane, age: 30)

// Keep existing values
var same = person.copyWith();  // clone

// Set to null
var cleared = person.copyWith(firstName: null);
```

### Deep copy

```dart
@freezed
class Company with _$Company {
  const factory Company({required Director director}) = _Company;
}

@freezed
class Director with _$Company {
  const factory Director({String? name}) = _Director;
}

// Nested copyWith
var company = Company(director: Director(name: 'John'));
var updated = company.copyWith.director(name: 'Jane');
// Company(director: Director(name: Jane))

// With null safety
var updated2 = company.copyWith.director?.call(name: 'Jane');
```

---

## Union Types

Multiple constructors for mutually exclusive states:

```dart
@freezed
sealed class Result<T> with _$Result<T> {
  const factory Result.data(T value) = ResultData<T>;
  const factory Result.loading() = ResultLoading<T>;
  const factory Result.error(String message) = ResultError<T>;
}

// Usage
Result<int> result = Result.data(42);

// Check type
if (result is ResultData<int>) {
  print(result.value);  // 42
}
```

### Sealed class (Dart 3+)

```dart
@freezed
sealed class ApiState<T> with _$ApiState<T> {
  const factory ApiState.idle() = ApiIdle;
  const factory ApiState.loading() = ApiLoading;
  const factory ApiState.data(T value) = ApiData;
  const factory ApiState.error(String message) = ApiError;
}
```

---

## Pattern Matching

### switch expression (recommended)

```dart
final message = switch (result) {
  ResultData(value: final v) => 'Data: $v',
  ResultLoading() => 'Loading...',
  ResultError(message: final m) => 'Error: $m',
};
```

### if-case

```dart
if (result case ResultData(value: final v)) {
  print('Got data: $v');
} else if (result case ResultError(message: final m)) {
  print('Error: $m');
}
```

### Legacy when/map

```dart
result.when(
  data: (value) => print('Data: $value'),
  loading: () => print('Loading'),
  error: (msg) => print('Error: $msg'),
);
```

---

## Default Values

```dart
@freezed
class Person with _$Person {
  const factory Person({
    required String name,
    @Default(18) int age,
    @Default([]) List<String> hobbies,
  }) = _Person;
}

var person = Person(name: 'John');
// Person(name: John, age: 18, hobbies: [])
```

---

## Validation with Assert

```dart
@freezed
class Person with _$Person {
  @Assert('name.isNotEmpty', 'name cannot be empty')
  @Assert('age >= 0', 'age must be positive')
  const factory Person({
    required String name,
    required int age,
  }) = _Person;
}
```

---

## Adding Methods

Use private constructor:

```dart
@freezed
class Person with _$Person {
  const Person._();

  const factory Person({
    required String name,
    required int age,
  }) = _Person;

  // Custom method
  String get greeting => 'Hello, $name!';

  // Computed property
  bool get isAdult => age >= 18;
}

print(person.greeting);  // Hello, John!
```

---

## Custom Getters

```dart
@freezed
class User with _$User {
  const factory User({
    required String email,
    required String password,
  }) = _User;

  // Add getter
  bool get isValid => email.isNotEmpty && password.length >= 8;

  // Custom method
  User copyWithPassword(String newPassword) {
    return copyWith(password: newPassword);
  }
}
```

---

## Mutable Class (@unfreezed)

```dart
@unfreezed
class Counter with _$Counter {
  factory Counter({int count = 0}) = _Counter;
}

var counter = Counter(count: 5);
counter.count = 10;  // Mutate directly
```

---

## Generic Types

```dart
@freezed
sealed class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse.data(T value) = ApiResponseData<T>;
  const factory ApiResponse.error(String message) = ApiResponseError<T>;
}

// Usage
ApiResponse<User> response = ApiResponse.data(User(name: 'John'));
ApiResponse<List<Post>> posts = ApiResponse.data([...]);
```

### with JSON

```dart
@Freezed(genericArgumentFactories: true)
sealed class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse.data(T value) = ApiResponseData<T>;
  const factory ApiResponse.error(String message) = ApiResponseError<T>;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);
}
```

---

## Common Patterns

### API Response State

```dart
@freezed
sealed class AsyncState<T> with _$AsyncState<T> {
  const factory AsyncState.idle() = AsyncIdle;
  const factory AsyncState.loading() = AsyncLoading;
  const factory AsyncState.data(T value) = AsyncData;
  const factory AsyncState.error(String message) = AsyncError;
}

// Usage in widget
@override
Widget build(BuildContext context) {
  return switch (state) {
    AsyncIdle() => Text('Tap to load'),
    AsyncLoading() => CircularProgressIndicator(),
    AsyncData(data: final d) => Text('Data: $d'),
    AsyncError(message: final m) => Text('Error: $m'),
  };
}
```

### Form Model

```dart
@freezed
class LoginForm with _$LoginForm {
  const factory LoginForm({
    required String email,
    required String password,
  }) = _LoginForm;

  const LoginForm._();

  bool get isValid => 
    email.contains('@') && password.length >= 8;
}

// In UI
final form = useState(LoginForm(email: '', password: ''));
final valid = form.value.isValid;
```

### Event/Action

```dart
@freezed
sealed class CounterEvent with _$CounterEvent {
  const factory CounterEvent.increment() = CounterIncrement;
  const factory CounterEvent.decrement() = CounterDecrement;
  const factory CounterEvent.reset() = CounterReset;
}

// Usage
void handleEvent(CounterEvent event) {
  switch (event) {
    case CounterIncrement(): count++;
    case CounterDecrement(): count--;
    case CounterReset(): count = 0;
  }
}
```

---

## Best Practices

1. **Use sealed classes** for union types - enables exhaustive matching
2. **Always use const constructors** - better performance
3. **Add private constructor** (`_`) for methods/getters
4. **Use @Default** for default values (works with JSON)
5. **Keep models flat** - deep nesting with freezed models works well
6. **Run build_runner** in watch mode during development

---

## Reference

- Package: https://pub.dev/packages/freezed
- GitHub: https://github.com/rrousselGit/freezed
- Docs: https://pub.dev/documentation/freezed/latest/
