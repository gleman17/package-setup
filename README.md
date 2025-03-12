# Laravel Package Generator

A bash script to quickly scaffold Laravel packages with proper structure and configuration.

For some usages, this is much less hassle than starting with a clone of a template.

## Features

- Creates a complete Laravel package structure in seconds
- Sets up PSR-4 autoloading with proper namespacing
- Configures composer.json with Laravel-specific settings
- Creates a service provider that handles:
    - Config merging and publishing
    - Migration publishing
    - Route loading
    - View loading
    - Translation loading
- Generates necessary directories for organized code
- Creates stub files (config, tests) to get you started
- Provides clear instructions for local package development

## Requirements

- PHP 8.0 or higher
- Composer
- jq (for JSON manipulation)
- bash shell

## Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/laravel-package-generator.git

# Make the script executable
chmod +x ./laravel-package-generator/package-generator.sh

# Optional: move to a directory in your PATH
sudo mv ./laravel-package-generator/package-generator.sh /usr/local/bin/laravel-package
```

## Usage

Navigate to the parent directory where you want to create your package and run:

```bash
laravel-package vendor/package-name
```

For example:

```bash
laravel-package acme/blog
```

This will create a new package at `./acme/blog` with all the necessary structure.

## Directory Structure

The script creates the following directory structure:

```
vendor/package/
├── composer.json
├── src/
│   ├── Config/
│   │   └── config.php
│   ├── Migrations/
│   ├── Routes/
│   ├── Views/
│   ├── Lang/
│   └── ServiceProvider.php
└── tests/
    ├── Feature/
    │   └── ExampleTest.php
    └── Unit/
```

## Using Your Package in a Laravel Project

After creating your package, follow these steps to use it in a Laravel project:

1. Open your Laravel project's `composer.json` file and add the package path to the repositories section:

```json
"repositories": [
    {
        "type": "path",
        "url": "/absolute/path/to/vendor/package"
    }
]
```

2. Require the package:

```bash
composer require vendor/package:* --prefer-source
```

3. Publish package assets (if applicable):

```bash
php artisan vendor:publish --tag=package-migrations
php artisan vendor:publish --tag=package-config
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
