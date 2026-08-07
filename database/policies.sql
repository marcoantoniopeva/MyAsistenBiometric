-- =================================================================
--
-- Archivo: 08_policies.sql
-- Descripción: Contiene toda la configuración de Row-Level
--              Security (RLS), incluyendo la habilitación,
--              las políticas de acceso y los privilegios
--              de los roles de la base de datos.
--
-- =================================================================

-- ---------------------------------------------------------------------
-- RLS: HABILITACIÓN
-- ---------------------------------------------------------------------
do $$
declare
  t text;
begin
  foreach t in array array[
    'institucion','area_administrativa','departamento_academico',
    'persona','cuenta_institucional','rol','permiso','usuario_rol',
    'rol_permiso','carrera','plan_estudios','materia','plan_materia',
    'materia_prerrequisito','periodo_escolar','grupo','salon','alumno',
    'maestro','personal_administrativo','curso','horario_curso',
    'inscripcion','inscripcion_curso','archivo','pago',
    'requisito_inscripcion','documento_inscripcion_alumno',
    'periodo_evaluacion','rubro_evaluacion','tipo_actividad','actividad',
    'entrega_actividad','entrega_archivo','calificacion_entrega',
    'calificacion_parcial','historial_calificacion','sesion_clase',
    'asistencia','asistencia_historial','perfil_biometrico',
    'consentimiento_biometrico','punto_acceso','dispositivo_acceso',
    'punto_dispositivo','evento_acceso','codigo_acceso_temporal',
    'tipo_credito','credito_alumno','tipo_documento',
    'solicitud_documento','tipo_vehiculo','vehiculo','pase_vehicular',
    'evento_acceso_vehicular','notificacion','notificacion_destinatario',
    'suspension_sistema','auditoria'
  ]
  loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- RLS: POLÍTICAS BASE
-- ---------------------------------------------------------------------

-- Catálogos visibles para usuarios autenticados.
do $$
declare
  t text;
begin
  foreach t in array array[
    'rol','permiso','tipo_actividad','tipo_vehiculo'
  ]
  loop
    execute format('drop policy if exists authenticated_read_%I on public.%I', t, t);
    execute format(
      'create policy authenticated_read_%I on public.%I
       for select to authenticated using (true)',
      t, t
    );
  end loop;
end $$;

-- Datos institucionales: misma institución.
do $$
declare
  t text;
begin
  foreach t in array array[
    'area_administrativa','departamento_academico','carrera',
    'materia','periodo_escolar','salon','punto_acceso','dispositivo_acceso',
    'tipo_credito','tipo_documento'
  ]
  loop
    execute format('drop policy if exists same_institution_read_%I on public.%I', t, t);
    execute format(
      'create policy same_institution_read_%I on public.%I
       for select to authenticated
       using (institucion_id = public.current_institucion_id())',
      t, t
    );
  end loop;
end $$;

-- Excepción: institucion usa id en vez de institucion_id.
drop policy if exists same_institution_read_institucion on public.institucion;
create policy same_institution_read_institucion
on public.institucion for select to authenticated
using (id = public.current_institucion_id());

-- Administradores: CRUD dentro de su institución en tablas maestras.
do $$
declare
  t text;
begin
  foreach t in array array[
    'area_administrativa','departamento_academico','carrera','materia',
    'periodo_escolar','salon','punto_acceso','dispositivo_acceso',
    'tipo_credito','tipo_documento'
  ]
  loop
    execute format('drop policy if exists admin_all_%I on public.%I', t, t);
    execute format(
      'create policy admin_all_%I on public.%I
       for all to authenticated
       using (public.is_admin() and institucion_id = public.current_institucion_id())
       with check (public.is_admin() and institucion_id = public.current_institucion_id())',
      t, t
    );
  end loop;
end $$;

