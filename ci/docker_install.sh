#!/bin/bash

# We need to install dependencies only for Docker
[[ ! -e /.dockerenv ]] && exit 0

set -xe

# Install git (the php image doesn't have it) which is required by composer
apt-get update -yqq
apt-get install git libmcrypt-dev zlib1g-dev -yqq
docker-php-ext-install mcrypt
docker-php-ext-install zip

#curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
#php /usr/bin/composer install