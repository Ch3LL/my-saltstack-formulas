{% set htpasswd = salt['pillar.get']('nginx:htpasswd', '') %}
{% set kibana_nginx_admin = salt['pillar.get']('nginx:kibana_admin', '') %}
{% set nginx_key = '/etc/nginx/ssl/nginx.key' %}
{% set nginx_crt = '/etc/nginx/ssl/nginx.crt' %}

install_nginx:
  pkg.installed:
    - pkgs:
      - nginx
      - apache2-utils

add_htpasswd_user:
  webutil.user_exists:
    - name: {{ kibana_nginx_admin }}
    - password: {{ htpasswd }} 
    - htpasswd_file: /etc/nginx/htpasswd.users
    - runas: root
    - require:
      - pkg: install_nginx

{# Configure Nginx SSL #}
create_nginx_ssl_dir:
  file.directory:
    - name: /etc/nginx/ssl
    - makedirs: true

create_nginx_certs:
  cmd.run:
    - name: openssl req -x509 -nodes -batch -days 365 -newkey rsa:2048 -keyout {{ nginx_key }} -out {{ nginx_crt }}
    - unless: test -s {{ nginx_crt }}

sites_available_default:
  file.managed:
    - name: /etc/nginx/sites-available/default
    - source: salt://elk/files/etc/nginx/sites-available/default
    - template: jinja
    - require:
      - pkg: install_nginx

nginx_service:
  service.running:
    - name: nginx
    - enable: True
    - reload: True
    - watch:
      - file: sites_available_default


