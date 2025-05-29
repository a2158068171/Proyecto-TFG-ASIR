#!/bin/bash

# hace que el script se detenga si algo falla y previene errores silenciosos
# todas las variables vienen del docker compose
set -e

# detiene PostgreSQL de forma segura y rapida
pg_ctl -D "$PGDATA" -m fast -w stop || true

# limpia todo los datos del directorio $PGdata 
rm -rf "$PGDATA"/*

# establezco la contraseña para el pg_basebackup
export PGPASSWORD="replica"

# clonamos los datos del nodo primary con el usuario replica y el slot de replicacion
# el -R genera un standby.signal para replicar y el -X stream replica los WAL
until pg_basebackup -h "$PRIMARY_HOST" -p "$PRIMARY_PORT" -U replica -X stream -S "${REPLICA_NAME}_slot" -D "$PGDATA" -R -v -P -w
do
  echo "Esperando que el nodo primario esté disponible... Reintentando en 5 segundos."
  sleep 5
done

# configuro la replica
cat > "$PGDATA/postgresql.conf" <<EOF
# Configuración general
listen_addresses = '*'
hot_standby = on
hot_standby_feedback = on
max_connections = 100
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.max = 10000
pg_stat_statements.track = all
# configuracion especifica de la replica que conecta al primary
primary_conninfo = 'host=$PRIMARY_HOST port=$PRIMARY_PORT user=replica password=replica application_name=$REPLICA_NAME'
primary_slot_name = '${REPLICA_NAME}_slot'
EOF

# crea un archivo standby.signal para indicar que es una replica
touch "$PGDATA/standby.signal"

# modifica  los permisos
chmod 700 "$PGDATA"

# Configuro pg_hba.conf para permitir conectarnos al PostgreSQL (socket unix, localhost, ipv6..)
cat > "$PGDATA/pg_hba.conf" <<EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
host    all             all             172.20.0.0/16           md5
host    replication     all             172.20.0.0/16           md5
EOF

echo "configuracion del nodo replica $REPLICA_NAME completada."