-- Persona: cada usuario ve su perfil; administradores ven su institución.
drop policy if exists persona_self_or_admin_select on public.persona;
create policy persona_self_or_admin_select
on public.persona for select to authenticated
using (
  auth_user_id = (select auth.uid())
  or (
    public.is_admin()
    and institucion_id = public.current_institucion_id()
  )
);

drop policy if exists persona_self_update on public.persona;
create policy persona_self_update
on public.persona for update to authenticated
using (auth_user_id = (select auth.uid()))
with check (auth_user_id = (select auth.uid()));

drop policy if exists persona_admin_all on public.persona;
create policy persona_admin_all
on public.persona for all to authenticated
using (
  public.is_admin()
  and institucion_id = public.current_institucion_id()
)
with check (
  public.is_admin()
  and institucion_id = public.current_institucion_id()
);

-- Cuenta institucional.
drop policy if exists cuenta_self_select on public.cuenta_institucional;
create policy cuenta_self_select
on public.cuenta_institucional for select to authenticated
using (auth_user_id = (select auth.uid()));

drop policy if exists cuenta_admin_all on public.cuenta_institucional;
create policy cuenta_admin_all
on public.cuenta_institucional for all to authenticated
using (
  public.is_admin()
  and institucion_id = public.current_institucion_id()
)
with check (
  public.is_admin()
  and institucion_id = public.current_institucion_id()
);

-- Roles propios o administración.
drop policy if exists usuario_rol_self_select on public.usuario_rol;
create policy usuario_rol_self_select
on public.usuario_rol for select to authenticated
using (
  auth_user_id = (select auth.uid())
  or public.is_admin()
);

drop policy if exists usuario_rol_admin_all on public.usuario_rol;
create policy usuario_rol_admin_all
on public.usuario_rol for all to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Alumno: perfil propio; administración; maestros con cursos compartidos.
drop policy if exists alumno_select_policy on public.alumno;
create policy alumno_select_policy
on public.alumno for select to authenticated
using (
  id = public.current_alumno_id()
  or public.is_admin()
  or exists (
    select 1
    from public.inscripcion i
    join public.inscripcion_curso ic on ic.inscripcion_id = i.id
    join public.curso c on c.id = ic.curso_id
    where i.alumno_id = alumno.id
      and c.maestro_id = public.current_maestro_id()
  )
);

drop policy if exists alumno_admin_all on public.alumno;
create policy alumno_admin_all
on public.alumno for all to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Maestro: propio y administración.
drop policy if exists maestro_select_policy on public.maestro;
create policy maestro_select_policy
on public.maestro for select to authenticated
using (
  id = public.current_maestro_id()
  or public.is_admin()
);

drop policy if exists maestro_admin_all on public.maestro;
create policy maestro_admin_all
on public.maestro for all to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Tablas académicas generales visibles para autenticados.
do $$
declare
  t text;
begin
  foreach t in array array[
    'plan_estudios','plan_materia','materia_prerrequisito','grupo',
    'horario_curso','periodo_evaluacion','requisito_inscripcion'
  ]
  loop
    execute format('drop policy if exists academic_read_%I on public.%I', t, t);
    execute format(
      'create policy academic_read_%I on public.%I
       for select to authenticated using (true)',
      t, t
    );
    execute format('drop policy if exists academic_admin_%I on public.%I', t, t);
    execute format(
      'create policy academic_admin_%I on public.%I
       for all to authenticated
       using (public.is_admin())
       with check (public.is_admin())',
      t, t
    );
  end loop;
end $$;

-- Cursos: maestro asignado puede modificarlos parcialmente; administración CRUD.
drop policy if exists curso_teacher_select on public.curso;
create policy curso_teacher_select
on public.curso for select to authenticated
using (
  maestro_id = public.current_maestro_id()
  or public.is_admin()
  or exists (
    select 1
    from public.inscripcion_curso ic
    join public.inscripcion i on i.id = ic.inscripcion_id
    where ic.curso_id = curso.id
      and i.alumno_id = public.current_alumno_id()
  )
);

