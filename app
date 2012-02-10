pacman -S zeromq libxslt

APP_NAME=darwin
APP_USER_HOME=`useradd -D | grep ^HOME= | cut -d = -f 2`/${APP_NAME}
APP_PGPASS=`pwgen -A1B 16`
useradd -u 2001 -m ${APP_NAME}
mkdir -p -m 0700 ${APP_USER_HOME}/.ssh
ssh-keygen -q -t rsa -f ${APP_USER_HOME}/.ssh/id_rsa -N '' -C ${APP_NAME}
ssh-add -L | head -n 1 | (umask 0077 && cat > ${APP_USER_HOME}/.ssh/authorized_keys)
echo "*:*:*:${APP_NAME}:${APP_PGPASS}" | (umask 0077 && cat > ${APP_USER_HOME}/.pgpass)
chown -R ${APP_NAME}:${APP_NAME} ${APP_USER_HOME}
cat << EOF | psql -U postgres
CREATE USER ${APP_NAME} PASSWORD '${APP_PGPASS}';
GRANT ALL PRIVILEGES ON DATABASE ${APP_NAME}_production TO ${APP_NAME}; CREATE DATABASE ${APP_NAME}_production;
GRANT ALL PRIVILEGES ON DATABASE ${APP_NAME}_development TO ${APP_NAME}; CREATE DATABASE ${APP_NAME}_development;
GRANT ALL PRIVILEGES ON DATABASE ${APP_NAME}_test TO ${APP_NAME}; CREATE DATABASE ${APP_NAME}_test;
EOF
mkdir -p /srv/${APP_NAME}
chown -R ${APP_NAME}:${APP_NAME} /srv/${APP_USER}
