// SAGE TS enforcement — ESLint flat config fragment (transitional variant)
// SPEC-0030: TypeScript Enforcement preset
//
// Prerequisites: typescript-eslint (@typescript-eslint v6+) installed and the
// @typescript-eslint plugin already registered in your flat config.
//
// How to apply (copy this file next to your eslint.config.mjs, then spread it in):
//
//   import sageTsEnforcement from './eslint-flat-transitional.mjs';
//
//   export default [
//     ...tseslint.configs.recommended,
//     ...sageTsEnforcement,
//   ];
//
// This is the legacy-migration variant: identical to eslint-flat.mjs except
// @typescript-eslint/no-explicit-any is 'warn' instead of 'error'.
// ban-ts-comment stays at error in ALL variants — new @ts-ignore / @ts-nocheck
// must never be introduced, even during migration.
//
// Graduation: once a full lint run reports zero no-explicit-any warnings,
// switch to eslint-flat.mjs (error variant). See docs/ts-enforcement.md.
export default [
  {
    files: ['**/*.ts', '**/*.tsx', '**/*.mts', '**/*.cts'],
    rules: {
      '@typescript-eslint/ban-ts-comment': [
        'error',
        {
          'ts-ignore': true,
          'ts-nocheck': true,
          'ts-expect-error': 'allow-with-description',
        },
      ],
      '@typescript-eslint/no-explicit-any': 'warn',
    },
  },
];