-- Inscripción: alumno propia; administración.
drop policy if exists inscripcion_select_policy on public.inscripcion;
create policy inscripcion_select_policy
on public.inscripcion for select to authenticated
using (
  alumno_id = public.current_alumno_id()
  or public.is_admin()
);

drop policy if exists inscripcion_student_insert on public.inscripcion;
create policy inscripcion_student_insert
on public.inscripcion for insert to authenticated
with check (alumno_id = public.current_alumno_id());

drop policy if exists inscripcion_student_update on public.inscripcion;
create policy inscripcion_student_update
on public.inscripcion for update to authenticated
using (
  alumno_id = public.current_alumno_id()
  and estado in ('BORRADOR','PAGO_PENDIENTE','PAGO_RECHAZADO')
)
with check (alumno_id = public.current_alumno_id());

drop policy if exists inscripcion_admin_all on public.inscripcion;
create policy inscripcion_admin_all
on public.inscripcion for all to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Inscripción a curso: alumno propio, maestro del curso y administración.
drop policy if exists inscripcion_curso_select_policy on public.inscripcion_curso;
create policy inscripcion_curso_select_policy
on public.inscripcion_curso for select to authenticated
using (
  public.is_admin()
  or exists (
    select 1
    from public.inscripcion i
    where i.id = inscripcion_curso.inscripcion_id
      and i.alumno_id = public.current_alumno_id()
  )
  or exists (
    select 1
    from public.curso c
    where c.id = inscripcion_curso.curso_id
      and c.maestro_id = public.current_maestro_id()
  )
);

drop policy if exists inscripcion_curso_admin_all on public.inscripcion_curso;
create policy inscripcion_curso_admin_all
on public.inscripcion_curso for all to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Actividades y rubros: alumnos inscritos leen; maestro propietario administra.
drop policy if exists rubro_select_policy on public.rubro_evaluacion;
create policy rubro_select_policy
on public.rubro_evaluacion for select to authenticated
using (
  public.is_admin()
  or exists (
    select 1 from public.curso c
    where c.id = rubro_evaluacion.curso_id
      and (
        c.maestro_id = public.current_maestro_id()
        or exists (
          select 1
          from public.inscripcion_curso ic
          join public.inscripcion i on i.id = ic.inscripcion_id
          where ic.curso_id = c.id
            and i.alumno_id = public.current_alumno_id()
        )
      )
  )
);

drop policy if exists rubro_teacher_all on public.rubro_evaluacion;
create policy rubro_teacher_all
on public.rubro_evaluacion for all to authenticated
using (
  public.is_admin()
  or exists (
    select 1 from public.curso c
    where c.id = rubro_evaluacion.curso_id
      and c.maestro_id = public.current_maestro_id()
  )
)
with check (
  public.is_admin()
  or exists (
    select 1 from public.curso c
    where c.id = rubro_evaluacion.curso_id
      and c.maestro_id = public.current_maestro_id()
  )
);

drop policy if exists actividad_select_policy on public.actividad;
create policy actividad_select_policy
on public.actividad for select to authenticated
using (
  public.is_admin()
  or exists (
    select 1
    from public.rubro_evaluacion r
    join public.curso c on c.id = r.curso_id
    where r.id = actividad.rubro_evaluacion_id
      and (
        c.maestro_id = public.current_maestro_id()
        or exists (
          select 1
          from public.inscripcion_curso ic
          join public.inscripcion i on i.id = ic.inscripcion_id
          where ic.curso_id = c.id
            and i.alumno_id = public.current_alumno_id()
        )
      )
  )
);

