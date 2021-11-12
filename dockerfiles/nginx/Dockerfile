FROM fedora:35

RUN dnf install -y nginx
COPY nginx.conf /etc/
RUN chmod ugo+rwX -Rc /var/log/nginx /var/lib/nginx

RUN useradd -u 2200 runuser
USER runuser

ENTRYPOINT ["nginx", "-c", "/etc/nginx.conf"]
