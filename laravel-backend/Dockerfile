FROM php:8.3-fpm-alpine

# 安裝系統依賴和 PHP 擴展
RUN apk add --no-cache \
    nginx \
    nodejs \
    npm \
    git \
    zip \
    unzip \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    icu-dev \
    g++ \
    make \
    autoconf \
    openssl-dev && \
    docker-php-ext-install pdo_mysql opcache bcmath exif gd pcntl zip intl && \
    docker-php-ext-enable opcache && \
    apk del g++ make autoconf # 清理構建依賴

# 安裝 Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

WORKDIR /var/www/html

# 複製 composer.json 和 package.json 提前安裝依賴，利用 Docker 層緩存
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader

COPY package.json package-lock.json ./
RUN npm install

# 複製應用程式代碼
COPY . .

# 設定儲存權限
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache && \
    chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# 暴露 PHP-FPM 端口
EXPOSE 9000

# 啟動 PHP-FPM
CMD ["php-fpm"]
