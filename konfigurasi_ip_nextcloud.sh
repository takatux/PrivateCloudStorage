#!/bin/bash
#script ini digunakan untuk setting ip ketika melakukan ujicoba seminar atau sidang

echo "IPv4  Configuration"
echo "======================"
echo -n "IPv4 Address : "
read ipv4
echo -n "IPv4 Subnetmask (ex. 24) : "
read ipv4subnet

cat > ipsetup.txt << EOF
# This file is generated from information provided by
# the datasource.  Changes to it will not persist across an instance.
# To disable cloud-init's network configuration capabilities, write a file
# /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg with the following:
# network: {config: disabled}
network:
    ethernets:
        enp0s3:
            addresses: []
            dhcp4: true
            #optional: true
        enp0s8:
            addresses: [$ipv4/$ipv4subnet]
            dhcp4: false
            optional: true
    version: 2
EOF

cat ipsetup.txt > /etc/netplan/50-cloud-init.yaml
netplan apply

cat > virthostnextcloud << EOF
<VirtualHost *:80>
    ServerName $ipv4
    Alias /nextcloud "/var/www/html/nextcloud/"
    #ServerAdmin user@192.168.99.102
    DocumentRoot /var/www/html/nextcloud

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    <Directory /var/www/html/nextcloud/>
        Options +FollowSymlinks
        AllowOverride All

        <IfModule mod_dav.c>
            Dav off
        </IfModule>

        SetEnv HOME /var/www/html/nextcloud
        SetEnv HTTP_HOME /var/www/html/nextcloud
    </Directory>
</VirtualHost>
EOF

cat virthostnextcloud > /etc/apache2/sites-available/nextcloud.conf

cat > virthostdefault << EOF
<VirtualHost *:80>
        ServerName $ipv4

        #ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html


        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

</VirtualHost>
EOF

cat virthostdefault > /etc/apache2/sites-available/000-default.conf

cat > virthostssl << EOF
<IfModule mod_ssl.c>
        <VirtualHost *:443>
                ServerName $ipv4
                ServerAdmin webmaster@localhost
                DocumentRoot /var/www/html
                ErrorLog ${APACHE_LOG_DIR}/error.log
                CustomLog ${APACHE_LOG_DIR}/access.log combined
                SSLEngine on
                SSLCertificateFile      /etc/ssl/certs/ssl-cert-snakeoil.pem
                SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
                <FilesMatch "\.(cgi|shtml|phtml|php)$">
                                SSLOptions +StdEnvVars
                </FilesMatch>
                <Directory /usr/lib/cgi-bin>
                                SSLOptions +StdEnvVars
                </Directory>
                </VirtualHost>
</IfModule>
EOF

cat virthostssl > /etc/apache2/sites-available/default-ssl.conf

service apache2 restart