drop policy if exists actividad_teacher_all on public.actividad;
create policy actividad_teacher_all
on public.actividad for all to authenticated
using (
  public.is_admin()
  or exists (
    select 1
    from public.rubro_evaluacion r
    join public.curso c on c.id = r.curso_id
    where r.id = actividad.rubro_evaluacion_id
      and c.maestro_id = public.current_maestro_id()
  )
)
with check (
  public.is_admin()
  or exists (
    select 1
    from public.rubro_evaluacion r
    join public.curso c on c.id = r.curso_id
    where r.id = actividad.rubro_evaluacion_id
      and c.maestro_id = public.current_maestro_id()
  )
);

-- Entregas: alumno propietario; maestro del curso; administración.
drop policy if exists entrega_select_policy on public.entrega_actividad;
create policy entrega_select_policy
on public.entrega_actividad for select to authenticated
using (
  public.is_admin()
  or exists (
    select 1
    from public.inscripcion_curso ic
    join public.inscripcion i on i.id = ic.inscripcion_id
    where ic.id = entrega_actividad.inscripcion_curso_id
      and i.alumno_id = public.current_alumno_id()
  )
  or exists (
    select 1
    from public.actividad a
    join public.rubro_evaluacion r on r.id = a.rubro_evaluacion_id
    join public.curso c on c.id = r.curso_id
    where a.id = entrega_actividad.actividad_id
      and c.maestro_id = public.current_maestro_id()
  )
);

drop policy if exists entrega_student_insert on public.entrega_actividad;
create policy entrega_student_insert
on public.entrega_actividad for insert to authenticated
with check (
  exists (
    select 1
    from public.inscripcion_curso ic
    join public.inscripcion i on i.id = ic.inscripcion_id
    where ic.id = entrega_actividad.inscripcion_curso_id
      and i.alumno_id = public.current_alumno_id()
  )
);

drop policy if exists entrega_student_update on public.entrega_actividad;
create policy entrega_student_update
on public.entrega_actividad for update to authenticated
using (
  exists (
    select 1
    from public.inscripcion_curso ic
    join public.inscripcion i on i.id = ic.inscripcion_id
    where ic.id = entrega_actividad.inscripcion_curso_id
      and i.alumno_id = public.current_alumno_id()
  )
)
with check (
  exists (
    select 1
    from public.inscripcion_curso ic
    join public.inscripcion i on i.id = ic.inscripcion_id
    where ic.id = entrega_actividad.inscripcion_curso_id
      and i.alumno_id = public.current_alumno_id()
  )
);

-- Calificaciones: alumno propietario lee; maestro asignado/admin gestiona.
drop policy if exists calificacion_parcial_select_policy on public.calificacion_parcial;
create policy calificacion_parcial_select_policy
on public.calificacion_parcial for select to authenticated
using (
  public.is_admin()
  or exists (
    select 1
    from public.inscripcion_curso ic
    join public.inscripcion i on i.id = ic.inscripcion_id
    where ic.id = calificacion_parcial.inscripcion_curso_id
      and (
        i.alumno_id = public.current_alumno_id()
        or exists (
          select 1 from public.curso c
          where c.id = ic.curso_id
            and c.maestro_id = public.current_maestro_id()
        )
      )
  )
);

drop policy if exists calificacion_parcial_teacher_all on public.calificacion_parcial;
create policy calificacion_parcial_teacher_all
on public.calificacion_parcial for all to authenticated
using (
  public.is_admin()
  or exists (
    select 1
    from public.inscripcion_curso ic
    join public.curso c on c.id = ic.curso_id
    where ic.id = calificacion_parcial.inscripcion_curso_id
      and c.maestro_id = public.current_maestro_id()
  )
)
with check (
  public.is_admin()
  or exists (
    select 1
    from public.inscripcion_curso ic
    join public.curso c on c.id = ic.curso_id
    where ic.id = calificacion_parcial.inscripcion_curso_id
      and c.maestro_id = public.current_maestro_id()
  )
);

