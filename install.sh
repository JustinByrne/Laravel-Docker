#!/bin/bash

# empty the shell
clear

# Project name
echo -n Project name: 
read app

sed  -i "s/container_name: /container_name: $app/g" docker-compose.yml
sed  -i 's/app-network/'"$app"'network/g' docker-compose.yml
sed  -i 's/dbdata/'"$app"'dbdata/g' docker-compose.yml


# MySQL root password
echo -n MySQL root password: 
read -s sqlRoot
echo

sed  -i "s/your_mysql_root_password/$sqlRoot/g" docker-compose.yml


# MySQL laraveluser & password
echo -n Laravel MySQL username: 
read sqlUser
echo -n Laravel MySQL password: 
read -s sqlPass
echo

sed  -i "s/MYSQL_USER:/MYSQL_USER: $sqlUser/g" docker-compose.yml
sed  -i "s/MYSQL_PASSWORD:/MYSQL_PASSWORD: $sqlPass/g" docker-compose.yml
cd ./app
cp .env.example .env
sed  -i "s/DB_USERNAME=root/DB_USERNAME=$sqlUser/g" .env
sed  -i "s/DB_PASSWORD=/DB_PASSWORD=$sqlPass/g" .env


# laravel setup
sed  -i 's/DB_HOST=127.0.0.1/DB_HOST='"$app"'db/g' .env
docker run --rm -v $(pwd):/app composer install
sudo chown -R $USER:$USER ./
cd ../
docker-compose up -d
docker-compose exec app php artisan key:generate
docker-compose exec app php artisan config:cache