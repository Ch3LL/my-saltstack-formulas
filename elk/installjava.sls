add-java-ppa:
  pkgrepo.managed:
    - ppa: webupd8team/java
    - refresh_db: true

install-debconf:
  pkg.installed:
    - name: debconf-utils

oracle-java-license:
  debconf.set:
    - name: oracle-java8-installer
    - data:
        'shared/accepted-oracle-license-v1-1': {'type': 'boolean', 'value': True}
    - require:
      - pkg: install-debconf

java-installer:
  pkg.installed:
    - name: oracle-java8-installer
    - require:
      - pkgrepo: add-java-ppa
      - debconf: oracle-java-license

