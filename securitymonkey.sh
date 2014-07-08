#!/bin/bash

email=$mail
host_name=$host

if [ "${email}" == "" ]; then
  echo "Email is not passed. Please set it as dockerrun -e mail=test@example.com"
  email="nagwww@gmail.com"
fi

if [ "${host_name}" == "" ]; then
  echo "Host or EC2 name is not passed. Please set it as dockerrun -e host=test@ec2-XX-XXX-XXX-XXX.compute-1.amazonaws.com"
  host="ec2-XX-XXX-XXX-XXX.compute-1.amazonaws.com"
fi

sed -i "s/securityteam@example.com/$email/g" /home/ubuntu/security_monkey/env-config/config-deploy.py
sed -i "s/securitymonkey@example.com/$email/g" /home/ubuntu/security_monkey/env-config/config-deploy.py
sed -i "s/ec2-XX-XXX-XXX-XXX.compute-1.amazonaws.com/$host_name/g" /home/ubuntu/security_monkey/env-config/config-deploy.py


openssl genrsa -des3 -passout pass:yourpassword -out server.key 2048
openssl rsa -in server.key -out server.key.insecure -passin pass:yourpassword
mv server.key server.key.secure
mv server.key.insecure server.key

openssl req -new -key server.key -out server.csr -subj "/C=US/ST=CA/L=Los Gatos/O=Global Security/OU=IT OPS/CN=securitymonkey.com"
openssl x509 -req -days 365  -in server.csr -signkey server.key -out server.crt

cp server.crt /etc/ssl/certs
cp server.key /etc/ssl/private

mkdir -p /var/log/nginx/log
touch /var/log/nginx/log/securitymonkey.access.log
touch /var/log/nginx/log/securitymonkey.error.log
ln -s /etc/nginx/sites-available/securitymonkey.conf /etc/nginx/sites-enabled/securitymonkey.conf
rm /etc/nginx/sites-enabled/default

echo "Starting nginx"
service nginx restart

#su - postgres -c '/usr/lib/postgresql/9.3/bin/postgres -D "/var/lib/postgresql/9.3/main" -c "config_file=/etc/postgresql/9.3/main/postgresql.conf"'
#/etc/init.d/nginx start

echo "Starting postgres"
/etc/init.d/postgresql start


echo "Update the database"
chown -R ubuntu:ubuntu /home/ubuntu/
cd /home/ubuntu/security_monkey/
python manage.py db upgrade

cd /home/ubuntu/security_monkey/supervisor

supervisord -c security_monkey.ini
supervisorctl -c security_monkey.ini

echo "Completed ... "
/bin/bash

