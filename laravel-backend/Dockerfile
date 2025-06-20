FROM php:8.2-fpm

# 安裝系統依賴
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    nodejs \
    npm \
    libzip-dev \
    libicu-dev \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# 安裝 PHP 擴展
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd opcache zip intl

# 安裝 Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

WORKDIR /var/www/html

# 複製 Composer 相關文件和 .env.example 以便在容器內安裝依賴
COPY composer.json composer.lock ./
COPY .env.example ./

# 安裝 Composer 依賴
RUN composer install --no-dev --optimize-autoloader

# 複製 Node.js 相關文件
COPY package.json package-lock.json ./

# 安裝 Node.js 依賴並編譯前端資源 (如果你的 Laravel 專案包含前端)
# 這步會下載大量 Node 模組，如果前端由獨立容器或 CI/CD 處理，此處可省略。
RUN npm install && npm run prod

# 複製所有 Laravel 應用文件
COPY . .

# 設定權限
RUN chown -R www-data:www-data storage bootstrap/cache
RUN chmod -R 775 storage bootstrap/cache

# 複製 Supervisor 配置
COPY docker-config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 9000
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
