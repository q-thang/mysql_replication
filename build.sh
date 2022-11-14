#!bin/bash

# Cleanup
# docker stop master slave
# docker rm master slave
# rm -rf master/data/*
# rm -rf slave/data/*
# docker network rm replicanet

docker-compose down -v 
rm -rf master/data/*
rm -rf slave/data/*
docker-compose build
docker-compose up -d

# Build
# docker network create replicanet

# docker run -d --name=master --net=replicanet --hostname=master -p 3307:3306 -v $PWD/master/data:/var/lib/mysql \
# -v $PWD/master/conf/mysql.conf.cnf:/etc/mysql/conf.d/mysql.conf.cnf -e MYSQL_ROOT_PASSWORD=123456 mysql/mysql-server:8.0 --server-id=1 --log-bin='mysql-bin-1.log' --binlog_format=ROW

# docker run -d --name=slave --net=replicanet --hostname=slave -p 3308:3306 -v $PWD/slave/data:/var/lib/mysql \
# -v $PWD/slave/conf/mysql.conf.cnf:/etc/mysql/conf.d/mysql.conf.cnf -e MYSQL_ROOT_PASSWORD=123456 mysql/mysql-server:8.0 --server-id=2

until docker exec -it master mysql -uroot -p123456 \
  -e "CREATE USER 'slave'@'%' IDENTIFIED BY '123456';" \
  -e "GRANT REPLICATION SLAVE ON *.* TO 'slave'@'%';" \
  -e "SHOW MASTER STATUS;"
do
    echo "Waiting for master database connection..."
    sleep 1
done

MS_STATUS=`docker exec master sh -c 'mysql -u root -p123456 -e "SHOW MASTER STATUS" -s'`
CURRENT_LOG=`echo $MS_STATUS | tail -n 1 | awk '{print $1}'`
CURRENT_POS=`echo $MS_STATUS | tail -n 1 | awk '{print $2}'`

until docker exec -it slave mysql -uroot -p123456 \
    -e "CHANGE MASTER TO MASTER_HOST='master', MASTER_USER='slave', \
      MASTER_PASSWORD='123456', MASTER_LOG_FILE='$CURRENT_LOG', MASTER_LOG_POS=$CURRENT_POS, GET_MASTER_PUBLIC_KEY=1;"
do
    echo "Waiting for slave database connection..."
    sleep 1
done

docker exec -it slave mysql -uroot -p123456 -e "START SLAVE;"

docker exec -it slave mysql -uroot -p123456 -e "SHOW SLAVE STATUS\G"

docker exec -it master mysql -uroot -p123456 -e "CREATE DATABASE replica;"

docker exec -it slave mysql -uroot -p123456 -e "SHOW DATABASES;"