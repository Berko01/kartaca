{% set user = pillar.get('kartaca_user', {}) %}

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
      - inetutils-ping
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

# Docker Kurulumu
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

# docker-compose.yml kurulumu
wordpress_compose_file:
  file.managed:
    - name: /opt/wordpress/docker-compose.yml
    - source: salt://files/docker-compose.yml
    - makedirs: True

# WordPress container'larını çalıştır
wordpress_stack:
  cmd.run:
    - name: docker compose -f /opt/wordpress/docker-compose.yml up -d
    - cwd: /opt/wordpress
    - require:
      - file: wordpress_compose_file
      - service: docker_service

# HAProxy kurulumu
haproxy_cfg:
  file.managed:
    - name: /opt/haproxy/haproxy.cfg
    - source: salt://files/haproxy.cfg
    - makedirs: True

haproxy_container:
  cmd.run:
    - name: >
        docker run -d --name haproxy --restart always
        -p 443:443 -v /opt/haproxy/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
        haproxy:latest
    - unless: docker ps --format '{% raw %}{{.Names}}{% endraw %}' | grep haproxy
    - require:
      - file: haproxy_cfg
      - service: docker_service

