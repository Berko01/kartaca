{% set user = pillar.get('kartaca_user', {}) %}
{% if grains['os_family'] == 'Debian' %}

kartaca_group:
  group.present:
    - gid: {{ user.gid }}

kartaca_user:
  user.present:
    - name: {{ user.name }}
    - uid: {{ user.uid }}
    - gid: {{ user.gid }}
    - home: {{ user.home }}
    - shell: {{ user.shell }}
    - password: {{ user.password }}
    - createhome: True

sudoers_file:
  file.managed:
    - name: /etc/sudoers.d/kartaca
    - source: salt://files/sudoers_kartaca
    - mode: 440

timezone:
  timezone.system:
    - name: Europe/Istanbul

set_hostname:
  cmd.run:
    - name: hostnamectl set-hostname kartaca1.local

required_packages:
  pkg.installed:
    - pkgs:
      - htop
      - tcptraceroute
      - iputils-ping
      - dnsutils
      - sysstat
      - mtr

ip_forwarding:
  sysctl.present:
    - name: net.ipv4.ip_forward
    - value: 1
    - config: /etc/sysctl.conf

hosts_entry:
  file.blockreplace:
    - name: /etc/hosts
    - marker_start: "# START kartaca host"
    - marker_end: "# END kartaca host"
    - content: |
        127.0.0.1   localhost
        127.0.1.1   kartaca1.local
    - append_if_not_found: True

# NGINX kurulumu ve etkinleştirme
nginx_pkg:
  pkg.installed:
    - name: nginx

nginx_service:
  service.running:
    - name: nginx
    - enable: True
    - require:
      - pkg: nginx_pkg

# PHP ve modüller
php_packages:
  pkg.installed:
    - pkgs:
      - php
      - php-fpm
      - php-mysql

# WordPress'i indir
wordpress_tarball:
  cmd.run:
    - name: wget https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz
    - unless: test -f /tmp/wordpress.tar.gz

# WordPress'i çıkar
extract_wordpress:
  cmd.run:
    - name: tar -xzf /tmp/wordpress.tar.gz -C /var/www/html --strip-components=1
    - unless: test -f /var/www/html/index.php
    - require:
      - cmd: wordpress_tarball

# wp-config.php'yi oluştur
wp_config:
  file.managed:
    - name: /var/www/html/wp-config.php
    - source: salt://files/wp-config.php.jinja
    - template: jinja

# SSL oluşturulmuş sertifikayı kopyala
ssl_cert:
  file.managed:
    - name: /etc/ssl/certs/selfsigned.pem
    - source: salt://files/ssl/selfsigned.pem

# nginx.conf güncellemesi
nginx_conf:
  file.managed:
    - name: /etc/nginx/nginx.conf
    - source: salt://files/nginx.conf
    - require:
      - pkg: nginx_pkg
    - watch_in:
      - service: nginx_service

# logrotate yapılandırması
logrotate_nginx:
  file.managed:
    - name: /etc/logrotate.d/nginx
    - source: salt://files/logrotate.d/nginx

# cron job: Her ayın ilk günü nginx restart
nginx_cron:
  cron.present:
    - name: "/bin/systemctl restart nginx"
    - user: root
    - daymonth: 1
    - minute: 0
    - hour: 0

{% endif %}
