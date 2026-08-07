-- =================================================================
--
-- Archivo: 05_triggers.sql
-- Descripción: Define todos los triggers que se adjuntan a las
--              tablas para automatizar tareas como la
--              actualización de `updated_at`, auditorías
--              y validaciones de negocio complejas.
--
-- =================================================================

-- ---------------------------------------------------------------------
-- TRIGGERS updated_at
-- ---------------------------------------------------------------------
do $$
declare
  t text;
begin
  foreach t in array array[
    'institucion','area_administrativa','departamento_academico','persona',
    'cuenta_institucional','carrera','plan_estudios','materia',
    'periodo_escolar','grupo','salon','alumno','maestro',
    'personal_administrativo','curso','inscripcion','inscripcion_curso',
    'pago','documento_inscripcion_alumno','periodo_evaluacion',
    'rubro_evaluacion','actividad','entrega_actividad',
    'calificacion_entrega','calificacion_parcial','sesion_clase',
    'asistencia','punto_acceso','dispositivo_acceso','credito_alumno',
    'solicitud_documento','vehiculo','pase_vehicular','suspension_sistema'
  ]
  loop
    execute format('drop trigger if exists trg_%I_updated_at on public.%I', t, t);
    execute format(
      'create trigger trg_%I_updated_at before update on public.%I
       for each row execute function public.set_updated_at()',
      t, t
    );
  end loop;
end $$;

drop trigger if exists trg_validar_porcentaje_rubros on public.rubro_evaluacion;
create trigger trg_validar_porcentaje_rubros
before insert or update on public.rubro_evaluacion
for each row execute function public.validar_porcentaje_rubros();

drop trigger if exists trg_validar_entrega on public.entrega_actividad;
create trigger trg_validar_entrega
before insert or update on public.entrega_actividad
for each row execute function public.validar_entrega_actividad();

drop trigger if exists trg_audit_calificacion_parcial on public.calificacion_parcial;
create trigger trg_audit_calificacion_parcial
after update of calificacion_publicada on public.calificacion_parcial
for each row
when (old.calificacion_publicada is distinct from new.calificacion_publicada)
execute function public.audit_calificacion_parcial();

-- Auditoría en entidades sensibles.
do $$
declare
  t text;
begin
  foreach t in array array[
    'inscripcion','inscripcion_curso','pago','calificacion_parcial',
    'asistencia','credito_alumno','solicitud_documento',
    'pase_vehicular','suspension_sistema'
  ]
  loop
    execute format('drop trigger if exists trg_%I_audit on public.%I', t, t);
    execute format(
      'create trigger trg_%I_audit after insert or update or delete on public.%I
       for each row execute function public.audit_row_change()',
      t, t
    );
  end loop;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();
