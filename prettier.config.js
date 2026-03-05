import bladePlugin from 'prettier-plugin-blade';
import * as tailwindPlugin from 'prettier-plugin-tailwindcss';

export default {
    semi: true,
    singleQuote: true,
    tabWidth: 4,
    printWidth: 120,

    plugins: [
        bladePlugin,
        tailwindPlugin,
    ],

    overrides: [
        {
            files: ['*.blade.php'],
            options: {
                parser: 'blade',
                tabWidth: 4,
                printWidth: 120,
                tailwindAttributes: ['class', 'x-bind:class', ':class'],
                tailwindFunctions: ['clsx', 'cn'],
            },
        },
    ],

    tailwindFunctions: ['clsx', 'cn', 'tv'],
    tailwindAttributes: ['class', 'x-bind:class', ':class'],
};
