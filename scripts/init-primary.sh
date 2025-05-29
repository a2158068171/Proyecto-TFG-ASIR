#!/bin/bash

# hace que el script se detenga si algo falla y previene errores silenciosos
# todas las variables vienen del docker compose
set -e

# el psql -v ON_ERROR_STOP=1 hace que si falla el bloque que hay de sql falle el comando por seguridad
# dentro de la sentencia sql lo que hacemos es crear un role llamado replica con contraseña replica
# ademas de habilitar la extension de pg_stat_statements para monitorear las consultas sql
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  CREATE ROLE replica WITH REPLICATION PASSWORD 'replica' LOGIN;
  CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
EOSQL


# modica el postgresql.conf para permitir replicacion
#  cat >> abre el archivo para añadir y el <<EOF indica a shell 
# que vendra un bloque de texto que se añadira en el archivo 
cat >> "$PGDATA/postgresql.conf" <<EOF
# Configuración para replicación
listen_addresses = '*'
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
hot_standby = on
hot_standby_feedback = on
max_connections = 100
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.max = 10000
pg_stat_statements.track = all
EOF

# configuro acceso para replicación en pg_hba.conf
cat >> "$PGDATA/pg_hba.conf" <<EOF
# permito el acceso para replicaction, con el nombre de usuario postgreSQL replica
# en la ip esa y con autentiacion con contraseña
host replication replica 172.20.0.0/16 md5
# permito conectarme a todas las bbdd de esa ip con el usuario shen
host all shen 172.20.0.0/16 md5
EOF

# creo los slots para las replicas fisicas 
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOF
  SELECT pg_create_physical_replication_slot('replica1_slot');
  SELECT pg_create_physical_replication_slot('replica2_slot');
EOF

# creo las tablas de la bbdd 
# Creo la  tabla test_table en la base de datos
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOF
  CREATE TABLE IF NOT EXISTS test_table (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
  
  -- Inserta valores a la tabla si esta vacia
  -- Se pueden cambiar el nombre de los valores en el select
  INSERT INTO test_table (name)
  SELECT 'Test Record ' || i
  FROM generate_series(1, 3) AS i
  WHERE NOT EXISTS (SELECT 1 FROM test_table);
EOF

echo "configuracion del nodo primario completada. la tabla se ha creada en $POSTGRES_DB."
