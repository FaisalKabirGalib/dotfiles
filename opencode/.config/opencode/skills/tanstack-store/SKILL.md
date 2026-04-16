# TanStack Store Skill

Expert guidance for using TanStack Store for state management in React/TypeScript applications.

## Installation

```bash
bun add @tanstack/store @tanstack/react-store
```

## Core Concepts

### Creating a Store

Two equivalent ways to create a writable store:

```typescript
import { Store, createStore } from '@tanstack/store'

// Using class constructor
const countStore = new Store<number>(0)

// Using factory function
const countStore = createStore<number>(0)
```

### Reading State

```typescript
// Direct property access
console.log(countStore.state) // 0

// Getter method
const value = countStore.get()
```

### Updating State

```typescript
// Functional update (recommended)
countStore.setState((prev) => prev + 1)

// Direct value
countStore.setState(() => 5)
```

### Subscriptions

```typescript
const { unsubscribe } = countStore.subscribe((state) => {
  console.log('State changed:', state)
})

// Cleanup
unsubscribe()
```

## Derived Stores

Derived stores automatically compute values when dependencies change:

```typescript
const count = createStore(0)

// Derived (readonly) store
const double = createStore(() => count.state * 2)

console.log(double.state) // 0
count.setState(() => 5)
console.log(double.state) // 10
```

### Derived with Previous Value

```typescript
const count = createStore(1)

// Accumulator pattern
const sum = createStore<number>((prev) => {
  return count.state + (prev ?? 0)
})

console.log(sum.state) // 1
count.setState(() => 2)
console.log(sum.state) // 3
```

## React Integration

```typescript
import { useStore } from '@tanstack/react-store'
import { createStore } from '@tanstack/store'

const counterStore = createStore({ count: 0 })

function Counter() {
  const state = useStore(counterStore)
  // or with selector
  const count = useStore(counterStore, (state) => state.count)

  return (
    <button onClick={() => counterStore.setState((s) => ({ count: s.count + 1 }))}>
      Count: {count}
    </button>
  )
}
```

## Best Practices

### Store Structure

```typescript
// Good: Flat, focused stores
const sessionStore = createStore({
  user: null,
  token: null,
})

const redemptionStore = createStore({
  current: null,
  step: 'idle',
})

// Avoid: Deeply nested state
const appStore = createStore({
  session: { user: { profile: { name: '' } } }
})
```

### Actions Pattern

```typescript
// Export store + action functions
export const sessionStore = createStore<SessionState>(initialState)

export function setSession(token: string, user: User) {
  sessionStore.setState((prev) => ({
    ...prev,
    token,
    user,
    isAuthenticated: true,
  }))
}

export function clearSession() {
  sessionStore.setState((prev) => ({
    ...prev,
    token: null,
    user: null,
    isAuthenticated: false,
  }))
}

// Convenience getters
export function getSession(): SessionState {
  return sessionStore.state
}

export function getToken(): string | null {
  return sessionStore.state.token
}
```

### Persistence

```typescript
const STORAGE_KEY = 'app_session'

// Load initial state
function loadFromStorage(): Partial<SessionState> {
  try {
    const stored = localStorage.getItem(STORAGE_KEY)
    return stored ? JSON.parse(stored) : {}
  } catch {
    return {}
  }
}

// Create store with persisted data
export const sessionStore = createStore<SessionState>({
  ...initialState,
  ...loadFromStorage(),
})

// Auto-save on changes
sessionStore.subscribe(() => {
  const { token, user } = sessionStore.state
  localStorage.setItem(STORAGE_KEY, JSON.stringify({ token, user }))
})
```

### Computed Values with Derived Stores

```typescript
const sessionStore = createStore({
  user: null as User | null,
  token: null as string | null,
})

// Derived store for computed value
export const isAuthenticated = createStore(() => {
  return !!sessionStore.state.token && !!sessionStore.state.user
})
```

## Batch Updates

```typescript
import { batch } from '@tanstack/store'

// Subscribers only notified once
batch(() => {
  store1.setState(() => ({ a: 1 }))
  store1.setState(() => ({ a: 2 }))
  store2.setState(() => ({ b: 3 }))
})
```

## Common Patterns

### Authentication Store

