---
name: spotforfun-add-feature
description: Add a new feature to spot_for_fun following the layered architecture (migration → DTO → mapper → domain → service → repository → ViewModel → screen → router). Use when adding any user-visible capability, e.g. social phase (likes/ratings/comments/favorites/reports), admin tools, profiles, notifications, filters. Triggers: "add a feature", "new screen", "implement X", "fase 7 social", "fase 8 push". Do NOT use for bug fixes (use the right skill) or for one-screen refactors.
---

# spotforfun-add-feature

Repo convention: **UI never talks to Supabase directly**. Data flows:

```
SQL migration
  → DTO (lib/data/models/<x>_dto.dart)
  → mapper (lib/domain/mappers/<x>_mapper.dart)
  → domain model (lib/domain/models/<x>.dart)
  → service (lib/data/services/<x>_service.dart)     [Supabase raw calls]
  → repository (lib/data/repositories/<x>_repository.dart)  [DTO ↔ domain + provider]
  → ViewModel (lib/ui/features/<x>/view_models/<...>_view_model.dart)
  → screen (lib/ui/features/<x>/views/<name>_screen.dart)
  → router (lib/ui/core/router/app_router.dart)
```

Skip no layer. Skipping layers is the #1 source of bugs in this codebase.

## Step 0 — Branch

Per `spotforfun-workflow`:

```bash
git checkout develop && git pull --rebase
git checkout -b feat/<scope>-<subject>
```

Examples (Spanish scope, kebab subject):
- `feat/social-likes`
- `feat/social-ratings`
- `feat/admin-spot-approval`
- `feat/profile-edit`

## Step 1 — SQL migration

Filename: `supabase/migrations/NNNN_<scope>_<subject>.sql`

- `NNNN` = next 4-digit number. Check existing: `ls supabase/migrations/`. **Do not leave gaps** (0003 is currently missing — fill it or note why).
- Idempotent: every `create` paired with `drop if exists ... cascade` at the top, mirroring `0001_init.sql`.
- New tables: enable RLS, define policies for `anon`, `authenticated`, `admin` (use `is_admin()` from `0001_init.sql`).
- New enums: `create type ... as enum (...)`.
- Storage changes: bucket `spot-photos` is the existing pattern; new buckets need insert/select/delete policies.
- Run locally: `psql "$SUPABASE_DB_URL" -f supabase/migrations/NNNN_<...>.sql` (or paste into Supabase SQL editor).

## Step 2 — DTO

`lib/data/models/<x>_dto.dart`:

```dart
class FooDto {
  FooDto({
    required this.id,
    required this.createdAt,
    this.payload,
  });

  final String id;
  final DateTime createdAt;
  final Map<String, dynamic>? payload;

  factory FooDto.fromJson(Map<String, dynamic> json) => FooDto(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        payload: json['payload'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'payload': payload,
      };
}
```

Rules:
- One DTO per SQL table.
- `fromJson` + `toJson` (even when only `fromJson` is used today; the test mocks need both).
- Enum columns: store as `String` in DTO (DB text), decode in mapper.
- Nullable columns → nullable Dart field.

If using codegen later (`flutter-supabase-typed-codegen` skill), this file is generated.

## Step 3 — Mapper

`lib/domain/mappers/<x>_mapper.dart`:

```dart
import 'package:spot_for_fun/data/models/foo_dto.dart';
import 'package:spot_for_fun/domain/models/foo.dart';
import 'package:spot_for_fun/domain/enums.dart';

extension FooMapper on FooDto {
  Foo toDomain() => Foo(
        id: id,
        createdAt: createdAt,
        kind: parseEnum<FooKind>(payload?['kind']),
      );
}
```

Add reverse `extension on Foo { FooDto toDto() => ... }` only when writes need it.

Rules:
- One mapper file per DTO/model pair.
- Use existing enum parsers from `lib/domain/enums.dart` (`parseEnum<T>(...)`, `tryParseEnum<T>(...)`).
- Null handling: when DTO nullable field is required by domain, throw a clear `FormatException` in `toDomain` (better than silent null).

## Step 4 — Domain model

`lib/domain/models/<x>.dart`:

```dart
import 'package:flutter/foundation.dart';

@immutable
class Foo {
  const Foo({
    required this.id,
    required this.createdAt,
    required this.kind,
  });

  final String id;
  final DateTime createdAt;
  final FooKind kind;
}
```

Rules:
- Pure Dart. No Flutter, no Supabase, no Riverpod imports.
- `@immutable` + `const` ctor + `final` fields.
- Used by ViewModels. Never import this layer from a screen directly — go via Repository.

## Step 5 — Service

`lib/data/services/<x>_service.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/data/models/foo_dto.dart';
import 'package:spot_for_fun/ui/core/providers/supabase_client_provider.dart';

class FooService {
  FooService(this._client);
  final SupabaseClient _client;

  Future<List<FooDto>> fetchAll() async {
    final res = await _client.from('foos').select().order('created_at');
    return (res as List).map((j) => FooDto.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<FooDto> create({required Map<String, dynamic> values}) async {
    final res = await _client.from('foos').insert(values).select().single();
    return FooDto.fromJson(res);
  }
}

final fooServiceProvider = Provider<FooService>((ref) {
  return FooService(ref.watch(supabaseClientProvider));
});
```

