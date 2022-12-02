#!/usr/bin/env bash

mv /opt/bitnami/apache2/htdocs/index.html /opt/bitnami/apache2/htdocs/bitnami.html
cat > /opt/bitnami/apache2/htdocs/index.html <<- EOM
<!doctype html>
<html lang="en">
  <head>
    <meta http-equiv="refresh" content="10">
  </head>
  <body>Deploying...</body>
</html>
EOM
echo "NO" > /opt/bitnami/apache2/htdocs/ready.html

apt-get remove apt-listchanges --assume-yes --force-yes

#using export is important since some of the commands in the script will fire in a subshell
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

#lib6c was an issue for me as it ignored the DEBIAN_FRONTEND environment variable and fired a prompt anyway. This should fix it
echo 'libc6 libraries/restart-without-asking boolean true' | debconf-set-selections

echo "executing wheezy to jessie"
find /etc/apt -name "*.list" | xargs sed -i '/^deb/s/wheezy/jessie/g'

echo "executing autoremove"
apt-get -fuy --force-yes autoremove

echo "executing clean"
apt-get --force-yes clean

echo "executing update"
apt-get update

echo "executing upgrade"
apt-get --force-yes -o Dpkg::Options::="--force-confold" --force-yes -o Dpkg::Options::="--force-confdef" -fuy upgrade

echo "executing dist-upgrade"
apt-get --force-yes -o Dpkg::Options::="--force-confold" --force-yes -o Dpkg::Options::="--force-confdef" -fuy dist-upgrade

echo "install packages"
apt-get install wget git -y

cat > /opt/bitnami/apache2/conf/bitnami/certs/server.pem <<- EOM
SERVER_PEM_STRING
EOM

cat > /opt/bitnami/apache2/conf/bitnami/certs/key.pem <<- EOM
KEY_PEM_STRING
EOM

chown bitnami:root /opt/bitnami/apache2/conf/bitnami/certs/*.pem
chmod 664 /opt/bitnami/apache2/conf/bitnami/certs/*.pem

sed -i 's/server.crt/server.pem/' /opt/bitnami/apache2/conf/bitnami/bitnami-ssl.conf
sed -i 's/server.key/key.pem/' /opt/bitnami/apache2/conf/bitnami/bitnami-ssl.conf

sed -i 's/DocumentRoot/Protocols h2 h2c http\/1.1\n  H2Direct on\n  Redirect permanent \/ https:\/\/justselfsigned.org\n  DocumentRoot/' /opt/bitnami/apache2/conf/bitnami/bitnami.conf
sed -i 's/DocumentRoot/Protocols h2 h2c http\/1.1\n  H2Direct on\n  DocumentRoot/' /opt/bitnami/apache2/conf/bitnami/bitnami-ssl.conf

sed -i 's/^#LoadModule http2_module modules\/mod_http2.so/LoadModule http2_module modules\/mod_http2.so/' /opt/bitnami/apache2/conf/httpd.conf

sed -i 's/<IfModule headers_module>/<IfModule headers_module>\n    Header always set Cross-Origin-Opener-Policy "same-origin"\n    Header always set Cross-Origin-Resource-Policy "same-origin"\n    Header always set Cross-Origin-Embedder-Policy "unsafe-none"\n    Header always set x-Frame-Options "DENY"\n    Header always set X-Content-Type-Options "nosniff"\n    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"\n    Header always set Content-Security-Policy "default-src \x27self\x27;"\n    Header always set Referrer-Policy "strict-origin-when-cross-origin"\n    Header always set Permissions-Policy "geolocation=(), microphone=(), camera=(), payment=(), xr-spatial-tracking=(), magnetometer=(), payment=(), sync-xhr=()"\n/' /opt/bitnami/apache2/conf/httpd.conf

printf '\nServerSignature Off\nServerTokens Prod\n' >> /opt/bitnami/apache2/conf/httpd.conf
sed -i 's/www.example.com/justselfsigned.org/' /opt/bitnami/apache2/conf/httpd.conf

/opt/bitnami/ctlscript.sh restart apache

cd /opt/bitnami
git clone https://github.com/OllieJC/justselfsigned.org.git
cd /opt/bitnami/justselfsigned.org/deploy/
/opt/bitnami/python/bin/python3 -m pip install -r requirements.txt
/opt/bitnami/python/bin/python3 1-generate-instance-files.py
rm /opt/bitnami/justselfsigned.org/website/*.tmpl

cp -r /opt/bitnami/justselfsigned.org/website/. /opt/bitnami/apache2/htdocs/
cp /opt/bitnami/apache2/conf/bitnami/certs/server.pem /opt/bitnami/apache2/htdocs/ssc.pem
cp /opt/bitnami/apache2/conf/bitnami/certs/server.pem /opt/bitnami/apache2/htdocs/sspc.pem

echo "YES" > /opt/bitnami/apache2/htdocs/ready.html
