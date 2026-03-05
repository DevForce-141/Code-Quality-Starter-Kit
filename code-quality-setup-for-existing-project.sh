#!/usr/bin/env bash

# =============================================================================
# DevForce 141 — Code Quality Pipeline Setup
# =============================================================================
# Run this once in the root of any new or existing Laravel project.
# It installs all tools and drops the baseline config files in place.
#
# Usage:
#   bash setup-quality-pipeline.sh
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()    { echo -e "${CYAN}▶ $1${NC}"; }
ok()     { echo -e "${GREEN}✓ $1${NC}"; }
warn()   { echo -e "${YELLOW}⚠ $1${NC}"; }
fail()   {
    echo -e "${RED}✗ $1${NC}"
    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  Script stopped early due to an error above.    ${NC}"
    echo -e "${RED}  Review the log, fix the issue, and re-run.     ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    read -rp "Press Enter to exit..."
    exit 1
}

# Run a command; on failure, report exactly which command failed
run() {
    local label="$1"; shift
    echo -e "${CYAN}  $ $*${NC}"
    if ! "$@" ; then
        fail "Failed: ${label}"
    fi
}

# Write a config file only if it doesn't already exist
write_config() {
    local filepath="$1"
    local content="$2"
    if [ -f "$filepath" ]; then
        warn "$filepath already exists — generation skipped"
    else
        printf '%s\n' "$content" > "$filepath"
        ok "$filepath"
    fi
}

# Guard — must run from a Laravel project root
[ -f "artisan" ] || fail "No artisan file found. Run this from the root of a Laravel project."

echo ""
echo -e "${CYAN}=================================================${NC}"
echo -e "${CYAN}  DevForce 141 — Code Quality Pipeline Setup     ${NC}"
echo -e "${CYAN}=================================================${NC}"
echo ""

# =============================================================================
# 1. PHP DEPENDENCIES
# =============================================================================
log "Installing PHP dev dependencies..."

run "composer require laravel/pint" \
    composer require laravel/pint --dev -q
ok "Laravel Pint installed"

run "composer require larastan/larastan" \
    composer require larastan/larastan --dev -q
ok "Larastan (PHPStan) installed"

# Allow the Pest composer plugin before installing — required since Composer 2.2
log "Allowing pestphp/pest-plugin in Composer..."
run "composer config allow-plugins.pestphp/pest-plugin true" \
    composer config allow-plugins.pestphp/pest-plugin true
ok "pestphp/pest-plugin allowed"

run "composer require pestphp/pest" \
    composer require pestphp/pest --dev --with-all-dependencies -q
ok "Pest PHP installed"

run "composer require pestphp/pest-plugin-laravel" \
    composer require pestphp/pest-plugin-laravel --dev -q
ok "Pest Laravel plugin installed"

run "composer require rector/rector" \
    composer require rector/rector --dev -q
ok "Rector installed"

# =============================================================================
# 2. NODE DEPENDENCIES
# =============================================================================
log "Installing Node dev dependencies..."

run "npm install prettier + plugins + eslint" \
    npm install -D \
        prettier \
        prettier-plugin-blade \
        prettier-plugin-tailwindcss \
        eslint \
        @eslint/js \
        globals \
        --silent

ok "Prettier + plugins installed"
ok "ESLint installed"

# =============================================================================
# 3. CONFIG FILES
# =============================================================================
log "Writing config files..."

# ---- pint.json ----
write_config "pint.json" '{
    "preset": "laravel",
    "rules": {
        "single_line_comment_style": false,
        "single_line_comment_spacing": false
    }
}'

# ---- phpstan.neon ----
write_config "phpstan.neon" 'includes:
    - vendor/larastan/larastan/extension.neon

parameters:
    paths:
        - app

    level: 6

    ignoreErrors:
        - '"'"'#Unsafe usage of new static#'"'"''

# ---- rector.php ----
write_config "rector.php" '<?php

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;

return RectorConfig::configure()
    ->withPaths([
        __DIR__ . '"'"'/app'"'"',
        __DIR__ . '"'"'/tests'"'"',
    ])
    ->withSets([
        LevelSetList::UP_TO_PHP_82,
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
    ]);'

# ---- prettier.config.js ----
write_config "prettier.config.js" "import bladePlugin from 'prettier-plugin-blade';
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
};"

# ---- eslint.config.js ----
write_config "eslint.config.js" "import js from '@eslint/js';
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
];"

