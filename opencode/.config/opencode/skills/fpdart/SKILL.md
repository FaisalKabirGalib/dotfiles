---
name: fpdart
description: Expert guidance on using fpdart for functional programming in Dart and Flutter. Covers Option, Either, Task, TaskEither, Do notation, and integration with Freezed. Use when implementing error handling, nullable handling, async workflows, or functional patterns in Flutter apps.
license: MIT
compatibility: opencode
---

# fpdart - Functional Programming for Dart & Flutter

Practical functional programming patterns for Flutter developers.

## Setup

```yaml
dependencies:
  fpdart: ^1.2.0

dev_dependencies:
  freezed: ^2.5.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  build_runner: ^2.4.0
```

```dart
import 'package:fpdart/fpdart.dart';
```

---

## Option - Handle Nullable Values

Replace null checks with explicit Some/None.

### Creation

```dart
Option<int> someValue = Option.of(10);      // Some(10)
Option<int> noneValue = Option<int>.none();  // None

// From nullable
String? name = 'John';
Option<String> option = Option.fromNullable(name);

// Safe parsing
Option<int> parsed = Option.tryCatch(() => int.parse('42'));
Option<int> invalid = Option.tryCatch(() => int.parse('abc')); // None
```

### Map & Chain

```dart
final value = Option.of(10);

final doubled = value.map((n) => n * 2);    // Some(20)
final stringVal = value.map((n) => '$n');   // Some('10')

// flatMap for chaining (returns Option)
final chained = Option.of(10)
  .flatMap((n) => Option.of(n + 5))         // Some(15)
  .flatMap((n) => Option<int>.none());      // None
```

### Get Value

```dart
final value = Option.of(10);

// Provide default for None
final int result = value.getOrElse(() => 0);  // 10
final none = Option<int>.none();
final fallback = none.getOrElse(() => 0);      // 0

// Get or throw
final orNull = value.getOrNull();   // 10
final orNullNone = none.getOrNull(); // null

// isNone / isSome
if (value.isSome()) { /* has value */ }
if (value.isNone()) { /* no value */ }
```

### Pattern Matching

```dart
final value = Option.of(10);

value.match(
  () => print('No value'),
  (a) => print('Value: $a'),
);

// Dart 3+ pattern matching
final message = switch (value) {
  None() => 'No value',
  Some(value: final v) => 'Value: $v',
};
```

### Convert to Either

```dart
Option<int> option = Option.of(10);

Either<String, int> either = option.toEither(() => 'Missing');
// Right(10)

Either<String, int> noneEither = Option<int>.none().toEither(() => 'Missing');
// Left('Missing')
```

---

## Either - Error Handling

Replace try-catch with explicit Left (error) / Right (success).

### Creation

```dart
Either<String, int> success = Either.of(42);           // Right(42)
Either<String, int> error = Either.left('Error msg');  // Left('Error msg')

// Safe try-catch
Either<String, int> parsed = Either.tryCatch(
  () => int.parse('42'),
  (e, s) => 'Parse error: $e',
);

Either<String, int> invalid = Either.tryCatch(
  () => int.parse('abc'),
  (e, s) => 'Parse error: $e',
); // Left('Parse error:...')
```

### Map

```dart
Either<String, int> right = Either.of(10);

// Transform Right value
final doubled = right.map((n) => n * 2);     // Right(20)
final stringVal = right.map((n) => '$n');   // Right('10')

// Transform Left value (error)
final mappedError = Either.left('error').mapLeft((e) => e.toUpperCase());

// flatMap for chaining (propagates Left)
final chained = Either.of(10)
  .flatMap((n) => Either.of(n + 5))        // Right(15)
  .flatMap((n) => Either.left('stop'));    // Left('stop')
```

### Get Value

```dart
Either<String, int> right = Either.of(10);
Either<String, int> left = Either.left('error');

// Provide default on Left
final int result = right.getOrElse((e) => 0);  // 10
final fallback = left.getOrElse((e) => 0);       // 0

// Fold - extract both sides
final message = right.match(
  (left) => 'Error: $left',
  (right) => 'Success: $right',
); // 'Success: 10'

// Dart 3+ pattern matching
final result2 = switch (right) {
  Left(value: final e) => 'Error: $e',
  Right(value: final v) => 'Value: $v',
};
```

### Convert

```dart
Either<String, int> either = Either.of(10);

// To Option (Left becomes None)
Option<int> option = either.toOption();

// To Future (Left becomes exception)
Future<int> future = either.toFuture();

// To Task (wraps in Task)
Task<Either<String, int>> task = either.toTask();
```

