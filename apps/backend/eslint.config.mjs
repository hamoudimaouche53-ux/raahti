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