Rules:
- One method per Supabase query the feature needs.
- Returns DTOs, not domain models. Conversion happens in the repository.
- Provider at the bottom. Reads `supabaseClientProvider`.
- No try/catch — let repository translate exceptions. (Repository catches `PostgrestException`, `StorageException`, `AuthException`, etc., into the project's domain exceptions.)

## Step 6 — Repository

`lib/data/repositories/<x>_repository.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/data/services/foo_service.dart';
import 'package:spot_for_fun/domain/mappers/foo_mapper.dart';
import 'package:spot_for_fun/domain/models/foo.dart';
import 'package:spot_for_fun/ui/core/providers/supabase_client_provider.dart';

class FooRepository {
  FooRepository(this._service);
  final FooService _service;

  Future<List<Foo>> list() async {
    final dtos = await _service.fetchAll();
    return dtos.map((d) => d.toDomain()).toList(growable: false);
  }

  Future<Foo> create({required Map<String, dynamic> values}) async {
    final dto = await _service.create(values: values);
    return dto.toDomain();
  }
}

final fooRepositoryProvider = Provider<FooRepository>((ref) {
  return FooRepository(ref.watch(fooServiceProvider));
});
```

Rules:
- Public API uses domain models only. Never leak DTO.
- Add new domain exception types (e.g. `AppFooException`) if needed in `lib/data/repositories/exceptions/`.
- Provider at bottom, depends on the service provider.

## Step 7 — ViewModel

Use the `flutter-add-riverpod-viewmodel` skill. Filename:
`lib/ui/features/<feature>/view_models/<verb>_<noun>_view_model.dart`

Inside, inject the repository, never the service:

```dart
final res = await ref.read(fooRepositoryProvider).list();
```

## Step 8 — Screen

`lib/ui/features/<feature>/views/<scope>_<subject>_screen.dart`:

```dart
class FooScreen extends ConsumerStatefulWidget {
  const FooScreen({super.key});
  @override
  ConsumerState<FooScreen> createState() => _FooScreenState();
}

class _FooScreenState extends ConsumerState<FooScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fooViewModelProvider);
    ref.listen(fooViewModelProvider, (prev, next) { /* one-shot effects */ });
    return Scaffold(/* uses Theme.of(context); no AppColors.accent hardcoded */);
  }
}
```

Rules:
- `ConsumerStatefulWidget` + `ConsumerState`.
- Never import `package:supabase_flutter` directly. ViewModels and repositories own that boundary.
- Theme: read via `Theme.of(context).colorScheme` — never hardcode colors. (Login/register are the only screens that hardcode brand tokens, by intent.)
- Reuse existing widgets from `lib/ui/shared/widgets/` before inventing new ones.

## Step 9 — Router

`lib/ui/core/router/app_router.dart`:

1. Add a static route name in `AppRoutes`:
   ```dart
   static const fooCreate = '/foos/create';
   static String fooDetail(String id) => '/foos/$id';
   ```
2. Import the screen at top.
3. Add a `GoRoute` in the `GoRouter` definition matching the rest of the structure (see existing routes for `redirect`, `refreshListenable`, etc.).
4. If the route needs auth, the existing `redirect` already redirects unauthenticated users to `/login` — don't duplicate that.
5. If the screen needs `extra`/path params, follow the pattern in `spotDetail`.

## Step 10 — Tests

Empty `test/` dir today. For new features, add at least:

- `test/domain/mappers/<x>_mapper_test.dart` — round-trip DTO ↔ domain.
- `test/data/repositories/<x>_repository_test.dart` — mock service provider, assert mapper calls.
- `test/ui/features/<feature>/view_models/<x>_view_model_test.dart` — fake repository, assert loading/error/success transitions.

Use `package:checks` (already adopted) over `package:matcher`. See `dart-migrate-to-checks-package` skill if existing tests still use `expect`/`isA`.

## Step 11 — Verify + commit

```bash
dart analyze                                # 0 issues
flutter test                                # all green
dart fix --apply                            # mechanical lint
```

Commit per `spotforfun-workflow` (Spanish or English, scope = feature name). Examples:

- `feat(foo): migration + DTO + mapper + domain model`
- `feat(foo): service + repository providers`
- `feat(foo): ViewModel with submit flow`
- `feat(foo): FooScreen + router registration`
- `test(foo): mapper + ViewModel coverage`

Multi-commit preferred over one mega-commit. Land on develop via `feat/<scope>-<subject>` branch.

## Anti-patterns in this repo to avoid

- Screen imports Supabase directly (breaks testability).
- DTO imported inside a `lib/ui/...` file (DTOs live in `lib/data/models/`).
- Hardcoded `AppColors.accent` in a screen (use `Theme.of(context).colorScheme.primary`).
- Provider declared with `Notifier` instead of `NotifierProvider.autoDispose` for screen-scoped state.
- Migration that is not idempotent (next run breaks).
- Router route added without `AppRoutes` constant.

## Reference files

- `supabase/migrations/0001_init.sql` — full schema + RLS style.
- `lib/data/repositories/spot_repository.dart` — canonical repository.
- `lib/data/services/spot_service.dart` — canonical service.
- `lib/ui/features/spots/view_models/create_spot_view_model.dart` — canonical ViewModel.
- `lib/ui/core/router/app_router.dart` — canonical router.
