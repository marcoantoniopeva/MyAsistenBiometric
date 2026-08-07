-- =================================================================
--
-- Archivo: 06_indexes.sql
-- Descripción: Crea todos los índices de la base de datos para
--              optimizar el rendimiento de las consultas más
--              frecuentes.
--
-- =================================================================

create index if not exists idx_persona_auth_user on public.persona(auth_user_id);
create index if not exists idx_persona_institucion on public.persona(institucion_id);
create index if not exists idx_cuenta_auth_user on public.cuenta_institucional(auth_user_id);
create index if not exists idx_usuario_rol_auth on public.usuario_rol(auth_user_id);
create index if not exists idx_alumno_persona on public.alumno(persona_id);
create index if not exists idx_alumno_carrera on public.alumno(carrera_id);
create index if not exists idx_maestro_persona on public.maestro(persona_id);
create index if not exists idx_curso_maestro on public.curso(maestro_id);
create index if not exists idx_curso_grupo on public.curso(grupo_id);
create index if not exists idx_inscripcion_alumno on public.inscripcion(alumno_id);
create index if not exists idx_inscripcion_periodo on public.inscripcion(periodo_escolar_id);
create index if not exists idx_inscripcion_curso_curso on public.inscripcion_curso(curso_id);
create index if not exists idx_actividad_rubro on public.actividad(rubro_evaluacion_id);
create index if not exists idx_entrega_actividad on public.entrega_actividad(actividad_id);
create index if not exists idx_entrega_inscripcion on public.entrega_actividad(inscripcion_curso_id);
create index if not exists idx_sesion_curso_fecha on public.sesion_clase(curso_id, fecha);
create index if not exists idx_asistencia_sesion on public.asistencia(sesion_clase_id);
create index if not exists idx_asistencia_inscripcion on public.asistencia(inscripcion_curso_id);
create index if not exists idx_evento_acceso_persona_fecha on public.evento_acceso(persona_id, fecha_hora desc);
create index if not exists idx_evento_acceso_punto_fecha on public.evento_acceso(punto_acceso_id, fecha_hora desc);
create index if not exists idx_notificacion_destinatario_usuario on public.notificacion_destinatario(auth_user_id, fecha_lectura);
create index if not exists idx_auditoria_entidad_registro on public.auditoria(entidad, registro_id);
create index if not exists idx_auditoria_usuario_fecha on public.auditoria(auth_user_id, created_at desc);
create index if not exists idx_auditoria_nuevo_gin on public.auditoria using gin(valor_nuevo);
create index if not exists idx_evento_metadatos_gin on public.evento_acceso using gin(metadatos);
