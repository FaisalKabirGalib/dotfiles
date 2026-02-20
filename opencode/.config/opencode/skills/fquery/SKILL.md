---
name: fquery
description: Expert guidance on using fquery for async state management in Flutter. Covers useQuery, useInfiniteQuery, useMutation, useQueries with flutter_hooks, and QueryBuilder/MutationBuilder widgets. Use when fetching API data, managing server state, or implementing caching/invalidation patterns.
license: MIT
compatibility: opencode
---

# fquery - Async State Management for Flutter

Powerful async state management with built-in caching, inspired by React Query. Works seamlessly with flutter_hooks.

## Dependencies

```yaml
dependencies:
  fquery: ^3.0.0
  flutter_hooks: ^0.21.0
```

## Setup

Wrap your app with `CacheProvider`:

```dart
final queryCache = QueryCache(
  defaultQueryOptions: DefaultQueryOptions(
    cacheDuration: Duration(minutes: 20),
    staleDuration: Duration(minutes: 3),
    refetchOnMount: RefetchOnMount.stale,
  ),
);

void main() {
  runApp(
    CacheProvider(
      cache: queryCache,
      child: MaterialApp(home: MyApp()),
    ),
  );
}
```

Access cache anywhere: `CacheProvider.of(context)` or use `useQueryClient()` hook.

---

## Hooks API (Primary)

### useQuery

Fetch and cache async data.

```dart
class TodoList extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final todos = useQuery<List<Todo>, Exception>(
      QueryOptions(
        queryKey: QueryKey(['todos']),
        queryFn: () => TodosAPI.getInstance().getAll,
      ),
    );

    if (todos.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (todos.isError) {
      return Center(child: Text(todos.error!.toString()));
    }

    return ListView.builder(
      itemCount: todos.data!.length,
      itemBuilder: (context, index) {
        return ListTile(title: Text(todos.data![index].text));
      },
    );
  }
}
```

### useQuery Options

```dart
useQuery<List<Todo>, Exception>(
  QueryOptions(
    queryKey: QueryKey(['todos', userId]),  // Dynamic key
    queryFn: () => fetchTodos(userId),
    
    enabled: userId != null,         // Dependent query
    cacheDuration: Duration(hours: 1), // Keep in cache when unused
    staleDuration: Duration(minutes: 5), // Data is fresh for 5 min
    refetchInterval: Duration(minutes: 10), // Auto refetch
    refetchOnMount: RefetchOnMount.stale, // Refetch if stale
    retryCount: 3,                   // Retry on error
    retryDelay: Duration(seconds: 1), // Delay between retries
  ),
);
```

### useInfiniteQuery

Infinite scroll pagination.

```dart
class InfiniteScrollList extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final query = useInfiniteQuery<PageResult, Exception, int>(
      InfiniteQueryOptions(
        queryKey: QueryKey(['posts']),
        queryFn: (page) => fetchPosts(page),
        initialPageParam: 1,
        getNextPageParam: (lastPage, allPages, lastPageParam, allPageParams) {
          return lastPage.hasMore ? lastPageParam + 1 : null;
        },
        getPreviousPageParam: (firstPage, allPages, firstPageParam, allPageParams) {
          return firstPage.hasPrev ? firstPageParam - 1 : null;
        },
      ),
    );

    if (query.isLoading) {
      return const CircularProgressIndicator();
    }

    return ListView.builder(
      itemCount: query.data?.pages.length ?? 0,
      itemBuilder: (context, index) {
        final page = query.data!.pages[index];
        return ListTile(title: Text(page.title));
      },
    );
  }
}
```

**InfiniteQuery methods:**

```dart
query.fetchNextPage();      // Fetch next page
query.fetchPreviousPage();  // Fetch previous page
query.hasNextPage;          // bool
query.hasPreviousPage;      // bool
query.isFetchingNextPage;   // bool
query.isFetchingPreviousPage; // bool
```

### useQueries

Parallel dynamic queries.

```dart
class PostsWidget extends HookWidget {
  final List<int> postIds;
  
  @override
  Widget build(BuildContext context) {
    final queries = useQueries<Post, Exception>(
      options: postIds.map((id) => QueryOptions(
        queryKey: QueryKey(['post', id]),
        queryFn: () => fetchPost(id),
      )).toList(),
    );

    return Column(
      children: queries.map((q) {
        if (q.isLoading) return Text('Loading...');
        if (q.isError) return Text('Error: ${q.error}');
        return Text(q.data!.title);
      }).toList(),
    );
  }
}
```

### useMutation

Mutate data with optimistic updates.

