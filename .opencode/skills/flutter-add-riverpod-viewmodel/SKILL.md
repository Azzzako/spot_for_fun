---
name: flutter-add-riverpod-viewmodel
description: Create a Riverpod 2.x AutoDisposeNotifier ViewModel matching the spot_for_fun convention. Use when adding any screen that holds async state, submits a form, exposes loading/error to UI, or persists user inputs across rebuilds. Triggers: "add a ViewModel", "create a notifier", "add state for X", "loading + error state". Do NOT use for stateless UI widgets, repositories, or one-shot side effects (use ref.listen).
---

# flutter-add-riverpod-viewmodel

Canonical pattern observed across `lib/ui/features/<x>/view_models/`. Mirror it exactly — drift wastes a future refactor.

## When to use

- Screen needs loading / error / success state.
- Form input survives rebuilds (controllers + multi-step submit).
- Async work (Supabase, storage, geolocation) needs to be cancellable or scoped to screen lifetime.
- Multiple widgets in the same screen share state.

Skip when: logic is pure one-shot (use `FutureBuilder`), state is read-only (use `Provider`/`FutureProvider`), or state must outlive the screen (use `NotifierProvider` non-autoDispose).

## File layout

```
lib/ui/features/<feature>/view_models/<verb>_<noun>_view_model.dart
```

Names follow existing files: `sign_in_view_model.dart`, `create_spot_view_model.dart`, `map_view_model.dart`.

## Template

Three blocks in one file: enum, state, notifier+provider.

### 1. Status enum (top-level)

```dart
enum SubmitState { idle, loading, success, error }
```

- Names match action verb when short (`SubmitState`); use `<Feature>Status` (e.g. `AuthFormStatus`) when shared across screens.
- Always include `idle`. Always include terminal `success` and `error`.

### 2. Immutable state

```dart
@immutable
class FooState {
  const FooState({
    this.status = SubmitState.idle,
    this.errorMessage,
    this.value,
  });

  final SubmitState status;
  final String? errorMessage;
  final String? value;

  FooState copyWith({
    SubmitState? status,
    String? errorMessage,
    String? value,
    bool clearError = false,
    bool clearValue = false,
  }) {
    return FooState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      value: clearValue ? null : (value ?? this.value),
    );
  }
}
```

Rules:
- `@immutable` + `const` constructor + all `final` fields.
- One `copyWith` per state. Every nullable field that can be RESET gets a `clearX` boolean (`clearError`, `clearValue`, `clearPickedLocation`, etc.).
- Computed getters are OK (see `CreateSpotState.filePhotoCount`).
- Never mutate `state` in place — always `state = state.copyWith(...)`.

### 3. Notifier + provider

```dart
class FooViewModel extends AutoDisposeNotifier<FooState> {
  @override
  FooState build() => const FooState();

  Future<bool> submit({required String input}) async {
    state = state.copyWith(status: SubmitState.loading, clearError: true);
    try {
      await ref.read(fooRepositoryProvider).doThing(input: input);
      state = state.copyWith(status: SubmitState.success);
      return true;
    } on AppAuthException catch (e) {
      state = state.copyWith(
        status: SubmitState.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: SubmitState.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void reset() => state = const FooState();
}

final fooViewModelProvider =
    NotifierProvider.autoDispose<FooViewModel, FooState>(FooViewModel.new);
```

Rules:
- `AutoDisposeNotifier` for screen-scoped state (the default in this repo).
- `build()` returns a `const` default state. Never throws.
- One public method per user action. Return `Future<bool>` when caller branches on success/failure (e.g. screen navigates only on success).
- Always wrap side-effect work in try/catch. Catch domain exceptions first (`on AppXException`), then generic `catch (e)` last.
- `clearError: true` on every transition INTO `loading` (prevents stale messages).
- Side setters (no async) for input fields: `setType(SpotType t) => state = state.copyWith(type: t);`
- Provider at bottom, named `<feature>ViewModelProvider`. Use `NotifierProvider.autoDispose<...>(...)` syntax (see `createSpotViewModelProvider`) — `signIn` uses `AutoDisposeNotifierProvider<...>`; both compile, but the `NotifierProvider.autoDispose` form is preferred for new code.
- Imports: `package:flutter/foundation.dart` for `@immutable`, `package:flutter_riverpod/flutter_riverpod.dart` for `Notifier`/`Provider`.

## Wiring in a screen

```dart
class FooScreen extends ConsumerStatefulWidget {
  const FooScreen({super.key});
  @override
  ConsumerState<FooScreen> createState() => _FooScreenState();
}

class _FooScreenState extends ConsumerState<FooScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _showSnack(String m) { /* standard */ }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fooViewModelProvider);
    final loading = state.status == SubmitState.loading;

    ref.listen(fooViewModelProvider, (prev, next) {
      if (next.status == SubmitState.error &&
          next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        _showSnack(next.errorMessage!);
      }
      if (next.status == SubmitState.success &&
          prev?.status != SubmitState.success) {
        context.go(AppRoutes.map);
      }
    });

    return Scaffold(/* uses `loading`, calls vm methods */);
  }
}
```

Rules:
- `ref.watch` for state shown in UI.
- `ref.read(provider.notifier).method(...)` to invoke.
- `ref.listen` for one-shot side effects (snackbars, navigation, dialogs). Guard on `prev?.X != next.X` to avoid repeat.
- Controllers live in the `State`, not the VM. `dispose()` is mandatory.

## Validation checklist

- [ ] Filename: `lib/ui/features/<x>/view_models/<verb>_<noun>_view_model.dart`
- [ ] `enum Status` at top-level
- [ ] `@immutable` state with `const` ctor and `copyWith` (incl. `clearX` bools for every nullable)
- [ ] Notifier extends `AutoDisposeNotifier<State>`
- [ ] `build()` returns `const` default
- [ ] Every action sets loading → try/catch → success/error
- [ ] `clearError: true` on loading transitions
- [ ] `reset()` method exists for forms that need it
- [ ] Provider declared at file bottom
- [ ] Screen uses `ref.watch` for state, `ref.read(provider.notifier).method(...)` for actions, `ref.listen` for one-shot effects
- [ ] Controllers `dispose()`d
- [ ] `dart analyze` clean
