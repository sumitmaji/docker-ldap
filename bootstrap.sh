#!/bin/bash

[[ "TRACE" ]] && set -x

create_ldif() {
echo "dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcAccess
olcAccess: to * by dn="cn=admin,dc=cloud,dc=com" write" > /var/tmp/access.ldif

ldapmodify -c -Y EXTERNAL -H ldapi:/// -f /var/tmp/access.ldif

  sudo ldapadd -c -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/core.ldif
  sudo ldapadd -c -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/cosine.ldif
  sudo ldapadd -c -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/nis.ldif
  sudo ldapadd -c -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/inetorgperson.ldif
  echo "dn: cn=config
changetype: modify
replace: olcLogLevel
olcLogLevel: 256" > /var/tmp/loglevel.ldif
ldapmodify -Y EXTERNAL -H ldapi:/// -f /var/tmp/loglevel.ldif

echo "dn: ou=users,dc=cloud,dc=com
ou: users
objectClass: organizationalUnit
objectclass: top

dn: ou=groups,dc=cloud,dc=com
ou: groups
objectClass: organizationalUnit
objectclass: top" > /var/tmp/ou.ldif
ldapadd -x -D 'cn=admin,dc=cloud,dc=com' -w sumit -H ldapi:/// -f /var/tmp/ou.ldif

echo "dn: cn=admins,ou=groups,dc=cloud,dc=com
cn: admins
gidnumber: 500
objectclass: posixGroup
objectclass: top

dn: cn=users,ou=groups,dc=cloud,dc=com
cn: users
gidnumber: 501
objectclass: posixGroup
objectclass: top" > /var/tmp/groups.ldif
ldapadd -x -D 'cn=admin,dc=cloud,dc=com' -w sumit -H ldapi:/// -f /var/tmp/groups.ldif

echo "dn: cn=Sumit Maji,ou=users,dc=cloud,dc=com
cn: Sumit Maji
gidnumber: 500
givenname: Sumit
homedirectory: /home/users/smaji
loginshell: /bin/bash
objectclass: inetOrgPerson
objectclass: posixAccount
objectclass: top
sn: Maji
uid: smaji
uidnumber: 1000
userpassword: {MD5}ciX/ceiCGyT9crTI/albmg==" > /var/tmp/sumit.ldif
ldapadd -x -D 'cn=admin,dc=cloud,dc=com' -w sumit -H ldapi:/// -f /var/tmp/sumit.ldif
}

start_ldap() {
   service slapd start
   service apache2 start
   service nscd start
   create_ldif
}

main() {
  if [ ! -f /ldap_initialized ]; then
    start_ldap 
    touch /ldap_initialized
  else
    start_ldap
  fi

  while true; do sleep 1000; done
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
