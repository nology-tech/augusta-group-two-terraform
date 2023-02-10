Content-Type: multipart/mixed; boundary="//"
MIME-Version: 1.0

--//
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="cloud-config.txt"

#cloud-config
cloud_final_modules:
- [scripts-user, always]

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"

#!/bin/bash

echo ---------- Update the Snake Game server_name to this IP address --------------
sudo sed "s/IP_ADDRESS/$(curl -4 icanhazip.com)/" /home/ubuntu/env/snake/snake-proxy.conf > /etc/nginx/sites-available/snake.game

DB_IP="${db_ip}"

ex /var/www/snake.game/html/scripts/Game.js <<eof                                                                                                                                                 
6 insert
const URL = "http://${db_ip}:5550/api/scores"
.
xit
eof

echo ---------- Reload Nginx --------------
sudo systemctl reload nginx.service

--//--