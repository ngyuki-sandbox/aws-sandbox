FROM php:alpine

COPY --from=composer /usr/bin/composer /usr/bin/composer

COPY composer.* /home/app/
WORKDIR /home/app/
RUN composer install --prefer-dist --no-dev --no-progress -o -a

COPY bin/      /home/app/bin/
COPY handlers/ /home/app/handlers/

ENTRYPOINT [ "/home/app/bin/bootstrap" ]
RUN chmod +x /home/app/bin/bootstrap

ARG VERSION
ENV VERSION $VERSION

CMD [ "handlers/index.php" ]