# ---- .prettierignore ----
write_config ".prettierignore" '# SVG components — not useful to format
resources/views/components/svgs/**'

# =============================================================================
# 4. PEST INIT (only if tests/Pest.php doesn't exist)
# =============================================================================
if [ ! -f "tests/Pest.php" ]; then
    log "Initialising Pest..."
    mkdir -p tests
    run "pest --init" ./vendor/bin/pest --init -q
    ok "Pest initialised"
else
    warn "tests/Pest.php already exists — Pest init skipped"
fi

# =============================================================================
# 5. ARCHITECTURE TESTS SCAFFOLD
# =============================================================================
if [ ! -f "tests/Architecture/ConventionsTest.php" ]; then
    log "Scaffolding architecture tests..."
    mkdir -p tests/Architecture

    write_config "tests/Architecture/ConventionsTest.php" '<?php

arch('"'"'actions are invokable'"'"')
    ->expect('"'"'App\Actions'"'"')
    ->toBeInvokable();

arch('"'"'models do not contain business logic'"'"')
    ->expect('"'"'App\Models'"'"')
    ->not->toHavePublicMethodsBesides([
        '"'"'relationships'"'"', '"'"'scopes'"'"', '"'"'casts'"'"', '"'"'fillable'"'"',
        '"'"'boot'"'"', '"'"'booted'"'"', '"'"'newCollection'"'"',
    ]);

arch('"'"'controllers do not query the database directly'"'"')
    ->expect('"'"'App\Http\Controllers'"'"')
    ->not->toUse(['"'"'Illuminate\Support\Facades\DB'"'"']);

arch('"'"'enums are properly placed'"'"')
    ->expect('"'"'App\Enums'"'"')
    ->toBeEnum();

arch('"'"'no debug functions in codebase'"'"')
    ->expect('"'"'App'"'"')
    ->not->toUse(['"'"'dd'"'"', '"'"'dump'"'"', '"'"'ray'"'"', '"'"'var_dump'"'"', '"'"'print_r'"'"']);

arch('"'"'form requests extend the base class'"'"')
    ->expect('"'"'App\Http\Requests'"'"')
    ->toExtend('"'"'Illuminate\Foundation\Http\FormRequest'"'"');'
else
    warn "tests/Architecture/ConventionsTest.php already exists — skipped"
fi

# =============================================================================
# 6. PACKAGE.JSON — ensure "type": "module"
# =============================================================================
if [ -f "package.json" ]; then
    if ! grep -q '"type": "module"' package.json; then
        warn "Add \"type\": \"module\" to package.json manually (needed for ESM config files)"
    else
        ok "package.json already has type:module"
    fi
fi

# =============================================================================
# 7. SCRIPT ALIASES — composer.json
# =============================================================================
log "Injecting composer script aliases..."

run "update composer.json scripts" php -r "
\$composer = json_decode(file_get_contents('composer.json'), true);

\$scripts = [
    'lint'           => './vendor/bin/pint',
    'lint:check'     => './vendor/bin/pint --test',
    'analyse'        => './vendor/bin/phpstan analyse',
    'test'           => './vendor/bin/pest',
    'test:arch'      => './vendor/bin/pest tests/Architecture',
    'refactor'       => './vendor/bin/rector process --dry-run',
    'refactor:apply' => './vendor/bin/rector process',
    'quality'        => [
        '@lint',
        '@analyse',
        '@test',
    ],
];

foreach (\$scripts as \$key => \$value) {
    \$composer['scripts'][\$key] = \$value;
}

file_put_contents('composer.json', json_encode(\$composer, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . PHP_EOL);
"
ok "composer.json scripts updated"

# =============================================================================
# 8. SCRIPT ALIASES — package.json
# =============================================================================
log "Injecting npm script aliases..."

run "update package.json scripts" php -r "
\$pkg = json_decode(file_get_contents('package.json'), true);

\$scripts = [
    'lint:js'      => 'eslint resources/js',
    'lint:js:fix'  => 'eslint resources/js --fix',
    'format'       => 'prettier --write \"resources/**/*.{html,js,blade.php}\"',
    'format:check' => 'prettier --check \"resources/**/*.{html,js,blade.php}\"',
    'quality'      => 'npm run lint:js && npm run format',
];

foreach (\$scripts as \$key => \$value) {
    \$pkg['scripts'][\$key] = \$value;
}

file_put_contents('package.json', json_encode(\$pkg, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . PHP_EOL);
"
ok "package.json scripts updated"

# =============================================================================
# DONE
# =============================================================================
echo ""
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}  All done. Quality pipeline is ready.          ${NC}"
echo -e "${GREEN}=================================================${NC}"
echo ""
echo "  PHP (composer run ...):"
echo "    lint              fix PHP style with Pint"
echo "    lint:check        check only, no changes"
echo "    analyse           run PHPStan static analysis"
echo "    test              run all Pest tests"
echo "    test:arch         run architecture tests only"
echo "    refactor          dry-run Rector"
echo "    refactor:apply    apply Rector changes"
echo "    quality           lint + analyse + test in one shot"
echo ""
echo "  JS/Frontend (npm run ...):"
echo "    lint:js           ESLint check"
echo "    lint:js:fix       ESLint auto-fix"
echo "    format            Prettier format all blade/js/html"
echo "    format:check      Prettier check only"
echo "    quality           lint:js + format"
echo ""
warn "Review tests/Architecture/ConventionsTest.php and adjust rules to your project."
echo ""
read -rp "Press Enter to exit..."