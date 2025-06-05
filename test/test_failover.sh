#!/bin/bash

echo "=== PRUEBA DE FAILOVER AUTOMÁTICO ==="
echo

# Verificar estado inicial
echo "1. Estado inicial del sistema:"
PGPASSWORD=sdfsdf psql -h localhost -p 5435 -U shen -d prueba -c "SELECT 'Servidor actual: ' || inet_server_addr();"
echo

# Insertar un registro de prueba antes del fallo
echo "2. Insertando registro de prueba..."
PGPASSWORD=sdfsdf psql -h localhost -p 5435 -U shen -d prueba -c "INSERT INTO test_table (name) VALUES ('Pre-failover test $(date)');"

# Iniciar cronómetro y simular fallo
echo "3. Simulando fallo del nodo primario..."
echo "Hora de inicio: $(date '+%H:%M:%S')"
START=$(date +%s)

# Detener el primario
docker stop postgres-primary

# Esperar y medir cuándo vuelve el servicio
echo "4. Midiendo tiempo hasta recuperación del servicio..."
RECOVERED=0
SECONDS_ELAPSED=0

while [ $RECOVERED -eq 0 ] && [ $SECONDS_ELAPSED -lt 30 ]; do
    sleep 1
    SECONDS_ELAPSED=$((SECONDS_ELAPSED + 1))
    
    # Intentar conectarse
    if PGPASSWORD=sdfsdf psql -h localhost -p 5435 -U shen -d prueba -c "SELECT 1;" >/dev/null 2>&1; then
        RECOVERED=1
        echo "✅ Servicio recuperado en $SECONDS_ELAPSED segundos"
        echo
        echo "5. Nuevo servidor activo:"
        PGPASSWORD=sdfsdf psql -h localhost -p 5435 -U shen -d prueba -c "SELECT 'Servidor actual: ' || inet_server_addr();"
        echo
        echo "6. Verificando que se pueden leer los datos anteriores:"
        PGPASSWORD=sdfsdf psql -h localhost -p 5435 -U shen -d prueba -c "SELECT * FROM test_table WHERE name LIKE 'Pre-failover%' ORDER BY id DESC LIMIT 3;"
    else
        echo "   Intento $SECONDS_ELAPSED... servicio no disponible"
    fi
done

if [ $RECOVERED -eq 0 ]; then
    echo "❌ Servicio no se recuperó en 30 segundos"
else
    echo
    echo "=== RESULTADO DE FAILOVER ==="
    echo "✅ Failover completado en $SECONDS_ELAPSED segundos"
    if [ $SECONDS_ELAPSED -lt 5 ]; then
        echo "✅ Objetivo cumplido: Failover < 5 segundos"
    elif [ $SECONDS_ELAPSED -lt 10 ]; then
        echo "⚠️  Failover aceptable: < 10 segundos"
    else
        echo "⚠️  Failover superior al objetivo de 5 segundos"
    fi
fi

echo
echo "7. Restaurando nodo primario..."
docker start postgres-primary
sleep 15
echo "✅ Sistema restaurado completamente"
echo
echo "8. Verificando estado final:"
PGPASSWORD=sdfsdf psql -h localhost -p 5435 -U shen -d prueba -c "SELECT 'Servidor principal restaurado: ' || inet_server_addr();"
