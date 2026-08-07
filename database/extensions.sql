-- =================================================================
--
-- Archivo: 01_extensions.sql
-- Descripción: Instala las extensiones de PostgreSQL necesarias
--              para el funcionamiento de la base de datos.
--              Se ejecuta primero para asegurar que todas las
--              funciones y tipos de datos estén disponibles.
--
-- =================================================================

create extension if not exists pgcrypto;
