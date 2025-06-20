# 使用官方 PHP 8.3 FPM 鏡像作為基礎
FROM php:8.3-fpm-alpine

# 安裝系統依賴
RUN apk add --no-cache \
    nginx \
    git \
    curl \
    libzip-dev \
    libpng-dev \
    jpeg-dev \
    postgresql-dev \
    mysql-client \
    nodejs \
    npm \
    build-base \
    autoconf \
    g++ \
    make \
    pcre-dev \
    zlib-dev

# 安裝 PHP 擴展
RUN docker-php-ext-install pdo pdo_mysql zip opcache gd
RUN docker-php-ext-configure gd --with-jpeg=/usr/include/
# 安裝 Redis 擴展 (phpredis)
RUN pecl install -o -f redis \
    && rm -rf /tmp/pear \
    && docker-php-ext-enable redis

# 安裝 Composer
COPY --from=composer/composer:latest-bin /composer /usr/bin/composer

# 設置工作目錄
WORKDIR /var/www/html

# 複製應用代碼 (composer install 將在容器內部執行)
COPY . /var/www/html

# 安裝 Composer 依賴
RUN composer install --no-dev --optimize-autoloader

# 運行 Artisan 命令，在首次構建時初始化 Laravel
# 但對於 GitHub Repo，我們不會在 Dockerfile 裡執行 migraion，讓用戶手動執行
RUN php artisan key:generate --ansi || true # 允許在 CI/CD 中跳過
RUN php artisan storage:link || true # 允許在 CI/CD 中跳過

# 設定目錄權限，確保 Web 服務器可以寫入
RUN chown -R www-data:www-data /var/www/html/storage \
    && chown -R www-data:www-data /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache

# 暴露 FPM 端口
EXPOSE 9000

# 啟動 PHP-FPM
CMD ["php-fpm"]
