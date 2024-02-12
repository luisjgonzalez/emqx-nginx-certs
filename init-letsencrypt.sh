#!/bin/bash

export COMPOSE_FILE=production_nginx.yml

printf "Please type your domain name example mysiteweb.com ! \n"
while [[ -z $DOMAIN   ]]
  do 
    read -p "DOMAIN: " DOMAIN
    printf "   -> DOMAIN: $DOMAIN \n"
  done

printf "Please type your EMAIL \n"
while [[ -z $EMAIL  ]] 
  do
    read -p "EMAIL: " EMAIL
    printf "    -> EMAIL: $EMAIL \n"   
  done	

staging=0 # Set to 1 if you're testing your setup to avoid hitting request limits
read -p "Do you want to do tests ? [N/y] :  " TEST
if [ "$TEST" = "n" ]; then 
  staging=1
fi
printf "Test value : ${staging} \n"

printf "Creanting news virtualhost \n"
vh_path="$PWD/nginx/nginx"
domains=( $DOMAIN )

cp ${vh_path}/domain ${vh_path}/${DOMAIN}.conf
cp ${vh_path}/domain.websocket ${vh_path}/${DOMAIN}.websocket.conf
cp ${PWD}/nginx/modules-enabled/stream ${PWD}/nginx/modules-enabled/stream.conf
sed -i "s/DOMAIN/${DOMAIN}/g" ${vh_path}/${DOMAIN}.conf
sed -i "s/DOMAIN/$DOMAIN/g" ${vh_path}/${DOMAIN}.websocket.conf
sed -i "s/DOMAIN/$DOMAIN/g" ${PWD}/nginx/modules-enabled/stream.conf

printf "Virtual Host Created !!\n"

rsa_key_size=4096
#data_path="./data/certbot"
data_path="$(pwd)/nginx/certbot"
#email="email@mail.com"
email="${EMAIL}" # Adding a valid address is strongly recommended


if [ -d "$data_path" ]; then
  read -p "Existing data found for $domains. Continue and replace existing certificate? (y/N) " decision
  if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
    exit
  fi
fi


if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
  echo "### Downloading recommended TLS parameters ..."
  mkdir -p "$data_path/conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"
  echo
fi


echo "### Creating dummy certificate for $domains ..."
for domain in "${domains[@]}" ; do
  path="/etc/letsencrypt/live/$domain"
  mkdir -p "$data_path/conf/live/$domain"
  docker-compose run --rm --entrypoint "\
    openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1\
      -keyout '$path/privkey.pem' \
      -out '$path/fullchain.pem' \
      -subj '/CN=localhost'" certbot
done
echo

echo "### Starting nginx ..."
docker-compose up --force-recreate -d nginx
echo

echo "### Deleting dummy certificate for $domains ..."
for domain in "${domains[@]}"; do
  docker-compose run --rm --entrypoint "\
    rm -Rf /etc/letsencrypt/live/$domain && \
    rm -Rf /etc/letsencrypt/archive/$domain && \
    rm -Rf /etc/letsencrypt/renewal/$domain.conf" certbot
done
echo


echo "### Requesting Let's Encrypt certificate for ${domains[@]} ..."

echo

# Select appropriate email arg
case "$email" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $email" ;;
esac

# Enable staging mode if needed
if [ $staging != "0" ]; then staging_arg="--staging"; fi

for domain in "${domains[@]}"; do
  docker-compose run --rm --entrypoint "\
    certbot certonly --webroot -w /var/www/certbot \
      $staging_arg \
      $email_arg \
      -d $domain \
      --rsa-key-size $rsa_key_size \
      --agree-tos \
      --force-renewal" certbot
done
echo

echo "### Reloading nginx ..."
docker-compose exec nginx nginx -s reload
