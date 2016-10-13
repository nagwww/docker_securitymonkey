#!/bin/bash

email=$mail
host_name=$host

if [ "${email}" == "" ]; then
  echo "Email is not passed. Please set it as dockerrun -e
  mail=test@example.com - "
  email="nagwww@gmail.com"
fi

if [ "${host_name}" == "" ]; then
  echo "Host or EC2 name is not passed. Please set it as dockerrun -e host=test@ec2-XX-XXX-XXX-XXX.compute-1.amazonaws.com"
  host="ec2-XX-XXX-XXX-XXX.compute-1.amazonaws.com"
fi

sed -i "s/securityteam@example.com/$email/g" /usr/local/src/security_monkey/env-config/config-deploy.py
sed -i "s/securitymonkey@example.com/$email/g" /usr/local/src/security_monkey/env-config/config-deploy.py
sed -i "s/ec2-XX-XXX-XXX-XXX.compute-1.amazonaws.com/$host_name/g" /usr/local/src/security_monkey/env-config/config-deploy.py


# Installing dart
curl https://dl-ssl.google.com/linux/linux_signing_key.pub |  apt-key add -
cd ~
curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > dart_stable.list
mv dart_stable.list /etc/apt/sources.list.d/dart_stable.list
apt-get update
apt-get install -y dart
cd /usr/local/src/security_monkey/dart
/usr/lib/dart/bin/pub get
/usr/lib/dart/bin/pub build

# Copy the compiled Web UI to the appropriate destination
/bin/mkdir -p /usr/local/src/security_monkey/security_monkey/static/
/bin/cp -R /usr/local/src/security_monkey/dart/build/web/* /usr/local/src/security_monkey/security_monkey/static/

openssl genrsa -des3 -passout pass:yourpassword -out server.key 2048
openssl rsa -in server.key -out server.key.insecure -passin pass:yourpassword
mv server.key server.key.secure
mv server.key.insecure server.key

openssl req -new -key server.key -out server.csr -subj "/C=US/ST=CA/L=Los Gatos/O=Global Security/OU=IT OPS/CN=securitymonkey.com"
openssl x509 -req -days 365  -in server.csr -signkey server.key -out server.crt

cp server.crt /etc/ssl/certs
cp server.key /etc/ssl/private

mkdir -p /var/log/nginx/log
mkdir /var/log/security_monkey
chown www-data /var/log/security_monkey/*
chmod -R 755 /var/log/security_monkey/*
mkdir /var/www
chown www-data /var/www

touch /var/log/security_monkey/security_monkey.error.log
touch /var/log/security_monkey/security_monkey.access.log
touch /var/log/security_monkey/security_monkey-deploy.log
chown www-data /var/log/security_monkey/*
chmod 755 /var/log/security_monkey/*

touch /var/log/nginx/log/securitymonkey.access.log
touch /var/log/nginx/log/securitymonkey.error.log
ln -s /etc/nginx/sites-available/securitymonkey.conf /etc/nginx/sites-enabled/securitymonkey.conf
rm /etc/nginx/sites-enabled/default

cp /usr/local/src/security_monkey/supervisor/security_monkey.conf /etc/supervisor/conf.d/security_monkey.conf 

echo "Starting nginx"
service nginx restart

#su - postgres -c '/usr/lib/postgresql/9.3/bin/postgres -D "/var/lib/postgresql/9.3/main" -c "config_file=/etc/postgresql/9.3/main/postgresql.conf"'
#/etc/init.d/nginx start

echo "Starting postgres"
/etc/init.d/postgresql start


echo "Update the database"
chown -R ubuntu:ubuntu /home/ubuntu/
cd /usr/local/src/security_monkey/
python manage.py db upgrade

cd /usr/local/src/security_monkey/supervisor

service supervisor restart
supervisorctl &

echo "Completed ... "
/bin/bash