-- Sesiones: alumnos inscritos leen; maestro asignado/admin gestiona.
drop policy if exists sesion_select_policy on public.sesion_clase;
create policy sesion_select_policy
on public.sesion_clase for select to authenticated
using (
  public.is_admin()
  or exists (
    select 1 from public.curso c
    where c.id = sesion_clase.curso_id
      and (
        c.maestro_id = public.current_maestro_id()
        or exists (
          select 1
          from public.inscripcion_curso ic
          join public.inscripcion i on i.id = ic.inscripcion_id
          where ic.curso_id = c.id
            and i.alumno_id = public.current_alumno_id()
        )
      )
  )
);

drop policy if exists sesion_teacher_all on public.sesion_clase;
create policy sesion_teacher_all
on public.sesion_clase for all to authenticated
using (
  public.is_admin()
  or exists (
    select 1 from public.curso c
    where c.id = sesion_clase.curso_id
      and c.maestro_id = public.current_maestro_id()
  )
)
with check (
  public.is_admin()
  or exists (
    select 1 from public.curso c
    where c.id = sesion_clase.curso_id
      and c.maestro_id = public.current_maestro_id()
  )
);

-- Asistencia: alumno propia; maestro del curso; administración.
drop policy if exists asistencia_select_policy on public.asistencia;
create policy asistencia_select_policy
on public.asistencia for select to authenticated
using (
  public.is_admin()
  or exists (
    select 1
    from public.inscripcion_curso ic
    join public.inscripcion i on i.id = ic.inscripcion_id
    join public.curso c on c.id = ic.curso_id
    where ic.id = asistencia.inscripcion_curso_id
      and (
        i.alumno_id = public.current_alumno_id()
        or c.maestro_id = public.current_maestro_id()
      )
  )
);

drop policy if exists asistencia_student_insert on public.asistencia;
create policy asistencia_student_insert
on public.asistencia for insert to authenticated
with check (
  exists (
    select 1
    from public.inscripcion_curso ic
    join public.inscripcion i on i.id = ic.inscripcion_id
    where ic.id = asistencia.inscripcion_curso_id
      and i.alumno_id = public.current_alumno_id()
  )
);

drop policy if exists asistencia_teacher_update on public.asistencia;
create policy asistencia_teacher_update
on public.asistencia for update to authenticated
using (
  public.is_admin()
  or exists (
    select 1
    from public.inscripcion_curso ic
    join public.curso c on c.id = ic.curso_id
    where ic.id = asistencia.inscripcion_curso_id
      and c.maestro_id = public.current_maestro_id()
  )
)
with check (
  public.is_admin()
  or exists (
    select 1
    from public.inscripcion_curso ic
    join public.curso c on c.id = ic.curso_id
    where ic.id = asistencia.inscripcion_curso_id
      and c.maestro_id = public.current_maestro_id()
  )
);

-- Perfil biométrico: propietario y administración; kiosco no obtiene embeddings.
drop policy if exists biometrico_self_admin_select on public.perfil_biometrico;
create policy biometrico_self_admin_select
on public.perfil_biometrico for select to authenticated
using (
  persona_id = public.current_persona_id()
  or public.is_admin()
);

drop policy if exists biometrico_admin_all on public.perfil_biometrico;
create policy biometrico_admin_all
on public.perfil_biometrico for all to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Eventos de acceso: cada persona ve los propios; admin; kiosco inserta.
drop policy if exists evento_acceso_select_policy on public.evento_acceso;
create policy evento_acceso_select_policy
on public.evento_acceso for select to authenticated
using (
  persona_id = public.current_persona_id()
  or public.is_admin()
);

drop policy if exists evento_acceso_kiosco_insert on public.evento_acceso;
create policy evento_acceso_kiosco_insert
on public.evento_acceso for insert to authenticated
with check (
  public.has_role('KIOSCO')
  or public.is_admin()
);

