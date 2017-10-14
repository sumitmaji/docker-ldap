#!/bin/bash
docker run -it -d -p 8181:8181 --name ldap -h ldap --net cloud.com sumit/ldap /bin/bash
