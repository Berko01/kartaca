{% set username = salt['pillar.get']('kartaca:username') %}
{% set uid = salt['pillar.get']('kartaca:uid') %}
{% set gid = salt['pillar.get']('kartaca:gid') %}
{% set homedir = salt['pillar.get']('kartaca:home') %}
{% set shell = salt['pillar.get']('kartaca:shell') %}
{% set password = salt['pillar.get']('kartaca:password') %}

create_group:
  group.present:
    - name: {{ username }}
    - gid: {{ gid }}

create_user:
  user.present:
    - name: {{ username }}
    - uid: {{ uid }}
    - gid: {{ gid }}
    - home: {{ homedir }}
    - shell: {{ shell }}
    - password: {{ password }}
    - createhome: True

add_to_sudoers:
  file.managed:
    - name: /etc/sudoers.d/{{ username }}
    - contents: '{{ username }} ALL=(ALL) NOPASSWD: /usr/bin/apt'
    - mode: 440

set_timezone:
  timezone.system:
    - name: Europe/Istanbul

set_hostname:
  system.hostname:
    - name: kartaca1.local

hosts_entry:
  host.present:
    - ip: 127.0.1.1
    - names:
      - kartaca1.local

install_packages:
  pkg.installed:
    - pkgs:
      - htop
      - tcptraceroute
      - inetutils-ping
      - dnsutils
      - sysstat
      - mtr
      - nginx
      - php
      - php-fpm
      - php-mysql
      - curl
      - gnupg
      - unzip

enable_nginx:
  service.enabled:
    - name: nginx

ip_forwarding:
  sysctl.present:
    - name: net.ipv4.ip_forward
    - value: 1
    - persist: True

download_wordpress:
  cmd.run:
    - name: curl -o /tmp/latest.tar.gz https://wordpress.org/latest.tar.gz
    - creates: /tmp/latest.tar.gz

extract_wordpress:
  archive.extracted:
    - name: /var/www/html
    - source: /tmp/latest.tar.gz
    - archive_format: tar
    - tar_options: z
    - if_missing: /var/www/html/wp-config-sample.php

wp_config:
  file.managed:
    - name: /var/www/html/wp-config.php
    - source: salt://debian/files/wp-config.php.j2
    - template: jinja

nginx_conf:
  file.managed:
    - name: /etc/nginx/nginx.conf
    - source: salt://debian/files/nginx.conf
    - watch_in:
      - service: nginx

ssl_cert:
  file.managed:
    - name: /etc/ssl/certs/ssl-cert-snakeoil.pem
    - source: salt://debian/files/ssl/cert.pem

ssl_key:
  file.managed:
    - name: /etc/ssl/private/ssl-cert-snakeoil.key
    - source: salt://debian/files/ssl/key.pem

monthly_nginx_restart:
  cron.present:
    - name: "systemctl restart nginx"
    - user: root
    - daymonth: 1
    - month: '*'
    - minute: 0
    - hour: 3

logrotate_nginx:
  file.managed:
    - name: /etc/logrotate.d/nginx
    - contents: |
        /var/log/nginx/*.log {
            hourly
            rotate 10
            compress
            missingok
            notifempty
            create 0640 www-data adm
            sharedscripts
            postrotate
                [ -f /var/run/nginx.pid ] && kill -USR1 `cat /var/run/nginx.pid`
            endscript
        }