```dart
class AddTodoWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final cache = useQueryClient();
    final controller = useTextEditingController();
    
    final mutation = useMutation<Todo, Exception, String, List<Todo>>(
      (text) => TodosAPI.getInstance().add(text),
      onMutate: (text) async {
        final previousTodos = cache.getQueryData<List<Todo>>(['todos']) ?? [];
        
        cache.setQueryData<List<Todo>>(['todos'], (old) {
          return [...(old ?? []), Todo(id: -1, text: text)];
        });
        
        return previousTodos;
      },
      onError: (error, text, previousTodos) {
        cache.setQueryData<List<Todo>>(['todos'], (_) => previousTodos!);
      },
      onSettled: (data, error, text, previousTodos) {
        cache.invalidateQueries(['todos']);
        controller.clear();
      },
    );

    return TextField(
      controller: controller,
      onSubmitted: (text) => mutation.mutate(text),
    );
  }
}
```

**Mutation type parameters:**

- `TData` - Return type from mutation function
- `TError` - Error type
- `TVariables` - Input variable type passed to `mutate()`
- `TContext` - Context passed between callbacks (from `onMutate`)

**Mutation callbacks:**

```dart
onMutate: (variables) async => context,   // Before mutation, return context
onSuccess: (data, variables, context) {}, // On success
onError: (error, variables, context) {},  // On error
onSettled: (data, error, variables, context) {}, // After mutation (always)
```

**Mutation state:**

```dart
mutation.mutate(variables);      // Execute mutation
mutation.mutateAsync(variables); // Returns Future<TData>
mutation.reset();                // Reset to idle state
mutation.isLoading;              // bool
mutation.isError;                // bool
mutation.isSuccess;              // bool
mutation.isIdle;                 // bool
mutation.data;                   // TData?
mutation.error;                  // TError?
mutation.variables;              // TVariables?
```

### useIsFetching

Track fetching queries count.

```dart
final isFetching = useIsFetching();

return Stack(
  children: [
    ListView(...),
    if (isFetching > 0)
      Positioned(
        top: 8,
        right: 8,
        child: CircularProgressIndicator(),
      ),
  ],
);
```

### useQueryClient

Access QueryCache in hooks.

```dart
final cache = useQueryClient();

cache.invalidateQueries(['todos']);
cache.setQueryData(['todos'], (old) => [...old, newTodo]);
```

---

## Query State Properties

Every query returns a state object:

```dart
query.data;           // T? - The cached data
query.error;          // Exception? - Error if any
query.isLoading;      // bool - First load, no data yet
query.isError;        // bool - Has error
query.isSuccess;      // bool - Has data
query.isFetching;     // bool - Currently fetching (includes refetch)
query.isRefetching;   // bool - Refetching with existing data
query.isStale;        // bool - Data is stale
query.dataUpdatedAt;  // DateTime? - When data was last updated
query.errorUpdatedAt; // DateTime? - When error occurred
```

---

## Query Methods

```dart
query.refetch();           // Manually refetch
query.remove();            // Remove from cache
query.setData(data);       // Manually set data
```

---

## Cache Operations

Access cache via `useQueryClient()` or `CacheProvider.of(context)`.

### Invalidation

```dart
final cache = useQueryClient();

// Invalidate all queries starting with 'posts'
cache.invalidateQueries(['posts']);

// Exact match only
cache.invalidateQueries(['posts'], exact: true);

// Invalidate specific query
cache.invalidateQueries(['posts', postId]);
```

### Manual Updates

```dart
cache.setQueryData<List<Post>>(['posts'], (previous) {
  return previous?.map((p) => p.copyWith(title: 'Updated')).toList() ?? [];
});
```

### Remove Queries

```dart
cache.removeQueries(['posts']);
cache.removeQueries(['posts'], exact: true);
```

### Get Query Data

```dart
final todos = cache.getQueryData<List<Todo>>(['todos']);
```

---

## Widget API (Non-Hook)

For projects not using flutter_hooks, use builder widgets.

### QueryBuilder

```dart
QueryBuilder<List<Todo>, Exception>(
  options: QueryOptions(
    queryKey: QueryKey(['todos']),
    queryFn: () => TodosAPI.getInstance().getAll,
  ),
  builder: (context, todos) {
    if (todos.isLoading) return CircularProgressIndicator();
    if (todos.isError) return Text(todos.error!.toString());
    return ListView.builder(
      itemCount: todos.data!.length,
      itemBuilder: (context, i) => Text(todos.data![i].text),
    );
  },
)
```

### InfiniteQueryBuilder

```dart
InfiniteQueryBuilder<PageResult, Exception, int>(
  InfiniteQueryOptions(
    queryKey: QueryKey(['posts']),
    queryFn: (page) => fetchPosts(page),
    initialPageParam: 1,
    getNextPageParam: (lastPage, allPages, lastPageParam, allPageParams) {
      return lastPage.hasMore ? lastPageParam + 1 : null;
    },
  ),
  builder: (context, query) {
    if (query.isLoading) return CircularProgressIndicator();
    return ListView(...);
  },
)
```

### QueriesBuilder

```dart
QueriesBuilder<Post, Exception>(
  options: postIds.map((id) => QueryOptions(
    queryKey: QueryKey(['post', id]),
    queryFn: () => fetchPost(id),
  )).toList(),
  builder: (context, queries) {
    return Column(
      children: queries.map((q) => Text(q.data?.title ?? 'Loading')).toList(),
    );
  },
)
```

