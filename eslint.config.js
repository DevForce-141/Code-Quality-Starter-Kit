import js from '@eslint/js';
import globals from 'globals';

export default [
    js.configs.recommended,
    {
        files: ['resources/js/**/*.js'],
        languageOptions: {
            globals: {
                ...globals.browser,
                Alpine: 'readonly',
            },
        },
        rules: {
            'no-unused-vars': 'warn',
            'no-console': 'warn',
            'eqeqeq': 'error',
            'no-var': 'error',
            'prefer-const': 'error',
        },
    },
];
