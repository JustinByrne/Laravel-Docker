# Clear the terminal
cls

# Configuration files
$compose = "docker-compose.yml"
$composeContent = Get-Content -Path $compose
$config = ".\nginx\conf.d\app.conf"
$configContent = Get-Content -Path $config
$envExample = ".\app\.env.example"
$env = ".\app\.env"
$envContent = Get-Content -Path $env

# Getting user Input
$app = Read-Host "Project name"
$domain = Read-Host "FQDN"
$sqlRoot = Read-Host "MySQL Root Password"
$sqlUser = Read-Host "Laravel MySQL Username"
$sqlPass = Read-Host "Laravel MySQL Password"

# Updating the compose file with details above
$composeContent -replace 'container_name: ', "container_name: $($app)" | Set-Content -Path $compose | Out-Null
$composeContent -replace 'app-network', "$($app)network" | Set-Content -Path $compose | Out-Null
$composeContent -replace 'dbdata', "$($app)dbdata" | Set-Content -Path $compose | Out-Null
$composeContent -replace 'your_mysql_root_password', "$($sqlRoot)" | Set-Content -Path $compose | Out-Null
$composeContent -replace 'MYSQL_USER:', "MYSQL_USER: $($sqlUser)" | Set-Content -Path $compose | Out-Null
$composeContent -replace 'MYSQL_PASSWORD:', "MYSQL_PASSWORD: $($sqlPass)" | Set-Content -Path $compose | Out-Null

# Updating nginx configuration
$configContent -replace 'server_name localhost', "server_name $($domain)" | Set-Content -Path $config | Out-Null

# Updating settings in the .env file
Copy-Item -Path $envExample -Destination $env
$envContent -replace 'DB_USERNAME=root', "DB_USERNAME=$($sqlUser)" | Set-Content -Path $env | Out-Null
$envContent -replace 'DB_PASSWORD=', "DB_PASSWORD=$($sqlPass)" | Set-Content -Path $env | Out-Null
$envContent -replace 'DB_HOST=127.0.0.1', "DB_HOST=$($app)db" | Set-Content -Path $env | Out-Null

# Installing with composer
docker run --rm -v $pwd/app/:/app composer install

# Creating a self-signed certificate
docker run --rm -e PUBLIC_CN="$($domain)" -v $pwd/nginx/ssl/:/etc/ssl/certs pgarrett/openssl-alpine

# Starting the stack and startup changes
docker-compose up -d
docker-compose exec app php artisan key:generate
docker-compose exec app php artisan config:cache