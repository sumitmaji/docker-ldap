#!/bin/bash

cat <<EOF | debconf-set-selections
slapd slapd/internal/generated_adminpw password admin
slapd slapd/internal/adminpw password admin
slapd slapd/password2 password admin
slapd slapd/password1 password admin
slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION
slapd slapd/domain string cloud.com
slapd shared/organization string Example Inc
slapd slapd/backend string ${LDAP_BACKEND^^}
slapd slapd/purge_database boolean true
slapd slapd/move_old_database boolean true
slapd slapd/allow_ldap_v2 boolean false
slapd slapd/no_configuration boolean false
slapd slapd/dump_database select when needed
EOF

dpkg-reconfigure -f noninteractive slapd
