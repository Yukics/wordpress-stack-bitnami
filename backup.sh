#!/bin/bash

# Reference: https://docs.bitnami.com/tutorials/backup-restore-data-containers/

PATH="/docker/some-wordpress"
WORDPRESS_SVC="wordpress"
MARIADB_SVC="mariadb"

RETENTION=7

function backup (){

        /bin/docker compose stop

        /bin/docker run --rm --volumes-from=$CONTAINER_WORDPRESS -v $PATH/backup:/tmp bitnami/minideb tar czf /tmp/$(echo $WORDPRESS_SVC)_data_backup-$(/bin/date +%Y-%m-%d).tar.gz -C /bitnami/wordpress .
        /bin/docker run --rm --volumes-from=$CONTAINER_MARIADB -v $PATH/backup:/tmp bitnami/minideb tar czf /tmp/$(echo $MARIADB_SVC)_data_backup-$(/bin/date +%Y-%m-%d).tar.gz -C /bitnami/mariadb .

        /bin/docker compose start

        /bin/find $PATH/backup -mtime +5 -delete -print
}

function restore (){

        DIAS=`/bin/ls $PATH/backup | /bin/tr '_' '\n' | /bin/grep backup | /bin/sed 's/backup-//g' | /bin/sed 's/.tar.gz//g' | /bin/sort | /bin/uniq`
        COUNT=0
        for DIA in $DIAS;do
                COUNT=$((COUNT + 1))
                echo "$COUNT ) $DIA"
        done
        read -p "Select [1 - $COUNT]: " SELECTION

        SELECTED_DAY=`echo $DIAS | /bin/tr ' ' '\n' |/bin/head -$SELECTION | /bin/tail -1`
        WORDPRESS_BACKUP=`/bin/ls $PATH/backup | /bin/grep $WORDPRESS_SVC | /bin/grep $SELECTED_DAY`
        MARIADB_BACKUP=`/bin/ls $PATH/backup | /bin/grep $MARIADB_SVC | /bin/grep $SELECTED_DAY`

        /bin/docker compose stop
 
        docker run --rm --volumes-from=$CONTAINER_WORDPRESS -v $PATH/backup:/tmp bitnami/minideb bash -c "rm -rf /bitnami/wordpress/* && tar xzf /tmp/$WORDPRESS_BACKUP -C /bitnami/wordpress"
        docker run --rm --volumes-from=$CONTAINER_MARIADB -v $PATH/backup:/tmp bitnami/minideb bash -c "rm -rf /bitnami/mariadb/* && tar xzf /tmp/$MARIADB_BACKUP -C /bitnami/mariadb"

        /bin/docker compose start
}


/bin/cd $PATH

CONTAINER_WORDPRESS=`/bin/docker compose ps $WORDPRESS_SVC | /bin/tail -1 | /bin/awk '{print $1}' | /bin/xargs -I % /bin/sh -c "/bin/docker ps -a | /bin/grep %" |  /bin/awk '{print $1}'`
CONTAINER_MARIADB=`/bin/docker compose ps $MARIADB_SVC | /bin/tail -1 | /bin/awk '{print $1}' | /bin/xargs -I % /bin/sh -c "/bin/docker ps -a | /bin/grep %" |  /bin/awk '{print $1}'`

if [[ "$1" == "restore" ]]; then

        read -p 'Estas seguro que quieres restaurar? [y/n]: ' SELECTION

        if [[ "$SELECTION" == "y" ]]; then
                echo "$(/bin/date +'%Y-%m-%d %H:%M:%S') [WARNING] Se ha inicia la restauración"
                restore
                echo "$(/bin/date +'%Y-%m-%d %H:%M:%S') [INFO] Ha finalizado la restauración"
        else
                echo "$(/bin/date +'%Y-%m-%d %H:%M:%S') [INFO] Se ha cancelado la restauración"
        fi
else
        echo "$(/bin/date +'%Y-%m-%d %H:%M:%S') [INFO] Se ha iniciado el backup"
        backup
        echo "$(/bin/date +'%Y-%m-%d %H:%M:%S') [INFO] Ha finalizado el backup"
fi
