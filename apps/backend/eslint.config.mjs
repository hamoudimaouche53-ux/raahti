// Architecture-boundary enforcement per docs/architecture/module-dependency-diagram.md
// and docs/architecture/repository-structure.md. Extended module-by-module as each
// bounded context gains real code (Phase 4 Implementation Plan §7).
import js from '@eslint/js';
import tseslint from '@typescript-eslint/eslint-plugin';
import tsParser from '@typescript-eslint/parser';
import importPlugin from 'eslint-plugin-import';
import prettier from 'eslint-config-prettier';
import globals from 'globals';

export default [
  js.configs.recommended,
  {
    files: ['src/**/*.ts', 'test/**/*.ts'],
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        sourceType: 'module',
      },
      globals: {
        ...globals.node,
        ...globals.jest,
      },
    },
    plugins: {
      '@typescript-eslint': tseslint,
      import: importPlugin,
    },
    rules: {
      ...tseslint.configs.recommended.rules,
      '@typescript-eslint/interface-name-prefix': 'off',
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/explicit-module-boundary-types': 'off',
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_', varsIgnorePattern: '^_' }],
      'import/no-restricted-paths': [
        'error',
        {
          zones: [
            {
              // Domain layer: zero outward imports beyond shared-kernel (System
              // Architecture §3 — "Zero imports from NestJS, Prisma, or any I/O library").
              target: './src/modules/*/domain',
              from: [
                './src/modules/*/application',
                './src/modules/*/infrastructure',
                './src/modules/*/interface',
                './src/platform',
              ],
              message:
                'domain/ may not import application/, infrastructure/, interface/, or platform/ — see system-architecture.md §3.',
            },
            {
              target: './src/modules/*/domain',
              from: ['./node_modules/@nestjs', './node_modules/@prisma'],
              message: 'domain/ must be plain TypeScript — no NestJS or Prisma imports.',
            },
            {
              // Interface layer depends only on this module's application/ (repository-structure.md §3 table).
              target: './src/modules/*/interface',
              from: ['./src/modules/*/infrastructure'],
              message:
                'interface/ may not import infrastructure/ directly — depend on application/ only.',
            },
            {
              // No cross-module repository/infrastructure access (module-dependency-diagram.md §5 rule 1).
              target: './src/modules/identity',
              from: [
                './src/modules/station-network/infrastructure',
                './src/modules/station-network/domain',
                './src/modules/third-party-places/infrastructure',
                './src/modules/third-party-places/domain',
              ],
              message:
                "No cross-module repository/domain access — depend on the other module's exported application service only.",
            },
            {
              // No module may import identity/ directly — the module-dependency-diagram.md §3
              // matrix grants no module a sanctioned dependency on IdentityModule. Cross-cutting
              // AuthN/AuthZ decorators/types (@Public, @Roles, @CurrentUser, AuthenticatedPrincipal)
              // live in platform/auth/ specifically so every module CAN use them without this
              // violation — caught the hard way once already (Facilities module, Phase 4).
              target: ['./src/modules/station-network', './src/modules/third-party-places', './src/modules/slatoki'],
              from: ['./src/modules/identity'],
              message:
                'No module may import identity/ directly — use platform/auth/ for AuthN/AuthZ decorators and types.',
            },
            {
              // Slatoki (module-dependency-diagram.md §3: the only module with a
              // sanctioned read dependency on BOTH Station Network and Third-Party
              // Places) may depend only on their exported *QueryService (application/)
              // — never their domain/infrastructure/interface layers.
              target: './src/modules/slatoki',
              from: [
                './src/modules/station-network/domain',
                './src/modules/station-network/infrastructure',
                './src/modules/station-network/interface',
                './src/modules/third-party-places/domain',
                './src/modules/third-party-places/infrastructure',
                './src/modules/third-party-places/interface',
              ],
              message:
                "Slatoki may only depend on the other module's exported *QueryService (application/) — see module-dependency-diagram.md §3.",
            },
            {
              // Nothing may depend on Slatoki — the matrix grants it read edges
              // outward only (Slatoki -.->|read| StationNetwork/ThirdPartyPlaces),
              // never the reverse.
              target: ['./src/modules/station-network', './src/modules/third-party-places', './src/composition'],
              from: ['./src/modules/slatoki'],
              message: 'No module may depend on slatoki/ — its read edges are outward-only (module-dependency-diagram.md §3).',
            },
            {
              // Notifications (module-dependency-diagram.md §3: `Notif -.->|read| Identity`)
              // may depend only on Identity's exported *QueryService (application/) —
              // never its domain/infrastructure/interface layers.
              target: './src/modules/notifications',
              from: ['./src/modules/identity/domain', './src/modules/identity/infrastructure', './src/modules/identity/interface'],
              message:
                "Notifications may only depend on Identity's exported *QueryService (application/) — see module-dependency-diagram.md §3.",
            },
            {
              // Nothing may depend on Notifications — the matrix grants it no incoming
              // edges at all; it is only ever a subscriber (event bus) or itself a
              // read-dependency source, never a dependency of another module.
              target: [
                './src/modules/identity',
                './src/modules/station-network',
                './src/modules/third-party-places',
                './src/modules/slatoki',
                './src/composition',
              ],
              from: ['./src/modules/notifications'],
              message: 'No module may depend on notifications/ — it has no sanctioned incoming edges (module-dependency-diagram.md §3).',
            },
            {
              // Operations (module-dependency-diagram.md §3: `Ops -> StationNet`
              // plain ✔) may depend only on Station Network's exported
              // *QueryService (application/) — never its domain/infrastructure/
              // interface layers.
              target: './src/modules/operations',
              from: [
                './src/modules/station-network/domain',
                './src/modules/station-network/infrastructure',
                './src/modules/station-network/interface',
              ],
              message:
                "Operations may only depend on Station Network's exported *QueryService (application/) — see module-dependency-diagram.md §3.",
            },
            {
              // The matrix grants Operations no incoming edges from any module
              // built so far (Analytics -> Ops is the only sanctioned inbound
              // edge, and AnalyticsModule doesn't exist yet — out of scope for
              // this pass per Phase 4 Implementation Plan §6).
              target: [
                './src/modules/identity',
                './src/modules/station-network',
                './src/modules/third-party-places',
                './src/modules/slatoki',
                './src/modules/notifications',
                './src/composition',
              ],
              from: ['./src/modules/operations'],
              message:
                'No module may depend on operations/ — its only sanctioned incoming edge (Analytics) is out of scope for this pass (module-dependency-diagram.md §3).',
            },
            {
              // Access & Payment (module-dependency-diagram.md §3: `AccessPay -> StationNet`
              // plain ✔, a COMMAND dependency) may depend only on Station Network's
              // exported *Service (application/) — never its domain/infrastructure/
              // interface layers.
              target: './src/modules/access-payment',
              from: [
                './src/modules/station-network/domain',
                './src/modules/station-network/infrastructure',
                './src/modules/station-network/interface',
              ],
              message:
                "Access & Payment may only depend on Station Network's exported *Service (application/) — see module-dependency-diagram.md §3.",
            },
            {
              // The matrix grants Access & Payment exactly one incoming edge
              // (`AP -.->|event: PaymentCaptured| NT`, event-based, not a
              // direct code dependency) — no module may import access-payment/
              // directly.
              target: [
                './src/modules/identity',
                './src/modules/station-network',
                './src/modules/third-party-places',
                './src/modules/slatoki',
                './src/modules/notifications',
                './src/modules/operations',
                './src/composition',
              ],
              from: ['./src/modules/access-payment'],
              message:
                'No module may depend on access-payment/ directly — its only sanctioned outgoing relationship to another module is the PaymentCaptured event (module-dependency-diagram.md §3).',
            },
            {
              // Places composition layer (ADR-0029) may depend ONLY on each Facilities
              // module's exported *QueryService (application/) — never their domain/,
              // infrastructure/, or interface/ layers directly.
              target: './src/composition',
              from: [
                './src/modules/station-network/domain',
                './src/modules/station-network/infrastructure',
                './src/modules/station-network/interface',
                './src/modules/third-party-places/domain',
                './src/modules/third-party-places/infrastructure',
                './src/modules/third-party-places/interface',
                './src/modules/identity',
              ],
              message:
                'composition/ may only depend on a Facilities module\'s exported *QueryService (application/) — see ADR-0029.',
            },
          ],
        },
      ],
    },
  },
  {
    ignores: ['dist/**', 'node_modules/**', 'coverage/**'],
  },
  prettier,
];
