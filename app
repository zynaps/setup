pacman -S zeromq libxslt

APP_UID=2001
APP_NAME=darwin

useradd -u ${APP_UID} -m -s /bin/zsh ${APP_NAME} && passwd ${APP_NAME}

<% if postgres %>
APP_PGPASS=`pwgen -A1B 16`
echo "*:*:*:${APP_NAME}:${APP_PGPASS}" | (umask 0077 && cat > /home/${APP_NAME}/.pgpass)
chown ${APP_NAME}:${APP_NAME} /home/${APP_NAME}/.pgpass
cat << EOF | psql -U postgres
CREATE USER ${APP_NAME} PASSWORD '${APP_PGPASS}';
CREATE DATABASE ${APP_NAME}_production; GRANT ALL PRIVILEGES ON DATABASE ${APP_NAME}_production TO ${APP_NAME};
CREATE DATABASE ${APP_NAME}_development; GRANT ALL PRIVILEGES ON DATABASE ${APP_NAME}_development TO ${APP_NAME};
CREATE DATABASE ${APP_NAME}_test; GRANT ALL PRIVILEGES ON DATABASE ${APP_NAME}_test TO ${APP_NAME};
EOF
<% end %>

mkdir -p /srv/${APP_NAME} && chown -R ${APP_NAME}:${APP_NAME} /srv/${APP_NAME}

echo 'God.load "/srv/'${APP_NAME}'/config/*.god"' > /etc/god.d/${APP_NAME}.god
