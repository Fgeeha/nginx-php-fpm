## Сборка из исходников

Требуются Docker и GNU Make. Из корня репозитория:

```sh
make help
make check
```

`make check` собирает образ `nginx-php-fpm:local` и проверяет версии PHP и
Alpine, расширения PHP, конфигурации Nginx и PHP-FPM, Composer, Certbot,
выполнение PHP через HTTP, статический файл и ответ 404.
Проверки запускаются с OPcache и с его отключением через `OPcache=1`.

Для отдельных шагов используйте `make build` и `make test`.
Имя образа можно задать через `make check IMAGE=nginx-php-fpm:latest`.

Базовый образ — `php:8.2.35-fpm-alpine3.24`. PHP 8.2.35 исправляет
CVE-2026-109618 и CVE-2026-109619:
[официальная рекомендация PHP](https://www.php.net/archive/2026.php).
После сборки необходимо пересоздать работающие контейнеры из нового образа.
