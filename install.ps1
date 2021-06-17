# Clear the terminal
cls

# Configuration files
$compose = ".\docker-compose.yml"
$config = ".\nginx\conf.d\app.conf"
$envExampleFile = ".\app\.env.example"
$envFile = ".\app\.env"

# Getting user Input
$app = Read-Host "Project name"
$domain = Read-Host "FQDN"
$sqlRootEncr = Read-Host -AsSecureString "MySQL Root Password"
$sqlUser = Read-Host "Laravel MySQL Username"
$sqlPassEncr = Read-Host -AsSecureString "Laravel MySQL Password"
$env = Read-Host "Environment (dev/prod) [dev]"

# Converting the password strings
$sqlRootBstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sqlRootEncr)
$sqlRoot = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($sqlRootBstr)
$sqlPassBstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sqlPassEncr)
$sqlPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($sqlPassBstr)

if ([string]::IsNullOrWhiteSpace($env))
{
    $env = "dev"
}

# Updating the compose file with details above
$composeContent = Get-Content -Path $compose
$composeContent -replace 'container_name: ', "container_name: $($app)" `
    -replace 'app-network', "$($app)network" `
    -replace 'dbdata', "$($app)dbdata" `
    -replace 'your_mysql_root_password', "$($sqlRoot)" `
    -replace 'MYSQL_USER:', "MYSQL_USER: $($sqlUser)" `
    -replace 'MYSQL_PASSWORD:', "MYSQL_PASSWORD: $($sqlPass)" | Set-Content -Path $compose | Out-Null

# Updating nginx configuration
$configContent = Get-Content -Path $config
$configContent -replace 'server_name localhost', "server_name $($domain)" | Set-Content -Path $config | Out-Null

# Updating settings in the .env file
Copy-Item -Path $envExampleFile -Destination $envFile
$envContent = Get-Content -Path $envFile
$envContent -replace 'DB_USERNAME=root', "DB_USERNAME=$($sqlUser)" `
    -replace 'DB_PASSWORD=', "DB_PASSWORD=$($sqlPass)" `
    -replace 'DB_HOST=127.0.0.1', "DB_HOST=$($app)db" | Set-Content -Path $envFile | Out-Null

if ($env -eq "prod")
{
    $envContent -replace 'APP_ENV=local', 'APP_ENV=production' `
        -replace 'APP_DEBUG=true', 'APP_DEBUG=false'
}

# Installing with composer
docker run --rm -v $pwd/app/:/app composer install

# Creating a self-signed certificate
docker run --rm -e PUBLIC_CN="$($domain)" -v $pwd/nginx/ssl/:/etc/ssl/certs pgarrett/openssl-alpine

# Starting the stack and startup changes
docker-compose up -d
docker-compose exec app php artisan key:generate
docker-compose exec app php artisan storage:link

if ($env -eq "prod")
{
    docker-compose exec app php artisan config:cache
}