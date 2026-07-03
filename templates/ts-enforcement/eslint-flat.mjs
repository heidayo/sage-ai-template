// SAGE TS enforcement — ESLint flat config fragment (standard / strict variant)
// SPEC-0030: TypeScript Enforcement preset
//
// Prerequisites: typescript-eslint (@typescript-eslint v6+) installed and the
// @typescript-eslint plugin already registered in your flat config
// (e.g. via typescript-eslint's `tseslint.configs.recommended`).
//
// How to apply (copy this file next to your eslint.config.mjs, then spread it in):
//
//   import sageTsEnforcement from './eslint-flat.mjs';
//
//   export default [
//     ...tseslint.configs.recommended,
//     ...sageTsEnforcement,
//   ];
//
// Rules:
//   - @typescript-eslint/ban-ts-comment: error
//       @ts-ignore / @ts-nocheck are forbidden.
//       @ts-expect-error is allowed only with a description (legitimate
//       suppressions must explain themselves).
//   - @typescript-eslint/no-explicit-any: error
//       For legacy codebases that cannot go straight to error, start with
//       eslint-flat-transitional.mjs (no-explicit-any: warn) and graduate to
//       this file once warn findings reach zero (see docs/ts-enforcement.md).
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
      '@typescript-eslint/no-explicit-any': 'error',
    },
  },
];
