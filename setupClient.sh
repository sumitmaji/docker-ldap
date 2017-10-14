#!/bin/bash

STATUS=`grep "ldap compat" /etc/nsswitch.conf`
if [ -z "$STATUS" ]
then
`sed -i 's/compat/ldap compat/' /etc/nsswitch.conf`
fi


STATUS=`grep "umask=0022 skel=/etc/skel" /etc/pam.d/common-session`

if [ -z "$STATUS" ]
then
`sed -i '/pam_ldap.so/ s/^/session required        pam_mkhomedir.so umask=0022 skel=\/etc\/skel\n/' /etc/pam.d/common-session`
`sed -i '/session.*required.*pam_permit.so/ s/$/\n# Enable if using Kerberos:\n#session  optional  pam_krb5.so minimum_uid=1000\n/' /etc/pam.d/common-session`
`sed -i '/pam_ldap.so/ s/^/\n# Disable if using Kerberos:\n/' /etc/pam.d/common-session`
fi

STATUS=`grep "Enable if using Kerberos" /etc/pam.d/common-account`
if [ -z "$STATUS" ]
then
`sed -i '/pam_unix.so/ s/^/\n# Disable if using Kerberos\n/' /etc/pam.d/common-account`
`sed -i '/pam_ldap.so/ s/$/\n#Enable if using Kerberos:\n#account \[success=1 new_authtok_reqd=done default=ignore\]        pam_unix.so\n/' /etc/pam.d/common-account`
echo "# Enable if using Kerberos:
#account required                        pam_krb5.so minimum_uid=1000" >> /etc/pam.d/common-account
fi


STATUS=`grep "Enable if using Kerberos" /etc/pam.d/common-auth`
if [ -z "$STATUS" ]
then
`sed -i '/pam_unix.so/ s/^/\n# Disable if using Kerberos\n/' /etc/pam.d/common-auth`
`sed -i '/use_first_pass/ s/$/\n# Enable if using Kerberos\n#auth    \[success=2 default=ignore\]      pam_krb5.so minimum_uid=1000\n#auth    \[success=1 default=ignore\]      pam_unix.so nullok_secure try_first_pass\n/' /etc/pam.d/common-auth`
echo "account required    pam_access.so" >> /etc/pam.d/common-auth
fi

STATUS=`grep "Enable if using Kerberos" /etc/pam.d/common-password`
if [ -z "$STATUS" ]
then
`sed -i '/pam_unix.so/ s/^/\n# Disable if using Kerberos\n/' /etc/pam.d/common-password`
`sed -i '/try_first_pass/ s/$/\n# Enable if using Kerberos\n#password        \[success=2 default=ignore\]      pam_krb5.so minimum_uid=1000\n#password        \[success=1 default=ignore\]      pam_unix.so obscure use_authtok try_first_pass sha512\n/' /etc/pam.d/common-password`
fi





service nscd restart

STATUS=`grep "%admins ALL=(ALL) ALL" /etc/sudoers`
if [ -z "$STATUS" ]
then
`sed -i '/%admin ALL=(ALL) ALL/a\%admins ALL=(ALL) ALL' /etc/sudoers`
fi

