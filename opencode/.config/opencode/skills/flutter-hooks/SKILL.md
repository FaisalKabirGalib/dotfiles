---
name: flutter-hooks
description: Expert guidance on using flutter_hooks for Flutter. Covers HookWidget, useState, useEffect, useMemoized, useRef, useCallback, async hooks, and custom hooks. Use when implementing reusable stateful logic in Flutter.
license: MIT
compatibility: opencode
---

# flutter_hooks

Flutter implementation of React hooks for reusable stateful logic.

## Setup

```yaml
dependencies:
  flutter_hooks: ^0.21.0
```

```dart
import 'package:flutter_hooks/flutter_hooks.dart';
```

## HookWidget

Replace StatelessWidget with HookWidget:

```dart
class Counter extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final count = useState(0);
    return Text('${count.value}');
  }
}
```

### Rules

1. Prefix hooks with `use`
2. Call hooks unconditionally (same order every render)

---

## Core Hooks

### useState

```dart
final count = useState(0);
count.value++;           // Triggers rebuild
print(count.value);     // Get value
```

### useEffect

```dart
useEffect(() {
  print('Mounted');
  return () => print('Cleanup');  // Cleanup on unmount
}, [dependency]);  // Re-run when dependency changes

useEffect(() => ..., []);  // Run once (mount only)
useEffect(() => ...);      // Run every render
```

### useMemoized

```dart
final sorted = useMemoized(
  () => heavyComputation(data),
  [data],
);
```

### useRef

```dart
final counter = useRef(0);
counter.value++;  // No rebuild

// Store objects without rebuild
final controller = useRef(ScrollController());
```

### useCallback

```dart
final callback = useCallback(() {
  print('Clicked');
}, [dependency]);  // Recreate only when dependency changes
```

---

## Async Hooks

### useFuture

```dart
final snapshot = useFuture(Future.delayed(
  Duration(seconds: 1),
  () => 'Hello',
));

switch (snapshot.connectionState) {
  case ConnectionState.done:
    Text(snapshot.data ?? '');
  default:
    CircularProgressIndicator();
}
```

### useStream

```dart
final snapshot = useStream(Stream.periodic(
  Duration(seconds: 1),
  (i) => i,
));
Text('${snapshot.data}');
```

---

## Controller Hooks

```dart
// Text controller - auto disposed
final controller = useTextEditingController(text: 'Initial');
controller.text;  // Access text

// Scroll controller - auto disposed
final scrollController = useScrollController();

// Focus node - auto disposed
final focusNode = useFocusNode();
```

---

## Lifecycle Hooks

### useIsMounted

```dart
final isMounted = useIsMounted();

Future.microtask(() {
  if (isMounted()) {
    // Widget still mounted
  }
});
```

### useAppLifecycleState

```dart
final state = useAppLifecycleState();
// AppLifecycleState.paused, .resumed, .inactive, .detached
```

---

## Custom Hooks

```dart
// Extract reusable logic
Result useDebouncedSearch(String query) {
  final debounced = useDebounced(query, Duration(milliseconds: 300));
  final result = useMemoized(() => search(debounced), [debounced]);
  return result;
}

// Usage
class SearchWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final query = useState('');
    final results = useDebouncedSearch(query.value);
    return Text('$results');
  }
}
```

---

## Common Patterns

### Form

```dart
class Form extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final email = useTextEditingController();
    final password = useTextEditingController();

    return Column(children: [
      TextField(controller: email),
      TextField(controller: password),
    ]);
  }
}
```

### API Call

```dart
final data = useState<AsyncValue<T>>(AsyncValue.loading());

useEffect(() async {
  try {
    data.value = AsyncValue.data(await fetchData());
  } catch (e, st) {
    data.value = AsyncValue.error(e, st);
  }
}, []);

return data.value.when(
  data: (d) => Text(d),
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
);
```

### Animation

```dart
final controller = useAnimationController(
  duration: Duration(seconds: 2),
  vsync: useSingleTickerProvider(),
);

useEffect(() => controller.repeat(reverse: true), []);

return AnimatedBuilder(
  animation: controller,
  builder: (_, child) => Opacity(
    opacity: controller.value,
    child: Text('Fade'),
  ),
);
```

---

## Reference

- Package: https://pub.dev/packages/flutter_hooks
- GitHub: https://github.com/rrousselGit/flutter_hooks
