#!/bin/bash

echo "=== POBLANDO BASE DE DATOS CON DATOS DE PRUEBA ==="
echo

# Función para ejecutar SQL en el primario
function run_sql() {
    docker exec -i postgres-primary psql -U shen -d prueba -c "$1"
}

echo "1. Creando tablas adicionales para pruebas..."

# Crear tablas de prueba
run_sql "
-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    edad INTEGER,
    ciudad VARCHAR(100),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT true
);

-- Tabla de productos
CREATE TABLE IF NOT EXISTS productos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    categoria VARCHAR(100),
    precio DECIMAL(10,2),
    stock INTEGER DEFAULT 0,
    descripcion TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de pedidos
CREATE TABLE IF NOT EXISTS pedidos (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER REFERENCES usuarios(id),
    producto_id INTEGER REFERENCES productos(id),
    cantidad INTEGER NOT NULL,
    precio_total DECIMAL(10,2),
    estado VARCHAR(50) DEFAULT 'pendiente',
    fecha_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de logs para pruebas de rendimiento
CREATE TABLE IF NOT EXISTS logs_sistema (
    id SERIAL PRIMARY KEY,
    nivel VARCHAR(20),
    mensaje TEXT,
    modulo VARCHAR(100),
    timestamp_log TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    datos_extra JSONB
);
"

echo "✅ Tablas creadas"

echo "2. Insertando datos de usuarios..."

# Insertar usuarios de prueba
run_sql "
INSERT INTO usuarios (nombre, email, edad, ciudad) VALUES
('Juan Pérez', 'juan.perez@email.com', 28, 'Madrid'),
('María García', 'maria.garcia@email.com', 34, 'Barcelona'),
('Carlos López', 'carlos.lopez@email.com', 25, 'Valencia'),
('Ana Martín', 'ana.martin@email.com', 31, 'Sevilla'),
('Luis Rodríguez', 'luis.rodriguez@email.com', 29, 'Bilbao'),
('Carmen Fernández', 'carmen.fernandez@email.com', 27, 'Málaga'),
('José González', 'jose.gonzalez@email.com', 35, 'Zaragoza'),
('Isabel Ruiz', 'isabel.ruiz@email.com', 26, 'Murcia'),
('Miguel Díaz', 'miguel.diaz@email.com', 32, 'Palma'),
('Laura Moreno', 'laura.moreno@email.com', 30, 'Las Palmas')
ON CONFLICT (email) DO NOTHING;

-- Insertar más usuarios con datos generados
INSERT INTO usuarios (nombre, email, edad, ciudad)
SELECT 
    'Usuario_' || i,
    'usuario' || i || '@test.com',
    20 + (i % 40),
    CASE (i % 5)
        WHEN 0 THEN 'Madrid'
        WHEN 1 THEN 'Barcelona'
        WHEN 2 THEN 'Valencia'
        WHEN 3 THEN 'Sevilla'
        ELSE 'Bilbao'
    END
FROM generate_series(1, 2000) AS i
ON CONFLICT (email) DO NOTHING;
"

echo "✅ Usuarios insertados"

echo "3. Insertando datos de productos..."

# Insertar productos de prueba
run_sql "
INSERT INTO productos (nombre, categoria, precio, stock, descripcion) VALUES
('Laptop Gaming', 'Electrónicos', 1299.99, 15, 'Laptop gaming de alta gama con RTX 4060'),
('Smartphone Pro', 'Electrónicos', 899.99, 25, 'Smartphone con cámara de 108MP'),
('Auriculares Bluetooth', 'Electrónicos', 199.99, 50, 'Auriculares inalámbricos con cancelación de ruido'),
('Monitor 4K', 'Electrónicos', 449.99, 12, 'Monitor 27 pulgadas 4K HDR'),
('Teclado Mecánico', 'Accesorios', 129.99, 30, 'Teclado mecánico RGB para gaming'),
('Ratón Gaming', 'Accesorios', 79.99, 40, 'Ratón gaming con sensor óptico 16000 DPI'),
('Webcam HD', 'Electrónicos', 89.99, 20, 'Webcam 1080p con micrófono incorporado'),
('Disco SSD 1TB', 'Almacenamiento', 149.99, 35, 'Disco SSD NVMe de 1TB'),
('Memoria RAM 16GB', 'Componentes', 129.99, 25, 'Kit memoria RAM DDR4 16GB 3200MHz'),
('Fuente 650W', 'Componentes', 99.99, 18, 'Fuente de alimentación modular 650W 80+ Gold');

-- Insertar más productos generados
INSERT INTO productos (nombre, categoria, precio, stock, descripcion)
SELECT 
    'Producto_' || i,
    CASE (i % 4)
        WHEN 0 THEN 'Electrónicos'
        WHEN 1 THEN 'Accesorios'
        WHEN 2 THEN 'Componentes'
        ELSE 'Software'
    END,
    ROUND(CAST(random() * 1000 + 50 AS NUMERIC), 2),
    (random() * 100)::INTEGER,
    'Descripción del producto ' || i
FROM generate_series(1, 1000) AS i;
"

echo "✅ Productos insertados"

echo "4. Generando pedidos de prueba..."

# Insertar pedidos de prueba
run_sql "
INSERT INTO pedidos (usuario_id, producto_id, cantidad, precio_total, estado)
SELECT 
    (random() * 2000 + 1)::INTEGER,
    (random() * 1000 + 1)::INTEGER,
    (random() * 5 + 1)::INTEGER,
    ROUND(CAST(random() * 500 + 20 AS NUMERIC), 2),
    CASE (random() * 4)::INTEGER
        WHEN 0 THEN 'pendiente'
        WHEN 1 THEN 'procesando'
        WHEN 2 THEN 'enviado'
        ELSE 'entregado'
    END
FROM generate_series(1, 5000);
"

echo "✅ Pedidos generados"

echo "5. Generando logs del sistema..."

# Insertar logs de prueba
run_sql "
INSERT INTO logs_sistema (nivel, mensaje, modulo, datos_extra)
SELECT 
    CASE (random() * 4)::INTEGER
        WHEN 0 THEN 'INFO'
        WHEN 1 THEN 'WARNING'
        WHEN 2 THEN 'ERROR'
        ELSE 'DEBUG'
    END,
    'Mensaje de log número ' || i,
    CASE (random() * 5)::INTEGER
        WHEN 0 THEN 'auth'
        WHEN 1 THEN 'database'
        WHEN 2 THEN 'api'
        WHEN 3 THEN 'cache'
        ELSE 'frontend'
    END,
    json_build_object(
        'request_id', 'req_' || i,
        'user_agent', 'Mozilla/5.0',
        'ip', '192.168.1.' || (random() * 255)::INTEGER
    )
FROM generate_series(1, 10000);
"

echo "✅ Logs generados"

echo "6. Creando índices para mejorar rendimiento..."

# Crear índices
run_sql "
CREATE INDEX IF NOT EXISTS idx_usuarios_ciudad ON usuarios(ciudad);
CREATE INDEX IF NOT EXISTS idx_usuarios_activo ON usuarios(activo);
CREATE INDEX IF NOT EXISTS idx_productos_categoria ON productos(categoria);
CREATE INDEX IF NOT EXISTS idx_productos_precio ON productos(precio);
CREATE INDEX IF NOT EXISTS idx_pedidos_usuario ON pedidos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_pedidos_estado ON pedidos(estado);
CREATE INDEX IF NOT EXISTS idx_logs_nivel ON logs_sistema(nivel);
CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON logs_sistema(timestamp_log);
"

echo "✅ Índices creados"

echo "7. Verificando datos insertados..."

# Mostrar resumen de datos
run_sql "
SELECT 'usuarios' as tabla, count(*) as registros FROM usuarios
UNION ALL
SELECT 'productos' as tabla, count(*) as registros FROM productos
UNION ALL
SELECT 'pedidos' as tabla, count(*) as registros FROM pedidos
UNION ALL
SELECT 'logs_sistema' as tabla, count(*) as registros FROM logs_sistema
UNION ALL
SELECT 'test_table' as tabla, count(*) as registros FROM test_table
ORDER BY tabla;
"

echo
echo "=== DATOS DE PRUEBA INSERTADOS CORRECTAMENTE ==="
echo "✅ Base de datos poblada con ~18,000 registros"
echo "✅ Datos replicados automáticamente a las réplicas"
echo
echo "Resumen de datos:"
echo "- usuarios: 2,000+ registros"
echo "- productos: 1,000+ registros"
echo "- pedidos: 5,000+ registros"
echo "- logs_sistema: 10,000+ registros"
echo "- test_table: tabla original"
