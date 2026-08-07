-- =================================================================
--
-- Archivo: 07_views.sql
-- Descripción: Define las vistas (views) que simplifican
--              consultas complejas y comunes, desnormalizando
--              datos para facilitar el acceso desde la aplicación.
--
-- =================================================================

create or replace view public.v_alumno_perfil
with (security_invoker = true)
as
select
  a.id as alumno_id,
  p.id as persona_id,
  p.auth_user_id,
  p.institucion_id,
  a.matricula,
  p.nombres,
  p.apellido_paterno,
  p.apellido_materno,
  p.correo_institucional,
  p.telefono_recuperacion,
  p.foto_storage_path,
  c.id as carrera_id,
  c.nombre as carrera,
  c.siglas as carrera_siglas,
  a.semestre_actual,
  a.estatus_academico
from public.alumno a
join public.persona p on p.id = a.persona_id
join public.carrera c on c.id = a.carrera_id;

create or replace view public.v_curso_detalle
with (security_invoker = true)
as
select
  cu.id as curso_id,
  pe.id as periodo_escolar_id,
  pe.nombre as periodo,
  m.id as materia_id,
  m.clave as materia_clave,
  m.nombre as materia,
  g.id as grupo_id,
  g.nombre as grupo,
  ma.id as maestro_id,
  concat_ws(' ', p.nombres, p.apellido_paterno, p.apellido_materno) as maestro
from public.curso cu
join public.periodo_escolar pe on pe.id = cu.periodo_escolar_id
join public.plan_materia pm on pm.id = cu.plan_materia_id
join public.materia m on m.id = pm.materia_id
join public.grupo g on g.id = cu.grupo_id
left join public.maestro ma on ma.id = cu.maestro_id
left join public.persona p on p.id = ma.persona_id;
