#!/bin/sh
set -eu

image=$1
app_dir=${2:?Укажите APP_DIR с исходниками PHP-проекта}
test -d "$app_dir"

docker run --rm --network none --mount "type=bind,src=$app_dir,dst=/portal,readonly" \
    --entrypoint sh "$image" -ec '
    tar -C /portal --exclude="./.*" -cf - . | tar -C /var/www/html -xf -
    find /var/www/html -type f -name "*.php" -print0 | xargs -0 -n 1 php -l > /tmp/portal-lint.log
    printf "PHP %s; %s; lint: %s files\n" "$(php -r "echo PHP_VERSION;")" "$(uname -m)" "$(wc -l < /tmp/portal-lint.log)"
    printf "PHP source snapshot: "
    find /var/www/html -type f -name "*.php" -print0 | sort -z | xargs -0 sha256sum | sha256sum
    printf "VARIABLE_URL=http://127.0.0.1:8110\nCMS_URL=http://127.0.0.1:8110\nAPI_ADDRESS=http://127.0.0.1:8038\nSITE_URL=\n" > /var/www/html/.env
    printf '\''server { listen 8110; listen 8038; default_type application/json; location / { return 200 "{\"data\":[]}"; } }\n'\'' > /etc/nginx/sites-enabled/test-backend.conf
    /start.sh > /tmp/portal-services.log 2>&1 &
    service_pid=$!
    trap '\''kill "$service_pid" 2>/dev/null || true; wait "$service_pid" || true'\'' EXIT
    ready=0
    for attempt in $(seq 1 60); do
        if curl --silent --fail http://127.0.0.1/ > /tmp/portal-home; then ready=1; break; fi
        sleep 1
    done
    if [ "$ready" != 1 ]; then cat /tmp/portal-services.log; exit 1; fi
    for route in / /news.php /partners.php /faq.php /documents.php /how-to-join.php /policy.php /support.php /cert-programs.php /css/home.css; do
        curl --silent --show-error --fail "http://127.0.0.1$route" > /tmp/portal-response
        printf "%s %s\n" "$route" "$(sha256sum /tmp/portal-response | cut -d " " -f 1)"
    done
    curl --silent --show-error --fail --data "root={}" http://127.0.0.1/siteapi/news-list.php > /tmp/portal-response
    php -r '\''exit(json_decode(file_get_contents("/tmp/portal-response"), true) === ["data" => []] ? 0 : 1);'\''
    if grep -Ei "fatal error|parse error|uncaught|already loaded" /tmp/portal-services.log; then exit 1; fi
    printf "Portal HTTP and API proxy: OK\n"
'
