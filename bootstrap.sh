#!/bin/bash

[[ "TRACE" ]] && set -x

: ${REALM:=CLOUD.COM}
: ${DOMAIN_REALM:=cloud.com}
: ${KERB_MASTER_KEY:=masterkey}
: ${KERB_ADMIN_USER:=root}
: ${KERB_ADMIN_PASS:=admin}
: ${KDC_ADDRESS:=kerberos.cloud.com}
: ${SEARCH_DOMAINS:=search.consul node.dc1.consul}

fix_nameserver() {
  cat>/etc/resolv.conf<<EOF
nameserver $NAMESERVER_IP
search $SEARCH_DOMAINS
EOF
}

fix_hostname() {
  sed -i "/^hosts:/ s/ *files dns/ dns files/" /etc/nsswitch.conf
}

create_config() {

  cat>/etc/krb5.conf<<EOF
[logging]
 default = FILE:/var/log/kerberos/krb5libs.log
 kdc = FILE:/var/log/kerberos/krb5kdc.log
 admin_server = FILE:/var/log/kerberos/kadmind.log

[libdefaults]
 default_realm = $REALM
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true

[realms]
 $REALM = {
  kdc = $KDC_ADDRESS
  admin_server = $KDC_ADDRESS
}

[domain_realm]
 .$DOMAIN_REALM = $REALM
 $DOMAIN_REALM = $REALM
EOF
}



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
   create_config
   service slapd start
   service apache2 start
   service nscd start
   service ssh restart
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
