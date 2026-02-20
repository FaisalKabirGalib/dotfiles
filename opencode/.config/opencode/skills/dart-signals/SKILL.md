---
name: dart-signals
description: Expert guidance on using Dart Signals in Flutter with flutter_hooks. Covers useSignal, useComputed, useSignalEffect, async signals, and collections. Use when working with signals package, HookWidget, or reactive state management in Flutter.
license: MIT
compatibility: opencode
---

# Dart Signals for Flutter (with flutter_hooks)

Fine-grained reactive state management for Flutter using signals with flutter_hooks integration.

## Dependencies

```yaml
dependencies:
  signals: ^6.0.0
  signals_hooks: ^0.4.0
  flutter_hooks: ^0.18.0
```

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class CounterWidget extends HookWidget {
  const CounterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final count = useSignal(0);
    final doubleCount = useComputed(() => count.value * 2);
    
    useSignalEffect(() {
      debugPrint('count: $count, double: $doubleCount');
    });

    return Scaffold(
      body: Center(child: Text('Count: $count (Double: $doubleCount)')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => count.value++,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

All signals and effects auto-dispose when widget unmounts.

---

## Core Hooks

### useSignal

Create reactive state. Auto-rebuilds widget on change.

```dart
final count = useSignal(0);
final name = useSignal('John');
final items = useSignal<List<String>>([]);

count.value++;           // Update
print(count.value);      // Read
count.peek();            // Read without subscribing
```

### useComputed

Derived values that auto-update when dependencies change. Lazy and memoized.

```dart
final firstName = useSignal('John');
final lastName = useSignal('Doe');
final fullName = useComputed(() => '${firstName.value} ${lastName.value}');

final count = useSignal(5);
final isEven = useComputed(() => count.value.isEven);
final doubled = useComputed(() => count.value * 2);
```

### useSignalEffect

Side effects that react to signal changes. Returns cleanup callback.

```dart
final count = useSignal(0);

useSignalEffect(() {
  debugPrint('Count changed: $count');
  return () => debugPrint('Effect cleaned up');
});

useSignalEffect(() {
  if (count.value > 10) {
    fetchData();
  }
});
```

### useExistingSignal

Bind external signal to widget lifecycle. Useful for signals passed as parameters.

```dart
class MyWidget extends HookWidget {
  final Signal<int> externalCount;
  
  const MyWidget(this.externalCount, {super.key});

  @override
  Widget build(BuildContext context) {
    final count = useExistingSignal(externalCount);
    return Text('Count: $count');
  }
}
```

### useSignalValue

Read-only access to signal value. Auto-rebuilds on change.

```dart
final count = useSignalValue(externalSignal);
return Text('Count: $count');
```

---

## Async Hooks

### useFutureSignal

Handle Future-based async data.

```dart
final data = useFutureSignal(() => fetchUser());

return data.value.map(
  data: (user) => Text('User: ${user.name}'),
  error: (error, stack) => Text('Error: $error'),
  loading: () => const CircularProgressIndicator(),
);
```

### useStreamSignal

Handle Stream-based async data.

```dart
final counter = useStreamSignal(() => 
  Stream.periodic(const Duration(seconds: 1), (i) => i)
);

return counter.value.map(
  data: (value) => Text('Count: $value'),
  error: (error, stack) => Text('Error: $error'),
  loading: () => const CircularProgressIndicator(),
);
```

### useAsyncSignal

Manual async state control.

```dart
final state = useAsyncSignal<int>(AsyncState.loading());

Future<void> loadData() async {
  state.value = AsyncState.loading();
  try {
    final result = await fetchData();
    state.value = AsyncState.data(result);
  } catch (e, st) {
    state.value = AsyncState.error(e, st);
  }
}

return state.value.map(
  data: (value) => Text('Data: $value'),
  error: (error, stack) => Text('Error: $error'),
  loading: () => const CircularProgressIndicator(),
);
```

### useAsyncComputed

Async computed values with dependency tracking.

```dart
final userId = useSignal(1);
final user = useAsyncComputed(
  () async => fetchUser(userId.value),
  dependencies: [userId],
);

return user.value.map(
  data: (u) => Text('User: ${u.name}'),
  error: (e, s) => Text('Error: $e'),
  loading: () => const CircularProgressIndicator(),
);
```

### AsyncState Methods

```dart
final asyncSignal = useFutureSignal(() => fetchData());

asyncSignal.value.map(
  data: (value) => Widget,
  error: (error, stack) => Widget,
  loading: () => Widget,
);

asyncSignal.value.hasValue;     // bool
asyncSignal.value.hasError;     // bool
asyncSignal.value.isLoading;    // bool
asyncSignal.value.value;        // T? (data if exists)
asyncSignal.value.error;        // Object? (error if exists)

asyncSignal.refresh();          // Set loading=true, keep state
asyncSignal.reload();           // Reset to AsyncLoading
asyncSignal.reset();            // Reset to initial state
```

---

## Collection Hooks

### useListSignal

Reactive list with mutable operations.

```dart
final items = useListSignal<String>(['a', 'b', 'c']);

items.add('d');           // Auto-triggers rebuild
items.remove('a');
items.insert(0, 'x');
items.clear();
items.value = ['new'];    // Replace entire list

return ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, i) => Text(items[i]),
);
```

### useSetSignal

Reactive set.

```dart
final tags = useSetSignal<String>({'flutter', 'dart'});

tags.add('signals');
tags.remove('dart');
tags.contains('flutter');  // true

return Text('Tags: ${tags.value}');
```

### useMapSignal

Reactive map.

```dart
final user = useMapSignal<String, dynamic>({
  'name': 'John',
  'age': 30,
});

user['age'] = 31;
user.remove('name');
user.value = {'new': 'data'};

return Text('Name: ${user['name']}');
```

---

## Migration Helpers

### useValueNotifierToSignal

Convert ValueNotifier to Signal.

```dart
final notifier = useValueNotifier(0);
final signal = useValueNotifierToSignal(notifier);

signal.value++;  // Updates both signal and notifier
```

### useValueListenableToSignal

Convert ValueListenable to ReadonlySignal.

```dart
final listenable = ValueNotifier(0);
final signal = useValueListenableToSignal(listenable);

print(signal.value);  // Read-only
```

---

## Utilities

### batch

Combine multiple updates into single rebuild.

```dart
final a = useSignal(0);
final b = useSignal(0);

batch(() {
  a.value = 1;
  b.value = 2;
});  // Single rebuild after callback completes
```

### untracked

Read signal without subscribing.

```dart
final count = useSignal(0);
final logCount = useSignal(0);

useSignalEffect(() {
  print(count.value);
  logCount.value = untracked(() => logCount.value + 1);  // No cycle
});
```

---

## Testing

Use `flutter_test` with `HookBuilder`.

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signals_hooks/signals_hooks.dart';

void main() {
  testWidgets('useSignal increments correctly', (tester) async {
    late Signal<int> count;
    
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        count = useSignal(0);
        return GestureDetector(
          onTap: () => count.value++,
          child: Text('$count', textDirection: TextDirection.ltr),
        );
      }),
    );

    expect(count.value, 0);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.text('0'));
    await tester.pumpAndSettle();

    expect(count.value, 1);
    expect(find.text('1'), findsOneWidget);
  });
}
```

---

## Best Practices

1. **Use HookWidget** - Not StatelessWidget or StatefulWidget
2. **Create signals in build()** - Hooks must be called in build method
3. **Avoid signal creation in effects** - Creates new signals on every run
4. **Use computed for derived state** - Don't duplicate logic
5. **Handle async states** - Always handle loading/error states
6. **Batch updates** - Use `batch()` for multiple related changes
7. **Clean up effects** - Return cleanup function when needed

---

## Common Patterns

### Form State

```dart
class FormWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final email = useSignal('');
    final password = useSignal('');
    final isValid = useComputed(() => 
      email.value.contains('@') && password.value.length >= 8
    );

    return Column(
      children: [
        TextField(onChanged: (v) => email.value = v),
        TextField(onChanged: (v) => password.value = v),
        ElevatedButton(
          onPressed: isValid.value ? submit : null,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
```

### API Data with Refresh

```dart
class DataWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final data = useFutureSignal(() => fetchData());

    return RefreshIndicator(
      onRefresh: () async => data.refresh(),
      child: data.value.map(
        data: (d) => ListView(children: [...]),
        error: (e, s) => Text('Error: $e'),
        loading: () => const CircularProgressIndicator(),
      ),
    );
  }
}
```

### Dependency Injection

```dart
final counterSignal = signal(0);  // Global signal

class MyApp extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final count = useExistingSignal(counterSignal);
    return Text('Count: $count');
  }
}
```

---

## Reference

- Documentation: https://dartsignals.dev/
- signals_hooks: https://pub.dev/packages/signals_hooks
- GitHub: https://github.com/rodydavis/signals.dart
