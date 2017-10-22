#!/bin/bash
[[ "TRACE" ]] && set -x

: ${LDAP_PASSWORD:=sumit}
uid=$(< /var/userid)
gid=`ldapsearch -x -b "ou=groups,dc=cloud,dc=com" "cn=$2" -D "cn=admin,dc=cloud,dc=com" -w ${LDAP_PASSWORD} -H ldap://ldap.cloud.com -LLL gidNumber | grep 'gidNumber' | grep -Eo '[0-9]+'`

echo "dn: cn=$1,ou=users,dc=cloud,dc=com
cn: $1
gidnumber: $gid
givenname: Sumit
homedirectory: /home/users/$1
loginshell: /bin/bash
objectclass: inetOrgPerson
objectclass: posixAccount
objectclass: top
sn: $1
uid: $1
uidnumber: $uid
userpassword: $3" > /var/tmp/user.ldif
ldapadd -x -D 'cn=admin,dc=cloud,dc=com' -w ${LDAP_PASSWORD} -H ldapi:/// -f /var/tmp/user.ldif

if [ $? == 0 ]
then
  echo $(($uid + 1)) > /var/userid
else
 exit 1
fi
exit 0

