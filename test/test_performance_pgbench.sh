#!/bin/bash

echo "=== PRUEBAS DE RENDIMIENTO CON PGBENCH ==="
echo

# Verificar que pgbench está disponible
if ! command -v pgbench &> /dev/null; then
    echo "Instalando postgresql-contrib para pgbench..."
    sudo apt update && sudo apt install -y postgresql-contrib
fi

# Función para ejecutar pruebas de pgbench
function run_pgbench_test() {
    local port=$1
    local description="$2"
    local clients=${3:-20}
    local duration=${4:-30}
    
    echo "=== $description ==="
    echo "Puerto: $port | Clientes: $clients | Duración: ${duration}s"
    echo
    
    # Inicializar pgbench si es necesario (solo en el primario)
    if [ $port -eq 5435 ]; then
        echo "Inicializando pgbench en el puerto $port..."
        PGPASSWORD=sdfsdf pgbench -h localhost -p $port -U shen -d prueba -i -s 2 --quiet
        echo "✅ pgbench inicializado"
        echo
    fi
    
    echo "Ejecutando prueba de rendimiento..."
    echo "Comando: pgbench -h localhost -p $port -U shen -d prueba -c $clients -j 4 -T $duration"
    echo
    
    # Ejecutar pgbench
    PGPASSWORD=sdfsdf pgbench -h localhost -p $port -U shen -d prueba \
        -c $clients \
        -j 4 \
        -T $duration \
        --progress=10 \
        --report-per-command
    
    echo
    echo "---"
}

# Función para pruebas de solo lectura
function run_readonly_test() {
    local port=$1
    local description="$2"
    local clients=${3:-25}
    local duration=${4:-30}
    
    echo "=== $description (SOLO LECTURA) ==="
    echo "Puerto: $port | Clientes: $clients | Duración: ${duration}s"
    echo
    
    echo "Ejecutando prueba de solo lectura..."
    echo "Comando: pgbench -h localhost -p $port -U shen -d prueba -c $clients -j 4 -T $duration -S"
    echo
    
    # Ejecutar pgbench en modo solo lectura (-S)
    PGPASSWORD=sdfsdf pgbench -h localhost -p $port -U shen -d prueba \
        -c $clients \
        -j 4 \
        -T $duration \
        -S \
        --progress=10 \
        --report-per-command
    
    echo
    echo "---"
}

# Función para crear script personalizado de consultas
function create_custom_script() {
    cat > /tmp/custom_queries.sql << 'EOSQL'
\set userid random(1, 2000)
\set productid random(1, 1000)
SELECT u.nombre, u.ciudad FROM usuarios u WHERE u.id = :userid;
SELECT p.nombre, p.precio FROM productos p WHERE p.id = :productid;
SELECT COUNT(*) FROM pedidos WHERE usuario_id = :userid;
EOSQL
}

# Función para pruebas con consultas personalizadas
function run_custom_test() {
    local port=$1
    local description="$2"
    local clients=${3:-15}
    local duration=${4:-30}
    
    echo "=== $description (CONSULTAS PERSONALIZADAS) ==="
    echo "Puerto: $port | Clientes: $clients | Duración: ${duration}s"
    echo
    
    create_custom_script
    
    echo "Ejecutando prueba con consultas personalizadas..."
    echo "Consultas: SELECT de usuarios, productos y conteo de pedidos"
    echo
    
    # Ejecutar pgbench con script personalizado
    PGPASSWORD=sdfsdf pgbench -h localhost -p $port -U shen -d prueba \
        -c $clients \
        -j 4 \
        -T $duration \
        -f /tmp/custom_queries.sql \
        --progress=10 \
        --report-per-command
    
    rm -f /tmp/custom_queries.sql
    echo
    echo "---"
}

echo "Iniciando suite de pruebas de rendimiento..."
echo "Estas pruebas medirán transacciones por segundo (TPS) y latencia"
echo

# Prueba 1: Puerto principal con operaciones mixtas
run_pgbench_test 5435 "PUERTO PRINCIPAL (5435) - LECTURA/ESCRITURA" 20 30

# Prueba 2: Puerto de solo lectura con operaciones de lectura
run_readonly_test 5436 "PUERTO BALANCEADO (5436) - SOLO LECTURA" 25 30

# Prueba 3: Puerto principal solo lectura
run_readonly_test 5435 "PUERTO PRINCIPAL (5435) - SOLO LECTURA" 25 30

# Prueba 4: Consultas personalizadas en puerto balanceado
run_custom_test 5436 "PUERTO BALANCEADO (5436) - CONSULTAS REALES" 15 30

echo
echo "=== PRUEBAS DE RENDIMIENTO COMPLETADO ==="
