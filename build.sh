#!bin/bash

echo "Stopping containers..."
docker-compose down -v
rm -rf ./master/data/*
rm -rf ./slave/data/*
docker-compose build
docker-compose up -d
echo "Restart successfully..."

echo "Start creating replication..."

priv_cmd='CREATE USER "slave"@"%" IDENTIFIED BY "It235711"; GRANT REPLICATION SLAVE ON *.* TO "slave"@"%"; FLUSH PRIVILEGES;'
docker exec mysql_master mysql -u root -pIt235711 -e "$priv_cmd"

MS_STATUS=`docker exec mysql_master mysql -u root -pIt235711 -e 'SHOW MASTER STATUS \G;'`
CURRENT_LOG=`echo $MS_STATUS | awk '{print $6}'`
CURRENT_POS=`echo $MS_STATUS | awk '{print $7}'`

# start_slave_cmd="CHANGE MASTER TO MASTER_HOST="mysql_master", MASTER_USER="root", MASTER_PASSWORD="It235711", MASTER_LOG_FILE='$CURRENT_LOG'
# ,MASTER_LOG_POS=$CURRENT_POS; START SLAVE;"
# docker exec mysql_slave mysql -u root -pIt235711 -e $start_slave_cmd

# docker exec mysql_slave mysql -u root -pIt235711 -e 'SHOW SLAVE STATUS \G'

echo "Done!"