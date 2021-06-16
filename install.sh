#!/bin/bash

# empty the shell
clear

# Getting user input
read -p "Project name: " app
read -p "Domain name: " domain
read -p "MySQL root password: " -s sqlRoot
printf "\n"
read -p "Laravel MySQL username: " sqlUser
read -p "Laravel MySQL password: " -s sqlPass
printf "\n"
read -p "Environment (dev/prod): " env

# Updating the docker-compose file
sed  -i "s/container_name: /container_name: $app/g" docker-compose.yml
sed  -i 's/app-network/'"$app"'network/g' docker-compose.yml
sed  -i 's/dbdata/'"$app"'dbdata/g' docker-compose.yml
sed  -i "s/your_mysql_root_password/$sqlRoot/g" docker-compose.yml
sed  -i "s/MYSQL_USER:/MYSQL_USER: $sqlUser/g" docker-compose.yml
sed  -i "s/MYSQL_PASSWORD:/MYSQL_PASSWORD: $sqlPass/g" docker-compose.yml

# Making changes to .env file
cp $(pwd)/app/.env.example $(pwd)/app/.env
sed  -i "s/DB_USERNAME=root/DB_USERNAME=$sqlUser/g" $(pwd)/app/.env
sed  -i "s/DB_PASSWORD=/DB_PASSWORD=$sqlPass/g" $(pwd)/app/.env
sed  -i 's/DB_HOST=127.0.0.1/DB_HOST='"$app"'db/g' $(pwd)/app/.env

if [ $env == "prod" ]; then
    sed  -i 's/APP_ENV=local/APP_ENV=production/g' $(pwd)/app/.env
    sed  -i 's/APP_DEBUG=true/APP_DEBUG=false/g' $(pwd)/app/.env
fi

# Making changes to the nginx config
sed  -i "s/server_name localhost/server_name $domain/g" $(pwd)/nginx/conf.d/app.conf

# laravel setup
docker run --rm -v $(pwd)/app/:/app composer install
sudo chown -R $USER:$USER $(pwd)/app/
sudo chown -R $USER:$USER $(pwd)/nginx/ssl/

# Creating the certificate
docker run --rm -e PUBLIC_CN=$domain -v $(pwd)/nginx/ssl/:/etc/ssl/certs pgarrett/openssl-alpine

# Starting docker and finsihing laravel install
docker-compose up -d
docker-compose exec app php artisan key:generate
docker-compose exec app php artisan storage:link

if [ $env == "prod" ]; then
    docker-compose exec app php artisan config:cache
fi