### MutationBuilder

```dart
MutationBuilder<Todo, Exception, String, List<Todo>>(
  (text) => TodosAPI.getInstance().add(text),
  onMutate: (text) async {
    final previous = cache.getQueryData<List<Todo>>(['todos']);
    cache.setQueryData<List<Todo>>(['todos'], (old) => [...?old, Todo(text: text)]);
    return previous;
  },
  onError: (error, text, previous) {
    cache.setQueryData<List<Todo>>(['todos'], (_) => previous!);
  },
  onSettled: (_, __, ___, ____) {
    cache.invalidateQueries(['todos']);
  },
  builder: (context, mutation) {
    return ElevatedButton(
      onPressed: () => mutation.mutate('New todo'),
      child: Text('Add'),
    );
  },
)
```

### IsFetchingBuilder

```dart
IsFetchingBuilder(
  builder: (context, count) {
    return Text('$count queries fetching');
  },
)
```

---

## Dependent Queries

Query that depends on another value:

```dart
final user = useQuery<User, Exception>(
  QueryOptions(
    queryKey: QueryKey(['user', email]),
    queryFn: () => fetchUser(email),
  ),
);

final posts = useQuery<List<Post>, Exception>(
  QueryOptions(
    queryKey: QueryKey(['posts', user.data?.id]),
    queryFn: () => fetchPosts(user.data!.id),
    enabled: user.data != null,  // Only run when user exists
  ),
);
```

---

## Parallel Queries

Static parallel queries (just use multiple hooks):

```dart
final assets = useQuery<List<Asset>, Exception>(QueryOptions(...));
final profile = useQuery<Profile, Exception>(QueryOptions(...));
```

Dynamic parallel queries (use `useQueries`):

```dart
final queries = useQueries<Post, Exception>(
  options: ids.map((id) => QueryOptions(
    queryKey: QueryKey(['post', id]),
    queryFn: () => fetchPost(id),
  )).toList(),
);
```

---

## Accessing Queries Outside Builder

Read query state anywhere with BuildContext:

```dart
final query = QueryInstance.of<List<Todo>, Exception>(
  context,
  QueryOptions(queryKey: QueryKey(['todos']), queryFn: fetchTodos),
);

query.refetch();
query.data;
```

Available accessors:

- `QueryInstance.of<TData, TError>(context, options)`
- `InfiniteQueryInstance.of<TData, TError, TPageParam>(context, options)`
- `QueriesInstance.of<TData, TError>(context, options)`

---

## Common Patterns

### API Client with Query Key Factory

```dart
class TodoKeys {
  static QueryKey list() => QueryKey(['todos']);
  static QueryKey detail(int id) => QueryKey(['todos', id]);
  static QueryKey byUser(int userId) => QueryKey(['todos', 'user', userId]);
}

// Usage
useQuery<List<Todo>, Exception>(
  QueryOptions(queryKey: TodoKeys.list(), queryFn: fetchTodos),
);
```

### Optimistic Update Pattern

```dart
final mutation = useMutation<Todo, Exception, String, Todo?>(
  (text) => api.addTodo(text),
  onMutate: (text) async {
    await cache.cancelQueries(['todos']);
    final previous = cache.getQueryData<Todo>(['todos']);
    cache.setQueryData<Todo>(['todos'], (old) => Todo(text: text));
    return previous;
  },
  onError: (error, text, previous) {
    cache.setQueryData<Todo>(['todos'], (_) => previous!);
  },
  onSettled: () {
    cache.invalidateQueries(['todos']);
  },
);
```

### Polling / Auto Refresh

```dart
useQuery<Data, Exception>(
  QueryOptions(
    queryKey: QueryKey(['status']),
    queryFn: fetchStatus,
    refetchInterval: Duration(seconds: 5),  // Poll every 5s
  ),
);
```

### Conditional Fetching

```dart
final isLoggedIn = useSignal(false);

useQuery<Data, Exception>(
  QueryOptions(
    queryKey: QueryKey(['profile']),
    queryFn: fetchProfile,
    enabled: isLoggedIn.value,  // Only fetch when logged in
  ),
);
```

---

## RefetchOnMount Options

```dart
RefetchOnMount.always,  // Always refetch on mount
RefetchOnMount.stale,   // Refetch only if stale (default)
RefetchOnMount.never,   // Never refetch on mount
```

---

## Best Practices

1. **Use QueryKey consistently** - Create a key factory class
2. **Invalidate after mutations** - Keep cache in sync with server
3. **Use optimistic updates** - Better UX for mutations
4. **Set appropriate staleDuration** - Avoid unnecessary refetches
5. **Handle loading/error states** - Always show UI feedback
6. **Use enabled for dependent queries** - Prevent null errors
7. **Cancel queries on mutate** - Prevent race conditions

---

## Reference

- Package: https://pub.dev/packages/fquery
- GitHub: https://github.com/41y08h/fquery
- Discord: https://discord.gg/udhkduc9sQ
