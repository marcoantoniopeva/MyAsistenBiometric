-- =================================================================
--
-- Archivo: 09_seed.sql
-- Descripción: Contiene los datos iniciales (catálogos)
--              necesarios para que el sistema funcione
--              correctamente desde el despliegue inicial.
--
-- =================================================================

insert into public.rol (codigo, nombre, descripcion)
values
  ('ALUMNO', 'Alumno', 'Usuario estudiante'),
  ('MAESTRO', 'Maestro', 'Usuario docente'),
  ('CONTROL_ESCOLAR', 'Control Escolar', 'Administración escolar'),
  ('DIRECCION', 'Dirección', 'Administración y supervisión institucional'),
  ('KIOSCO', 'Kiosco', 'Cuenta técnica para acceso físico')
on conflict (codigo) do update
set nombre = excluded.nombre,
    descripcion = excluded.descripcion;

insert into public.tipo_actividad (nombre, descripcion)
values
  ('ACTIVIDAD_CLASE', 'Actividad realizada durante una sesión'),
  ('TAREA', 'Trabajo asignado fuera de clase'),
  ('PROYECTO', 'Proyecto académico'),
  ('EXAMEN', 'Evaluación escrita, oral o práctica'),
  ('PRACTICA', 'Práctica de laboratorio o taller'),
  ('PARTICIPACION', 'Participación en clase')
on conflict (nombre) do nothing;

insert into public.tipo_vehiculo (nombre, descripcion)
values
  ('MOTOCICLETA', 'Vehículo motorizado de dos ruedas'),
  ('AUTOMOVIL', 'Automóvil particular'),
  ('CAMIONETA', 'Camioneta particular')
on conflict (nombre) do nothing;

insert into public.permiso (codigo, descripcion)
values
  ('ALUMNO_LEER_PROPIO', 'Consultar información académica propia'),
  ('ALUMNO_REGISTRAR_ASISTENCIA', 'Registrar asistencia propia'),
  ('ALUMNO_ENTREGAR_ACTIVIDAD', 'Subir evidencias de actividades'),
  ('MAESTRO_GESTIONAR_CURSO', 'Administrar cursos asignados'),
  ('MAESTRO_CALIFICAR', 'Capturar calificaciones'),
  ('MAESTRO_VALIDAR_ASISTENCIA', 'Validar y modificar asistencias'),
  ('CONTROL_GESTIONAR_USUARIOS', 'Administrar alumnos y maestros'),
  ('CONTROL_GESTIONAR_INSCRIPCIONES', 'Validar pagos e inscripciones'),
  ('CONTROL_CORREGIR_CALIFICACION', 'Corregir calificaciones extemporáneas'),
  ('DIRECCION_REPORTES', 'Consultar reportes globales'),
  ('DIRECCION_SUSPENDER_SISTEMA', 'Configurar suspensiones institucionales'),
  ('KIOSCO_REGISTRAR_ACCESO', 'Validar y registrar accesos físicos')
on conflict (codigo) do update
set descripcion = excluded.descripcion;

-- Asignación base de permisos.
insert into public.rol_permiso (rol_id, permiso_id)
select r.id, p.id
from public.rol r
join public.permiso p on
  (r.codigo = 'ALUMNO' and p.codigo in (
    'ALUMNO_LEER_PROPIO',
    'ALUMNO_REGISTRAR_ASISTENCIA',
    'ALUMNO_ENTREGAR_ACTIVIDAD'
  ))
  or
  (r.codigo = 'MAESTRO' and p.codigo in (
    'MAESTRO_GESTIONAR_CURSO',
    'MAESTRO_CALIFICAR',
    'MAESTRO_VALIDAR_ASISTENCIA'
  ))
  or
  (r.codigo = 'CONTROL_ESCOLAR' and p.codigo in (
    'CONTROL_GESTIONAR_USUARIOS',
    'CONTROL_GESTIONAR_INSCRIPCIONES',
    'CONTROL_CORREGIR_CALIFICACION'
  ))
  or
  (r.codigo = 'DIRECCION')
  or
  (r.codigo = 'KIOSCO' and p.codigo = 'KIOSCO_REGISTRAR_ACCESO')
on conflict do nothing;