-- Código temporal: solo propietario; service role puede operar sin RLS.
drop policy if exists codigo_temporal_self_select on public.codigo_acceso_temporal;
create policy codigo_temporal_self_select
on public.codigo_acceso_temporal for select to authenticated
using (auth_user_id = (select auth.uid()));

drop policy if exists codigo_temporal_self_insert on public.codigo_acceso_temporal;
create policy codigo_temporal_self_insert
on public.codigo_acceso_temporal for insert to authenticated
with check (auth_user_id = (select auth.uid()));

-- Créditos y trámites.
drop policy if exists credito_select_policy on public.credito_alumno;
create policy credito_select_policy
on public.credito_alumno for select to authenticated
using (
  alumno_id = public.current_alumno_id()
  or public.is_admin()
);

drop policy if exists credito_admin_all on public.credito_alumno;
create policy credito_admin_all
on public.credito_alumno for all to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists solicitud_select_policy on public.solicitud_documento;
create policy solicitud_select_policy
on public.solicitud_documento for select to authenticated
using (
  alumno_id = public.current_alumno_id()
  or public.is_admin()
);

drop policy if exists solicitud_student_insert on public.solicitud_documento;
create policy solicitud_student_insert
on public.solicitud_documento for insert to authenticated
with check (alumno_id = public.current_alumno_id());

drop policy if exists solicitud_admin_all on public.solicitud_documento;
create policy solicitud_admin_all
on public.solicitud_documento for all to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Vehículos: propietario consulta; administración gestiona.
drop policy if exists vehiculo_select_policy on public.vehiculo;
create policy vehiculo_select_policy
on public.vehiculo for select to authenticated
using (
  persona_responsable_id = public.current_persona_id()
  or public.is_admin()
);

drop policy if exists vehiculo_admin_all on public.vehiculo;
create policy vehiculo_admin_all
on public.vehiculo for all to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists pase_select_policy on public.pase_vehicular;
create policy pase_select_policy
on public.pase_vehicular for select to authenticated
using (
  public.is_admin()
  or exists (
    select 1 from public.vehiculo v
    where v.id = pase_vehicular.vehiculo_id
      and v.persona_responsable_id = public.current_persona_id()
  )
);

drop policy if exists pase_admin_all on public.pase_vehicular;
create policy pase_admin_all
on public.pase_vehicular for all to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Notificaciones: destinatario.
drop policy if exists notificacion_destinatario_self on public.notificacion_destinatario;
create policy notificacion_destinatario_self
on public.notificacion_destinatario for select to authenticated
using (auth_user_id = (select auth.uid()));

drop policy if exists notificacion_self_via_recipient on public.notificacion;
create policy notificacion_self_via_recipient
on public.notificacion for select to authenticated
using (
  public.is_admin()
  or exists (
    select 1 from public.notificacion_destinatario nd
    where nd.notificacion_id = notificacion.id
      and nd.auth_user_id = (select auth.uid())
  )
);

drop policy if exists notificacion_admin_all on public.notificacion;
create policy notificacion_admin_all
on public.notificacion for all to authenticated
using (public.is_admin())
with check (
  public.is_admin()
  and institucion_id = public.current_institucion_id()
);

-- Auditoría: solo Dirección; Control Escolar podría habilitarse si se requiere.
drop policy if exists auditoria_direccion_select on public.auditoria;
create policy auditoria_direccion_select
on public.auditoria for select to authenticated
using (
  public.has_role('DIRECCION')
  and institucion_id = public.current_institucion_id()
);

-- ---------------------------------------------------------------------
-- PRIVILEGIOS
-- ---------------------------------------------------------------------
grant usage on schema public to anon, authenticated, service_role;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;
grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;

alter default privileges in schema public
grant select, insert, update, delete on tables to authenticated;

alter default privileges in schema public
grant usage, select on sequences to authenticated;

alter default privileges in schema public
grant all on tables to service_role;

alter default privileges in schema public
grant all on sequences to service_role;
