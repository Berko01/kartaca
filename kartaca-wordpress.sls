{% set user = pillar.get('kartaca_user', {}) %}
{% set db_host_ip = pillar.get('db:host_ip', '3.75.97.136') %}
{% set db_host_name = pillar.get('db:host', 'kartaca1.local') %}

# Ortak kullanıcı ve sistem ayarları
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

# Farklı hostname ataması (çakışmayı önlemek için)
{% if grains['os'] == 'Ubuntu' %}
set_hostname:
  cmd.run:
    - name: hostnamectl set-hostname kartaca1.local
{% elif grains['os'] == 'Debian' %}
set_hostname:
  cmd.run:
    - name: hostnamectl set-hostname kartaca2.local
{% endif %}

ip_forwarding:
  sysctl.present:
    - name: net.ipv4.ip_forward
    - value: 1
    - config: /etc/sysctl.conf

# Her sistemin kendi /etc/hosts kaydı
{% if grains['os'] == 'Ubuntu' %}
self_hosts_entry:
  host.present:
    - ip: 127.0.1.1
    - names:
      - kartaca1.local
{% elif grains['os'] == 'Debian' %}
self_hosts_entry:
  host.present:
    - ip: 127.0.1.1
    - names:
      - kartaca2.local

# Debian’dan Ubuntu'ya bağlanmak için gerekli çözümleme
ubuntu_host_entry:
  host.present:
    - ip: {{ db_host_ip }}
    - names:
      - {{ db_host_name }}
{% endif %}

{% if grains['os'] == 'Ubuntu' %}

required_packages_ubuntu:
  pkg.installed:
    - pkgs:
      - htop
      - tcptraceroute
      - inetutils-ping
      - dnsutils
      - sysstat
      - mtr

docker_pkg_repo:
  pkgrepo.managed:
    - name: deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable
    - file: /etc/apt/sources.list.d/docker.list
    - key_url: https://download.docker.com/linux/ubuntu/gpg

docker_packages:
  pkg.installed:
    - pkgs:
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - docker-compose-plugin

docker_service:
  service.running:
    - name: docker
    - enable: True

wordpress_compose_file:
  file.managed:
    - name: /opt/wordpress/docker-compose.yml
    - source: salt://files/docker-compose.yml
    - makedirs: True

haproxy_cfg:
  file.managed:
    - name: /opt/wordpress/haproxy.cfg
    - source: salt://files/haproxy.cfg
    - require:
      - file: wordpress_compose_file

haproxy_cert:
  file.managed:
    - name: /opt/wordpress/ssl/selfsigned.pem
    - source: salt://files/ssl/selfsigned.pem
    - makedirs: True

wordpress_stack:
  cmd.run:
    - name: docker compose -f /opt/wordpress/docker-compose.yml up -d
    - cwd: /opt/wordpress
    - require:
      - service: docker_service
      - file: wordpress_compose_file
      - file: haproxy_cfg
      - file: haproxy_cert

{% elif grains['os'] == 'Debian' %}

required_packages_debian:
  pkg.installed:
    - pkgs:
      - htop
      - tcptraceroute
      - iputils-ping
      - dnsutils
      - sysstat
      - mtr

nginx_pkg:
  pkg.installed:
    - name: nginx

nginx_service:
  service.running:
    - name: nginx
    - enable: True
    - require:
      - pkg: nginx_pkg
      - file: nginx_conf

php_packages:
  pkg.installed:
    - pkgs:
      - php
      - php-fpm
      - php-mysql

wordpress_tarball:
  cmd.run:
    - name: wget https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz
    - unless: test -f /tmp/wordpress.tar.gz

extract_wordpress:
  cmd.run:
    - name: tar -xzf /tmp/wordpress.tar.gz -C /var/www/html --strip-components=1
    - unless: test -f /var/www/html/index.php
    - require:
      - cmd: wordpress_tarball

wp_config:
  file.managed:
    - name: /var/www/html/wp-config.php
    - source: salt://files/wp-config.php.jinja
    - template: jinja
    - require:
      - cmd: extract_wordpress

ssl_cert:
  file.managed:
    - name: /etc/ssl/certs/selfsigned.pem
    - source: salt://files/ssl/selfsigned.pem

nginx_conf:
  file.managed:
    - name: /etc/nginx/nginx.conf
    - source: salt://files/nginx.conf
    - require:
      - pkg: nginx_pkg
      - file: wp_config
    - watch_in:
      - service: nginx_service

logrotate_nginx:
  file.managed:
    - name: /etc/logrotate.d/nginx
    - source: salt://files/logrotate_nginx

cron_package:
  pkg.installed:
    - name: cron

nginx_cron:
  cron.present:
    - name: "/bin/systemctl restart nginx"
    - user: root
    - daymonth: 1
    - minute: 0
    - hour: 0
    - require:
      - pkg: cron_package

{% endif %}
