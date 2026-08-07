# Estructura de la Base de Datos

Este directorio contiene todos los scripts necesarios para construir y mantener la base de datos del proyecto en PostgreSQL, especialmente adaptado para Supabase.

## Organización de Archivos

Los scripts se han modularizado para facilitar su mantenimiento y ejecución ordenada. Deben ejecutarse en el siguiente orden numérico:

1.  **`01_extensions.sql`**: Instala las extensiones de PostgreSQL requeridas, como `pgcrypto`.
2.  **`02_types.sql`**: Define todos los tipos de datos `ENUM` personalizados para estandarizar valores en columnas específicas.
3.  **`03_functions.sql`**: Contiene todas las funciones de la base de datos, incluyendo helpers para auditoría, RLS y lógica de negocio.
4.  **`04_schema.sql`**: Define la estructura de todas las tablas de la base de datos (`CREATE TABLE`).
5.  **`05_triggers.sql`**: Crea los `triggers` que se adjuntan a las tablas para automatizar tareas como la actualización de fechas, auditorías y validaciones.
6.  **`06_indexes.sql`**: Define los índices para optimizar el rendimiento de las consultas más frecuentes.
7.  **`07_views.sql`**: Crea las vistas (`views`) que simplifican consultas complejas y proporcionan una capa de abstracción sobre las tablas base.
8.  **`08_policies.sql`**: Configura la seguridad a nivel de fila (Row-Level Security - RLS), habilitando RLS en las tablas y definiendo las políticas de acceso para los diferentes roles de usuario.
9.  **`09_seed.sql`**: Inserta los datos iniciales y catálogos necesarios para el funcionamiento básico del sistema (e.g., roles, tipos de actividad, permisos).

## Ejecución

Para inicializar la base de datos desde cero, ejecute los scripts en el orden numérico indicado desde el editor SQL de Supabase o utilizando un cliente de PostgreSQL como `psql`.

---
*Este archivo fue generado y organizado automáticamente.*
