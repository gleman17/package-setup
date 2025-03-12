#!/bin/bash

# Ensure a package name is provided
if [ -z "$1" ]; then
    echo "Usage: $0 vendor/package-name"
    exit 1
fi

# Extract vendor and package name
VENDOR=$(echo $1 | cut -d'/' -f1)
PACKAGE=$(echo $1 | cut -d'/' -f2)
PACKAGE_NAMESPACE=$(echo "$VENDOR" | sed -E 's/(^|-)([a-z])/\U\2/g')\\"$(echo "$PACKAGE" | sed -E 's/(^|-)([a-z])/\U\2/g')"

# Define package directory based on the current working directory
PACKAGE_DIR="$(pwd)/$VENDOR/$PACKAGE"

# Ensure the parent directories exist
mkdir -p "$PACKAGE_DIR"

# Exit if the directory wasn't created
if [ ! -d "$PACKAGE_DIR" ]; then
    echo "ERROR: Failed to create package directory $PACKAGE_DIR"
    exit 1
fi

# Navigate to the package directory
cd "$PACKAGE_DIR" || { echo "ERROR: Failed to navigate to $PACKAGE_DIR"; exit 1; }

# Create necessary subdirectories
for DIR in src/Config src/Migrations src/Routes src/Views src/Lang tests/Feature tests/Unit; do
    mkdir -p "$PACKAGE_DIR/$DIR"
    if [ ! -d "$PACKAGE_DIR/$DIR" ]; then
        echo "ERROR: Failed to create directory $PACKAGE_DIR/$DIR"
        exit 1
    fi
done

# Initialize composer
composer init --name="$1" --type=library --require="php:>=8.0" --require-dev="phpunit/phpunit:^10.0" --no-interaction

# Add Laravel-specific configurations
PACKAGE_NAMESPACE_ESCAPED=$(echo "$PACKAGE_NAMESPACE" | sed 's/\\/\\\\/g')

jq --arg namespace "$PACKAGE_NAMESPACE_ESCAPED" '. + {
    "autoload": {
        "psr-4": {
            ($namespace + "\\\\") : "src/"
        }
    },
    "extra": {
        "laravel": {
            "providers": [
                ($namespace + "\\\\ServiceProvider")
            ]
        }
    }
}' composer.json > composer.json.tmp && mv composer.json.tmp composer.json

# Create the Service Provider with package-specific publishing tags
cat <<EOL > "$PACKAGE_DIR/src/ServiceProvider.php"
<?php

namespace $PACKAGE_NAMESPACE;

use Illuminate\Support\ServiceProvider;

class ServiceProvider extends ServiceProvider
{
    public function register()
    {
        \$this->mergeConfigFrom(__DIR__.'/Config/config.php', '$PACKAGE');
    }

    public function boot()
    {
        if (\$this->app->runningInConsole()) {
            \$this->publishes([
                __DIR__.'/Config/config.php' => config_path('$PACKAGE.php'),
            ], '$PACKAGE-config');

            \$this->publishes([
                __DIR__.'/Migrations/' => database_path('migrations'),
            ], '$PACKAGE-migrations');

            if (file_exists(__DIR__.'/Routes/web.php')) {
                \$this->loadRoutesFrom(__DIR__.'/Routes/web.php');
            }

            if (file_exists(__DIR__.'/Views')) {
                \$this->loadViewsFrom(__DIR__.'/Views', '$PACKAGE');
            }

            if (file_exists(__DIR__.'/Lang')) {
                \$this->loadTranslationsFrom(__DIR__.'/Lang', '$PACKAGE');
            }
        }
    }
}
EOL

# Verify Service Provider
if [ ! -f "$PACKAGE_DIR/src/ServiceProvider.php" ]; then
    echo "ERROR: Failed to create ServiceProvider.php"
    exit 1
fi

# Create default config file
cat <<EOL > "$PACKAGE_DIR/src/Config/config.php"
<?php

return [
    'example_setting' => true,
];
EOL

# Verify config file
if [ ! -f "$PACKAGE_DIR/src/Config/config.php" ]; then
    echo "ERROR: Failed to create config.php"
    exit 1
fi

# Create test stub
cat <<EOL > "$PACKAGE_DIR/tests/Feature/ExampleTest.php"
<?php

test('example test', function () {
    expect(true)->toBeTrue();
});
EOL

# Verify test file
if [ ! -f "$PACKAGE_DIR/tests/Feature/ExampleTest.php" ]; then
    echo "ERROR: Failed to create ExampleTest.php"
    exit 1
fi

# Run composer dump-autoload
composer dump-autoload

# Print final instructions
echo -e "\n🎉 Package setup complete! 🎉"
echo -e "\n📦 Your package was created in: \033[1;32m$PACKAGE_DIR\033[0m"
echo -e "\n🚀 To use this package in a Laravel project, follow these steps:"
echo -e "1️⃣ Open your Laravel project's composer.json file and add the following entry under 'repositories':\n"
echo -e "   \033[1;34m\"repositories\": [\n       {\n           \"type\": \"path\",\n           \"url\": \"$PACKAGE_DIR\"\n       }\n   ]\033[0m\n"
echo -e "2️⃣ Run the following command inside your Laravel project:\n"
echo -e "   \033[1;32mcomposer require $1:* --prefer-source\033[0m\n"
echo -e "3️⃣ If your package has migrations, publish them with:\n"
echo -e "   \033[1;32mphp artisan vendor:publish --tag=$PACKAGE-migrations\033[0m\n"
echo -e "4️⃣ If your package has config files, publish them with:\n"
echo -e "   \033[1;32mphp artisan vendor:publish --tag=$PACKAGE-config\033[0m\n"
echo -e "5️⃣ Start developing! 🚀"