---

## Task - Async Without Errors

Wrap async functions that never fail.

### Creation

```dart
Task<int> task = Task.of(10);

Task<int> asyncTask = Task(() async => 10);

Task<int> fromFuture = Task(() => Future.value(10));
```

### Map & Chain

```dart
Task<int> task = Task.of(10);

Task<String> mapped = task.map((n) => '$n');      // Task(() => '10')
Task<int> doubled = task.map((n) => n * 2);        // Task(() => 20)

Task<int> chained = task
  .flatMap((n) => Task.of(n + 5));                 // Task(() => 15)
```

### Run

```dart
Task<int> task = Task(() async => 42);

final int result = await task.run();  // 42
```

---

## TaskEither - Most Common Pattern

Combine Task (async) + Either (error handling). Perfect for API calls.

### Creation

```dart
// Pattern: TaskEither<ErrorType, SuccessType>
TaskEither<String, User> fetchUser(int id) {
  return TaskEither.tryCatch(
    () => api.getUser(id),
    (e, s) => 'Failed to fetch user: $e',
  );
}

// Or manually
TaskEither<String, User> fetchUser2(int id) {
  return Task(() async {
    try {
      final user = await api.getUser(id);
      return Right(user);
    } catch (e, s) {
      return Left('Error: $e');
    }
  });
}
```

### Usage

```dart
final result = await fetchUser(1).run();

// Handle result
result.match(
  (error) => print('Error: $error'),
  (user) => print('User: ${user.name}'),
);

// Or use getOrElse
final user = await fetchUser(1).run().getOrElse((e) => User.guest());

// Chain multiple calls
final userTask = fetchUser(1).flatMap((user) => fetchPosts(user.id));

final posts = await userTask.run().getOrElse((e) => []);
```

### Map

```dart
TaskEither<String, User> userTask = fetchUser(1);

// Map success value
TaskEither<String, String> nameTask = userTask.map((u) => u.name);

// Map error
TaskEither<ApiError, User> withCustomError = userTask
  .mapLeft((e) => ApiError(e));
```

### Multiple API Calls

```dart
// Parallel - use Future.wait
final results = await Future.wait([
  fetchUser(1).run(),
  fetchPosts(1).run(),
]).run();

// Sequential with flatMap
final combined = fetchUser(1).flatMap((user) =>
  fetchPosts(user.id).map((posts) => UserWithPosts(user, posts))
).run();
```

---

## Do Notation - Cleaner Chains

Use `$(...)` instead of nested flatMaps.

### Option Do

```dart
// Without Do - nested flatMaps
final without = Option.of(10)
  .flatMap((a) => Option.of(a + 5))
  .flatMap((b) => Option.of(b * 2))
  .getOrElse(() => 0);

// With Do - linear syntax
final withDo = Option.Do($ => 
  final a = $(Option.of(10));
  final b = $(Option.of(a + 5));
  final c = $(Option.of(b * 2));
  return c;
).getOrElse(() => 0);

// Example: Find user and their posts
final result = Option.Do($) {
  final user = $(findUser(userId));
  final posts = $(findPosts(user.id));
  return UserWithPosts(user, posts);
};
```

### Either Do

```dart
final result = Either.Do($) {
  final user = $(fetchUser(1));
  final posts = $(fetchPosts(user.id));
  return UserWithPosts(user, posts);
};

await result.run();
```

### TaskEither Do

```dart
final result = TaskEither<String, UserWithPosts>.Do($) {
  final user = $(fetchUser(1));
  final posts = $(fetchPosts(user.id));
  return UserWithPosts(user, posts);
}.run();
```

### Do Notation Rules

- Use `$()` to extract value from Option/Either/TaskEither
- If any `$()` returns None/Left, the entire Do returns None/Left
- Cannot throw inside Do
- Cannot await without using `$`
- No nested Do constructors

---

## fpdart + Freezed

Freezed unions work perfectly with Either pattern.

### Freezed with Either

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

part 'user.freezed.dart';

@freezed
class User with _$User {
  const factory User.loaded(UserData data) = UserLoaded;
  const factory User.loading() = UserLoading;
  const factory User.error(String message) = UserError;
}

// Convert to Either for API responses
Either<String, UserData> toEither(User user) {
  return switch (user) {
    UserLoaded(data: final d) => Right(d),
    UserLoading() => const Left('Loading'),
    UserError(message: final m) => Left(m),
  };
}
```

### Use with TaskEither

```dart
TaskEither<String, User> fetchUser(int id) {
  return TaskEither.tryCatch(
    () => api.getUser(id),
    (e, s) => 'API Error: $e',
  );
}

