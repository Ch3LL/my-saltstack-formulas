{% set allowed_ip_elastic = salt['pillar.get']('elasticsearch:allowedip', '') %}

add-elasticsearch-repo-key:
  cmd.run:
    - name: wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | apt-key add -

add-elasticsearch-repo:
  pkgrepo.managed:
    - humanname: ElasticSearch 
    - name: deb http://packages.elastic.co/elasticsearch/2.x/debian stable main
    - file: /etc/apt/sources.list.d/elasticsearch.list
    - refresh_db: true

install-elasticsearch:
  pkg.installed:
    - name: elasticsearch
    - require: 
      - pkgrepo: add-elasticsearch-repo

allowed_ip_elasticsearch:
  file.append:
    - name: /etc/elasticsearch/elasticsearch.yml
    - text: |
        network_host: {{ allowed_ip_elastic }}

elasticsearch-service:
  service.running:
    - name: elasticsearch
    - enable: True
    - reload: True
    - watch:
      - file: allowed_ip_elasticsearch
