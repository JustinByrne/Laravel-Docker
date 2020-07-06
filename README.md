# Laravel Development Docker

## System Requirements

- Docker
- Docker-Compose

## Installation Steps

### Script install

To install the system with an interactive script run

``` shell
bash ./install.sh
```

### Manual install

#### Laravel install

Move into the `app` directory

``` shell
cd ./app
```

Use Dockers composer image to install the laravel project

``` shell
docker run --rm -v $(pwd):/app composer install
```

Lastly change the user permissions of the laravel site

``` shell
sudo chown -R $USER:$USER ./
```

#### MySQL install

You will need to add your own password that laravel will use with MySQL. Open the `docker-compose.yml` file and change the following line for your chosen root password

``` yaml
MYSQL_ROOT_PASSWORD: your_mysql_root_password
```

If this is your first instance of laravel on docker ignore this step and move onto the next. Otherwise you will need to change the volume name for MySQL in the `docker-compose.yml` file. Find the lines below and change `dbdata` to anything else.

``` yaml
#MySQL Service
db:
  ...
    volumes:
      - dbdata:/var/lib/mysql
    networks:
      - app-network

...

#Volumes
volumes:
  dbdata:
    driver: local
```

#### Setting up Laravel

Laravel uses a `.env` file to manage settings this file will need to be created.

``` shell
cp ./app/.env.example ./app/.env
```

The `.env` file will then need to be changed to match the settings provided earlier. Find the `DB_CONNECTION` section and change the following to the password you would like for the `laraveluser` user

``` shell
DB_HOST=db
DB_PASSWORD=your_laravel_password
```

## Starting Laravel

With the majority of the system ready to go the docker container can now be started

``` shell
docker-compose up -d
```

This wil start the docker container in the background, the next thing to do is generate the key for laravel and add the settings to the cache. These can be done with the following commands

``` shell
docker-compose exec app php artisan key:generate
docker-compose exec app php artisan config:cache
```

With that done if you now navigate to `http://localhost/` this will open the new laravel instance

## Creating the MySQL User

Laravel is currently working however, it doesn't have the user specified earlier. This user will need to be created now. We need to open a bash shell in the MySQL container with the following.

``` shell
docker-compose exec db bash
```

With a bash shell open in the MySQL container you will be able to user a cli version of MySQL using the following

``` shell
mysql -u root -p
```

The password required will be the one you created in the `docker-compose.yml` file. Now connected you will be able to create the MySQL user with the following, changing the password to the one specified in the `./app/.env` file

``` mysql
GRANT ALL ON laravel.* TO 'laraveluser'@'%' IDENTIFIED BY 'your_laravel_db_password';
```

With that done you can flush the privileges with the following

``` mysql
FLUSH PRIVILEGES;
```

and then using the `exit` keyword quit both the mysql instance and the mysql container.
