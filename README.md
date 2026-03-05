# DevForce 141 — Laravel Starter Kit

A Laravel 12 starter kit with a full code quality pipeline pre-configured and ready to go from day one.

## What's included

| Tool | Purpose |
|------|---------|
| **Laravel Pint** | PHP code style fixer (Laravel preset) |
| **Larastan / PHPStan** | Static analysis at level 6 |
| **Pest PHP** | Modern test runner with architecture tests |
| **Rector** | Automated refactoring up to PHP 8.2 |
| **Prettier** | Blade, JS, and HTML formatting |
| **ESLint** | JavaScript linting |
| **GitHub Actions** | CI workflow running the full quality pipeline |

All config files (`pint.json`, `phpstan.neon`, `rector.php`, `prettier.config.js`, `eslint.config.js`) are pre-written and ready to use or customise.

Architecture tests live in `tests/Architecture/ConventionsTest.php` — edit them to match your project's conventions.

### For Existing Projects
Installing and setting up each tool manually is annoying, especially if the same process needs to be repeated across many
projects, hence ``code-quality-setup-for-existing-project.sh`` is provided which installs all the quality tools and 
generates their baseline config same as this repo. The bash script is added here to keep both the starter kit and 
the bash script in view, and hopefully keep both of them in sync.

---

## Installation

### New project (recommended)

```bash
laravel new my-app --using=your-vendor/devforce-kit
```

### Clone directly

```bash
git clone https://github.com/your-vendor/devforce-kit my-app
cd my-app
composer install
npm install
cp .env.example .env
php artisan key:generate
php artisan migrate
```

---

## Available commands

### PHP (via Composer)

```bash
composer lint              # Fix PHP code style with Pint
composer lint:check        # Check only — no changes made
composer analyse           # Run PHPStan static analysis
composer test              # Run all Pest tests
composer test:arch         # Run architecture tests only
composer refactor          # Dry-run Rector
composer refactor:apply    # Apply Rector changes
composer quality           # lint + analyse + test in one shot
```

### JS / Frontend (via npm)

```bash
npm run lint:js            # ESLint check
npm run lint:js:fix        # ESLint auto-fix
npm run format             # Prettier format all Blade/JS/HTML
npm run format:check       # Prettier check only
npm run quality            # lint:js + format
```

---

## Architecture tests

`tests/Architecture/ConventionsTest.php` ships with sensible defaults:

- Actions must be invokable
- Models must not contain business logic
- Controllers must not query the DB directly
- Enums must live in `App\Enums`
- No debug functions (`dd`, `dump`, `ray`, etc.) in `App`
- Form requests must extend `Illuminate\Foundation\Http\FormRequest`

Adjust or remove any rule that doesn't fit your project.

---

## Customising the kit

Since this is a starter kit, **you own all the code**. There's nothing to update or publish — just edit the files directly.
