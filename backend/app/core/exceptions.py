"""
====================================================
Proyecto:
    Plataforma de Asistencia Biometrica Escolar
modulo:
    Infraestructura Base

Archivo:
    exceptions.py

Descripcion:
    Define las excepciones personalizadas 
    que se utilizaran y utiliza el proyecto 
    para manejar los errores de manera consistente
    y centralizadas y para que FastAPI pueda convertirlas en 
    resppuestas HTTP controladas y estandarizadas.

Responsabilidades:
    - centralizar las escepciones del sistema
    - Evitar el uso de excepciones genericas en la logica de negocio
    - Proporcionar una forma estandarizada de manejar errores y excepciones en la aplicacion
    - Facilitar el manejo de errores
    - Permitir que los servicios comuniquen errores de manera clara y consistente
      hacia las capas superiores de la aplicacion, como la capa de presentacion o la capa de API.

Autor:
    Marco Antonio Peña Vargas

Fecha de Creacion:
    11 Agosto 2026

=================================================
"""

from typing import Optional

class ExcepcionAplicacion(Exception):

    """
    Excepcion personalizada base de la aplicacion.

    Todas las excepciones personalizadas del sistema
    deben heredar de esta clase para garantizar un manejo
    consistente de los errores y excepciones en toda la aplicacion.
    """

    def __init__(
            self,
            mensaje: str,
            codigo: str = "App_Error",
    )-> None:
        self.mensaje = mensaje
        self.codigo = codigo

        #se inicializa la clase base de Exception con el mensaje 
        #de error para que pueda ser manejado por FastAPI y convertido en una respuesta HTTP controlada.
        #es la clase Exception de python.
        super().__init__(mensaje)

class ExcepcionAutenticacion(ExcepcionAplicacion):
    """
    Representa un error relacionado con los permisos
    de acceso de un usuario.

    Se produce cuando un usuario esta autenticando,
    pero no tiene los permisos necesario o suficientes
    para acceder a un recurso o para realizar una 
    determinada operacion.
    """

    def __init__(
            self,
            mensaje: str = (
                " El usuario no tiene los permisos"
                "para realizar esta operacion"
            ),
    ) -> None:
        super().__init__(
            mensaje=mensaje,
            codigo="ERROR_DE_AUTENTICACION",
        )