```typescript
import { createStore } from '@tanstack/store'
import { useStore } from '@tanstack/react-store'

interface SessionState {
  user: User | null
  token: string | null
  isAuthenticated: boolean
}

export const sessionStore = createStore<SessionState>({
  user: null,
  token: null,
  isAuthenticated: false,
})

export function setSession(token: string, user: User) {
  sessionStore.setState((prev) => ({
    ...prev,
    token,
    user,
    isAuthenticated: true,
  }))
}

export function clearSession() {
  sessionStore.setState({
    user: null,
    token: null,
    isAuthenticated: false,
  })
}

export function useSession() {
  return useStore(sessionStore)
}
```

### Form State

```typescript
interface FormState {
  values: Record<string, string>
  errors: Record<string, string>
  touched: Record<string, boolean>
  isSubmitting: boolean
}

export const formStore = createStore<FormState>({
  values: {},
  errors: {},
  touched: {},
  isSubmitting: false,
})

export function setField(name: string, value: string) {
  formStore.setState((prev) => ({
    ...prev,
    values: { ...prev.values, [name]: value },
  }))
}

export function setError(name: string, error: string) {
  formStore.setState((prev) => ({
    ...prev,
    errors: { ...prev.errors, [name]: error },
  }))
}
```

### Async State

```typescript
interface AsyncState<T> {
  data: T | null
  isLoading: boolean
  error: string | null
}

export function createAsyncStore<T>(initialData: T | null = null) {
  return createStore<AsyncState<T>>({
    data: initialData,
    isLoading: false,
    error: null,
  })
}

// Usage with mutations
export function setLoading(store: Store<AsyncState<unknown>>) {
  store.setState((prev) => ({ ...prev, isLoading: true, error: null }))
}

export function setData<T>(store: Store<AsyncState<T>>, data: T) {
  store.setState((prev) => ({ ...prev, data, isLoading: false }))
}

export function setError(store: Store<AsyncState<unknown>>, error: string) {
  store.setState((prev) => ({ ...prev, error, isLoading: false }))
}
```

## TypeScript Tips

```typescript
// Type-safe state interface
interface AppState {
  user: User | null
  token: string | null
  deviceId: string
  isAuthenticated: boolean
}

// Create typed store
export const appStore = createStore<AppState>({
  user: null,
  token: null,
  deviceId: generateDeviceId(),
  isAuthenticated: false,
})

// Type-safe selector
export function useUser(): User | null {
  return useStore(appStore, (state) => state.user)
}

// Type-safe action
export function setSession(token: string, user: User): void {
  appStore.setState((prev) => ({
    ...prev,
    token,
    user,
    isAuthenticated: true,
  }))
}
```

## Common Mistakes

### 1. Mutating State Directly

```typescript
// ❌ Wrong - mutates state
store.setState((prev) => {
  prev.items.push(newItem)
  return prev
})

// ✅ Correct - creates new state
store.setState((prev) => ({
  ...prev,
  items: [...prev.items, newItem],
}))
```

### 2. Not Using Functional Updates

```typescript
// ❌ Wrong - ignores previous state
store.setState({ count: 5 })

// ✅ Correct - uses previous state
store.setState((prev) => ({ count: prev.count + 1 }))
```

### 3. Stale Closures in Derived Stores

```typescript
// ❌ Wrong - captures stale reference
let multiplier = 2
const doubled = createStore(() => count.state * multiplier)
multiplier = 3 // doubled won't update

// ✅ Correct - derived from other stores
const multiplierStore = createStore(2)
const doubled = createStore(() => count.state * multiplierStore.state)
```

## Integration with TanStack Query

```typescript
import { useMutation } from '@tanstack/react-query'
import { sessionStore, setSession } from './stores/session-store'

export function useLogin() {
  return useMutation({
    mutationFn: async (credentials: LoginRequest) => {
      return api.post<LoginResponse>('/login', credentials)
    },
    onSuccess: (response) => {
      // Update store on success
      setSession(response.data.token, response.data.user)
    },
  })
}
```

## Debugging

```typescript
// Add logging to store
const originalStore = createStore(initialState)

export const store = new Proxy(originalStore, {
  get(target, prop) {
    if (prop === 'setState') {
      return (updater: (prev: State) => State) => {
        const result = target.setState(updater)
        console.log('State updated:', target.state)
        return result
      }
    }
    return Reflect.get(target, prop)
  },
})
```
