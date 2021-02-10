FROM archlinux/base

RUN pacman -Syu --noconfirm apache
ADD ./ksfiles/*.tar ./ksfiles/*.ks /srv/http/
EXPOSE 80

CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
