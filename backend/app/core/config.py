"""
====================================================
Proyecto:
    Plataforma de Asistencia Biometrica Escolar
modulo:
    Infraestructura Base
Archivo:
    config.py

Descripcion:
    Centraliza la configuracion mediante variables
    de entorno, permitiendo la gestion de configuraciones.

    La configuracion es validada mediante la libreria pydantic 
    settings, evitando que credenciales y configuraciones y datos 
    sensibles sean almacenadas directamente en el codigo fuente,
    y permitiendo que sean gestionadas de forma segura y centralizada.

Responsabilidades: 
    Gestionar, tipar y validar de forma estricta todas las variables
    de entorno que se utilizan en el proyecto para la ejecucion segura
    del sistema, utilizando la libreria pydantic para la validacion de datos y la gestion de configuraciones.

    Cargar variables de entorno
    Validar tipos de configuracion
    Porporcionar valores predeterminados seguros
    Centralizar la configuracion del sistema


Autor:
    Marco Antonio Peña Vargas

Fecha de Creacion:
    6 Agosto 2026

=================================================
"""

from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional


class Settings(BaseSettings):

    """

    Configuracion globales de la aplicacion.

    Las variables pueden ser proporcionadas mediante:
    - Variables de entorno del sistema
    -Archivo .env durante el desarrollo y pruebas locales

    Las varibales obligatorias provocaran un error durante
    el inicio de la aplicacion si noestan configuradas correctamente.
    """


    #   Configuracion general de la aplicacion
    Nombre_Proyecto: str = "Plataforma Escolar con validacion Biometrica"
    Version_Proyecto: str = "1.0.0"
    API_Version: str = "/api/v1"

    ENV: str = "development" 
    DEBUG: bool = False



    #   Configuracion de la base de datos y supabase
    DB_URL: str
    SUPABASE_URL: str
    SUPABASE_ANON_KEY: str

    #  Clave de previlegios unicamente para operaciones
    #  realizadas desde el backend
    SUPABASE_SERVICE_ROLE_KEY: str | None = None




    #  Configuracion de seguridad y autenticacion
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"

    # Tiempo de vida del token de acceso en minutos
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30



    #  Almacenamiento de archivos
    UPLOAD_DIRECTORY: str = "uploads"
    #configuracion opcional para produccion, si no se proporciona se utilizara el directorio por defecto
    CLOUDINARY_URL:str | None = None


    # Correo electronico
    SMTP_SERVER: str | None = None
    SMTP_PORT: int = 587
    SMTP_USERNAME: str | None = None
    SMTP_PASSWORD: str | None = None
    SMTP_USE_TLS: bool = True


    #  Configuracion Pydantic Settings
    model_config = SettingsConfigDict(
        
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )


#  Instancia unica de configuracion global
settings = Settings()