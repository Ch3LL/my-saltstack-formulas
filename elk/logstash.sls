{% set ssl_dirs = ['/etc/pki/tls/certs/', '/etc/pki/tls/private/'] %} 
{% set logstash_key = '/etc/pki/tls/private/logstash-forwarder.key' %}
{% set logstash_crt = '/etc/pki/tls/certs/logstash-forwarder.crt' %}
{% set public_ip_logstash = salt['pillar.get']('logstash:public_ip','') %}
{#{% set check_key_exists = salt['cmd.run']('[ -f /etc/pki/tls/private/logstash-forwarder.key ]') %}#}

add-logstash-repo:
  pkgrepo.managed:
    - humanname: Logstash
    - name: deb http://packages.elasticsearch.org/logstash/2.0/debian stable main
    - file: /etc/apt/sources.list.d/logstash.list
    - require:
      - pkgrepo: add-elasticsearch-repo
    - refresh_db: true

install_logstash:
  pkg.installed:
    - name: logstash

{% for dirs in ssl_dirs %}
{{ dirs }}-dir:
  file.directory:
    - name: {{ dirs }}
    - makedirs: True
{% endfor %}

add_ip_logstash_ssl:
  file.append:
    - name: /etc/ssl/openssl.cnf
    - text: |
        subjectAltName = IP: {{ public_ip_logstash }}

create_logstash_cert:
  cmd.run:
    - name: openssl req -config /etc/ssl/openssl.cnf -x509 -days 3650 -batch -nodes -newkey rsa:2048 -keyout {{ logstash_key }} -out {{ logstash_crt }}
    - unless: test -s {{ logstash_crt }}
    - require: 
      - file: add_ip_logstash_ssl

{# Now we will configure Logstash #}
input_logstash_config:
  file.managed:
    - name: /etc/logstash/conf.d/01-lumberjack-input.conf
    - source: salt://elk/files/etc/logstash/conf.d/01-lumberjack-input.conf

filter_logstash_config:
  file.managed:
    - name: /etc/logstash/conf.d/10-syslog.conf
    - source: salt://elk/files/etc/logstash/conf.d/10-syslog.conf

output_logstash_config:
  file.managed:
    - name: /etc/logstash/conf.d/30-lumberjack-output.conf
    - source: salt://elk/files/etc/logstash/conf.d/30-lumberjack-output.conf

logstash_service:
  service.running:
    - name: logstash
    - enable: True
    - require:
      - pkg: install_logstash
    - watch:
      - file: input_logstash_config
      - file: filter_logstash_config
      - file: output_logstash_config


      
