{% set user = pillar.get('kartaca_user', {}) %}
{% set db = pillar.get('db', {}) %}
{% set hostname = 'kartaca1.local' if grains['os'] == 'Ubuntu' else 'kartaca2.local' %}
{% set self_host = hostname %}
{% set ping_package = 'inetutils-ping' if grains['os'] == 'Ubuntu' else 'iputils-ping' %}
{% set base_packages = ['htop', 'tcptraceroute', ping_package, 'dnsutils', 'sysstat', 'mtr'] %}

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

set_hostname:
  cmd.run:
    - name: hostnamectl set-hostname {{ hostname }}
    - unless: "hostnamectl | grep 'Static hostname: {{ hostname }}'"

self_hosts_entry:
  host.present:
    - ip: 127.0.1.1
    - names:
      - {{ self_host }}
    - clean: True

ip_forwarding:
  sysctl.present:
    - name: net.ipv4.ip_forward
    - value: 1
    - config: /etc/sysctl.conf

ubuntu_host_entry:
  host.present:
    - ip: {{ db.host_ip }}
    - names:
      - {{ db.host }}
    - clean: True

required_packages:
  pkg.installed:
    - pkgs: {{ base_packages }}

{% if grains['os'] == 'Ubuntu' %}

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

nginx_pkg:
  pkg.installed:
    - name: nginx

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

nginx_service:
  service.running:
    - name: nginx
    - enable: True
    - require:
      - pkg: nginx_pkg
      - file: nginx_conf

logrotate_nginx:
  file.managed:
    - name: /etc/logrotate.d/nginx
    - source: salt://files/logrotate.d/nginx

cron_package:
  pkg.installed:
    - name: cron

enable_cron_service:
  service.running:
    - name: cron
    - enable: True
    - require:
      - pkg: cron_package

nginx_cron:
  cron.present:
    - name: "/bin/systemctl restart nginx"
    - user: root
    - minute: 0
    - hour: 0
    - daymonth: 1
    - require:
      - service: enable_cron_service

{% endif %}
