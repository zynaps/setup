pacman -S zeromq libxslt

APP_NAME=darwin
APP_USER_HOME=`useradd -D | grep ^HOME= | cut -d = -f 2`/${APP_NAME}
APP_UID=2001
APP_PGPASS=`pwgen -A1B 16`
useradd -u ${APP_UID} -m -s /bin/zsh ${APP_NAME} && passwd ${APP_NAME}
echo "*:*:*:${APP_NAME}:${APP_PGPASS}" | (umask 0077 && cat > ${APP_USER_HOME}/.pgpass)
chown -R ${APP_NAME}:${APP_NAME} ${APP_USER_HOME}
cat << EOF | psql -U postgres
CREATE USER ${APP_NAME} PASSWORD '${APP_PGPASS}';
CREATE DATABASE ${APP_NAME}_production; GRANT ALL PRIVILEGES ON DATABASE ${APP_NAME}_production TO ${APP_NAME};
CREATE DATABASE ${APP_NAME}_development; GRANT ALL PRIVILEGES ON DATABASE ${APP_NAME}_development TO ${APP_NAME};
CREATE DATABASE ${APP_NAME}_test; GRANT ALL PRIVILEGES ON DATABASE ${APP_NAME}_test TO ${APP_NAME};
EOF
mkdir -p /srv/${APP_NAME}
chown -R ${APP_NAME}:${APP_NAME} /srv/${APP_NAME}
echo 'God.load "/srv/'${APP_NAME}'/config/*.god"' > /etc/god.d/${APP_NAME}.god
