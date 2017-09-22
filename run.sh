#!/bin/bash
docker run -it -d -p 8181:8181 --name ldap -h ldap --net cloud.com master.cloud.com:5000/ldap /bin/bash
