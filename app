export APP_UID=2001
export APP_PASSWD=`pwgen -A1Bn 16`
export APP_NAME=darwin

useradd -u ${APP_UID} -m -s /usr/bin/zsh ${APP_NAME} && echo "${APP_NAME}:${APP_PASSWD}" | chpasswd

mkdir -m 700 /home/${APP_NAME}/.ssh
install -m 600 /tmp/setup/files/authorized_keys /home/${APP_NAME}/.ssh
chown -R ${APP_NAME}:${APP_NAME} /home/${APP_NAME}/.ssh

echo "*:*:*:${APP_NAME}:${APP_PASSWD}" | (umask 0077 && cat > /home/${APP_NAME}/.pgpass)
chown ${APP_NAME}:${APP_NAME} /home/${APP_NAME}/.pgpass
cat << EOF | psql -U postgres
CREATE USER ${APP_NAME} PASSWORD '${APP_PASSWD}';
CREATE DATABASE ${APP_NAME}_production; GRANT ALL PRIVILEGES ON DATABASE ${APP_NAME}_production TO ${APP_NAME};
CREATE DATABASE ${APP_NAME}_development; GRANT ALL PRIVILEGES ON DATABASE ${APP_NAME}_development TO ${APP_NAME};
CREATE DATABASE ${APP_NAME}_test; GRANT ALL PRIVILEGES ON DATABASE ${APP_NAME}_test TO ${APP_NAME};
EOF

mkdir /home/${APP_NAME}/tmp

erb /tmp/setup/files/app/unicorn.conf.erb > /home/${APP_NAME}/tmp/unicorn.conf
erb /tmp/setup/files/app/deploy.rb.erb > /home/${APP_NAME}/tmp/deploy.rb

mkdir -p /srv/${APP_NAME}/{tmp,shared/config}

erb /tmp/setup/files/app/database.yml.erb | (umask 0077 && cat > /srv/${APP_NAME}/shared/config/database.yml)

chown -R ${APP_NAME}:${APP_NAME} /{home,srv}/${APP_NAME}

systemctl enable unicorn@${APP_NAME}.service
echo "${APP_NAME} ALL= NOPASSWD: /usr/bin/systemctl reload unicorn@${APP_NAME}.service" | (umask 0227 && cat >> /etc/sudoers.d/55${APP_NAME})

systemctl enable resque_scheduler@${APP_NAME}.service
echo "${APP_NAME} ALL= NOPASSWD: /usr/bin/systemctl restart resque_scheduler@${APP_NAME}.service" | (umask 0227 && cat >> /etc/sudoers.d/55${APP_NAME})

systemctl enable resque_workers@${APP_NAME}.service
echo "${APP_NAME} ALL= NOPASSWD: /usr/bin/systemctl restart resque_workers@${APP_NAME}.service" | (umask 0227 && cat >> /etc/sudoers.d/55${APP_NAME})

erb /tmp/setup/files/app/nginx.conf.erb > /etc/nginx/sites.d/${APP_NAME}.conf

erb /tmp/setup/files/app/logrotate.conf.erb > /etc/logrotate.d/${APP_NAME}
