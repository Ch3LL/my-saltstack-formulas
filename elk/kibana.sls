{% set kibana_pkg = "kibana-4.2.0-linux-x64.tar.gz" %}
{% set allowed_ip_kibana = salt['pillar.get']('kibana:allowedip', '') %}
{% set kibana_dir_exists = salt['cmd.run']('test -d /opt/kibana/ ]]') %}

add-kibana-group:
  group.present:
    - name: kibana
    - gid: 999

add-kibana-usr:
  user.present:
    - name: kibana
    - gid: 999
    - uid: 999

{% if not kibana_dir_exists %}
download-kibana:
  cmd.run:
    - name: wget https://download.elastic.co/kibana/kibana/{{ kibana_pkg }} -P /tmp/

extract_kibana_tar:
  archive.extracted:
    - name: /opt/kibana/
    - source: /tmp/{{ kibana_pkg }} 
    - tar_options: xvf --strip-components 1
    - archive_format: tar
    - require:
      - cmd: download-kibana

kibana_dir_perms:
  file.directory:
    - name: /opt/kibana/
    - user: kibana
    - recurse:
      - user

{% endif %}


allowed_ip_kibana:
  file.append:
    - name: /opt/kibana/config/kibana.yml
    - text: |
        server.host: {{ allowed_ip_kibana }}

download_kibana_init:
  file.managed:
    - name: /etc/init.d/kibana
    - source: https://gist.githubusercontent.com/thisismitch/8b15ac909aed214ad04a/raw/fc5025c3fc499ad8262aff34ba7fde8c87ead7c0/kibana-4.x-init
    - user: kibana 
    - mode: 755
    - source_hash: sha512=4a5ef272438e3e4db86f9ac1da0d3daadcd1463422a5344b97512fbf10d057f1f0a7b91616c2fa338538e6f523c51143ddf7c73020496cca2cad61b7d25a0cb3


download_kibana_default:
  file.managed:
    - name: /etc/default/kibana
    - source: https://gist.githubusercontent.com/thisismitch/8b15ac909aed214ad04a/raw/fc5025c3fc499ad8262aff34ba7fde8c87ead7c0/kibana-4.x-default
    - user: kibana
    - mode: 755
    - source_hash: sha512=5dfb0e888eade4bfd9e6a1ea6de0f442225b28fd90e36c8afad82bf9c0b895b43659c1a0c44ecefac5a2756a014ab9f0f0261a15ad6e8e9663e98536f3e9106e

start_kibana:
  service.running:
    - name: kibana
    - enable: True
    - reload: True
    - require:
      - file: download_kibana_default
      - file: download_kibana_init