// In repository
class UserRepository {
  Future<Either<String, UserData>> getUser(int id) {
    return fetchUser(id).run();
  }
}

// In bloc/provider
final result = await userRepo.getUser(1);
result.fold(
  (error) => emit(UserError(error)),
  (user) => emit(UserLoaded(user)),
);
```

### Validation with Either

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
class LoginCredentials with _$LoginCredentials {
  const factory LoginCredentials({
    required String email,
    required String password,
  }) = _LoginCredentials;

  const LoginCredentials._();

  Either<String, LoginCredentials> validate() {
    return Either.Do($) {
      final email = $(_validateEmail(this.email));
      final password = $(_validatePassword(this.password));
      return LoginCredentials(email: email, password: password);
    };
  }

  Option<String> _validateEmail(String email) {
    if (email.contains('@')) return Option.of(email);
    return Option.none();
  }

  Option<String> _validatePassword(String password) {
    if (password.length >= 8) return Option.of(password);
    return Option.none();
  }
}
```

---

## Common Patterns

### API Call Pattern

```dart
// Repository
class ApiRepository {
  TaskEither<ApiException, User> getUser(String id) {
    return TaskEither.tryCatch(
      () => _dio.get('/users/$id'),
      (e, s) => ApiException(e.toString()),
    );
  }

  TaskEither<ApiException, List<Post>> getUserPosts(String userId) {
    return TaskEither.tryCatch(
      () => _dio.get('/users/$userId/posts'),
      (e, s) => ApiException(e.toString()),
    );
  }
}

// Usage in bloc/cubit
class UserCubit extends Cubit<UserState> {
  final ApiRepository _api;

  Future<void> loadUser(String id) async {
    emit(UserLoading());
    
    final result = await _api.getUser(id).run();
    
    result.fold(
      (error) => emit(UserError(error.message)),
      (user) => emit(UserLoaded(user)),
    );
  }
}
```

### Form Validation

```dart
Either<String, LoginRequest> validateLogin(String email, String pass) {
  return Either.Do($) {
    if (email.isEmpty) return $(_left('Email required'));
    if (!email.contains('@')) return $(_left('Invalid email'));
    if (pass.length < 8) return $(_left('Password too short'));
    
    return LoginRequest(email: email, password: pass);
  };
}

// Usage
final result = validateLogin('test@example.com', 'password123');
result.fold(
  (errors) => showErrors(errors),
  (request) => login(request),
);
```

### Safe List Operations

```dart
import 'package:fpdart/fpdart.dart';

final list = [1, 2, 3, 4, 5];

// Head - first element as Option
final first = list.head;          // Some(1)
final emptyHead = [].head;       // None

// Last - last element as Option  
final last = list.last;           // Some(5)
final emptyLast = [].last;       // None

// Find - find element as Option
final found = list.find((x) => x > 3); // Some(4)

// FilterMap - map and filter in one
final mapped = list.filterMap((x) => 
  x > 2 ? Option.of(x * 2) : Option.none()
); // [6, 8, 10]

// GroupBy
final grouped = list.groupBy((x) => x.isEven ? 'even' : 'odd');
// {'even': [2, 4], 'odd': [1, 3, 5]}
```

---

## Best Practices

1. **Use TaskEither for API calls** - Most common pattern for async + error handling
2. **Prefer Either over exceptions** - Explicit error types are more testable
3. **Use Option for nullable** - More explicit than null checks
4. **Use Do notation** - Improves readability over nested flatMaps
5. **Keep Either left types specific** - Don't use String for everything
6. **Use Freezed for domain models** - Works great with Either pattern matching
7. **Run TaskEither at boundary** - Keep inner code pure, run at repository/handler level
8. **Don't over-engineer** - Sometimes simple try-catch is fine for small functions

---

## Type Reference

| Type | Description | Use Case |
|------|-------------|----------|
| `Option<T>` | T or None | Nullable values |
| `Either<L, R>` | Left or Right | Error handling |
| `Task<R>` | Async R | Async without errors |
| `TaskEither<L, R>` | Async + Either | API calls |
| `IO<R>` | Sync side effects | Pure side effects |
| `Reader<E, R>` | Environment R | Dependency injection |
| `State<S, R>` | State + R | State management |

---

## Reference

- Package: https://pub.dev/packages/fpdart
- Docs: https://www.sandromaglione.com/
- GitHub: https://github.com/SandroMaglione/fpdart
- Freezed: https://pub.dev/packages/freezed
