FROM sumit/base
MAINTAINER Sumit Kumar Maji

RUN apt-get update
#ARG DEBIAN_FRONTEND=noninteractive
#RUN apt-get install -yq apt debconf
#RUN apt-get upgrade -yq
#RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes --no-install-recommends \
#	slapd ldap-utils

RUN apt-get update
RUN apt-get install -yq slapd ldap-utils
RUN apt-get install -yq phpldapadmin
#RUN dpkg-reconfigure slapd
# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
RUN sed -i "s/^exit 101$/exit 0/" /usr/sbin/policy-rc.d
ADD setup.sh /etc/setup.sh
ADD slapdsetup.sh /etc/slapdsetup.sh
RUN /bin/bash -c "/etc/slapdsetup.sh"
RUN /bin/bash -c "/etc/setup.sh" 
RUN service apache2 restart

RUN apt-get install -yq ldap-auth-client nscd
RUN auth-client-config -t nss -p lac_ldap
ADD setupClient.sh /etc/setupClient.sh
RUN /bin/bash -c "/etc/setupClient.sh"
ADD ldap.conf /etc/ldap.conf
ADD ldap.secret /etc/ldap.secret
#RUN /bin/bash -c "/etc/setupClient.sh"
