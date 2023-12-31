# Set up

Lets suppose we are running our wordpres compose on: `/docker/some-wordpress`

```bash
git clone https://github.com/Yukics/wordpress-stack-bitnami.git /docker/some-wordpress
```

Bitnami containers run as 1001 user, so:

```bash
chown -R 1001.root /docker/some-wordpress/wordpress
chown -R 1001.root /docker/some-wordpress/mariadb
```

In production environments, make backups (wordpress and DB stops, so make sure you are caching your content. Or the service will be interrupted). 
Those will be available on `/docker/some-wordpress/backup`. Feel free to edit the `backup.sh` script with the correct path and retention policy on days:

```bash
su - # as root
crontab -e # append the following line
0 0 * * * /docker/some-wordpress/backup.sh >> /var/log/wordpress-backup.log 2>&1
```