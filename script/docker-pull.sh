# /docker-php/script/docker-pull.sh
docker login -u="$DOCKER_USER" -p="$DOCKER_PASS" -e="$DOCKER_EMAIL" \
&& docker push cbsan/php:5.6;