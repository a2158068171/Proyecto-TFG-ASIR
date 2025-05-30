# Proyecto TFG ASIR - BBDD Distribuida con Réplica y Alta Disponibilidad (HA)

Este repositorio contiene la infraestructura completa para desplegar un sistema de base de datos PostgreSQL distribuida con réplica asincrónica, alta disponibilidad mediante HAProxy, y monitorización con Prometheus y Grafana

## 🧱 Arquitectura del Proyecto

- **3 contenedores PostgreSQL** (1 primario + 2 réplicas)
- **HAProxy** para balanceo de carga y failover
- **Prometheus + PostgreSQL Exporter + Grafana** para monitorización
- **Docker Compose** para orquestar todos los servicios

## 🚀 Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:

- **Docker Engine** (v24.0.0 o superior)
- **Docker Compose** (v2.20.0 o superior)
- **Sistema operativo compatible** (recomendado: Debian 12)

## 📁 Estructura del Proyecto

```
Proyecto-TFG-ASIR/
├── configs/
│   ├── haproxy/haproxy.cfg
│   └── prometheus/prometheus.yml
├── scripts/
│   ├── init-primary.sh
│   └── init-replica.sh
├── data/
│   ├── primary/
│   ├── replica1/
│   └── replica2/
└── docker-compose.yml

```
## 🔧 Pasos para Desplegar la Infraestructura

### 1. Clonar el repositorio

```bash
git clone https://github.com/a2158068171/Proyecto-TFG-ASIR.git
cd Proyecto-TFG-ASIR

```

### 2. Crear carpetas de persistencia para los datos

```bash
mkdir -p data/{primary,replica1,replica2}

```

> ⚠️ IMPORTANTE: Estas carpetas deben existir para que Docker asocie correctamente los volúmenes persistentes.

### 3. Dar permisos de ejecución a los scripts

```bash
chmod +x scripts/init-primary.sh scripts/init-replica.sh docker-compose.yml

```

> Añade aquí otros scripts si fuera necesario, por ejemplo: `chmod +x start.sh`

### 4. Levantar los contenedores

```bash
docker compose up -d

```

Verifica que todos los servicios estén corriendo:

```bash
docker ps

```

----------

## 🔎 Comprobación de Funcionamiento

### Acceder a PostgreSQL

-   **Lectura y escritura (HAProxy)**: `localhost:5435`
    
-   **Solo lectura (HAProxy)**: `localhost:5436`
    

Ejemplo de conexión desde terminal:

```bash
PGPASSWORD=sdfsdf psql -h localhost -p 5435 -U shen -d prueba

```

### Paneles de Monitorización

-   **Grafana**: [http://localhost:3000](http://localhost:3000/)
    
    -   Usuario: `admin`
        
    -   Contraseña: `admin`
        
-   **Prometheus**: [http://localhost:9090](http://localhost:9090/)
    
-   **HAProxy Stats**: [http://localhost:8404](http://localhost:8404/)
    
-   **PostgreSQL Exporter**: [http://localhost:9187/metrics](http://localhost:9187/metrics)
    

----------

## 📊 Dashboard Grafana Recomendado

Puedes importar el dashboard de PostgreSQL desde [Grafana Dashboards](https://grafana.com/grafana/dashboards/):

-   ID del dashboard: `9628`
----------

## 📚 Más Información

Consulta el documento PDF incluido para ver los detalles técnicos completos sobre la instalación desde cero, pruebas de replicación, failover y monitorización.

