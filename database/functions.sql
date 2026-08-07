-- =================================================================
--
-- Archivo: 03_functions.sql
-- Descripción: Almacena todas las funciones de PostgreSQL,
--              incluyendo funciones de ayuda para RLS,
--              auditoría y validaciones de negocio.
--
-- =================================================================

-- ---------------------------------------------------------------------
-- FUNCIÓN GENERAL updated_at
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------
-- FUNCIONES DE AUTORIZACIÓN PARA RLS
-- ---------------------------------------------------------------------
create or replace function public.current_persona_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select p.id
  from public.persona p
  where p.auth_user_id = (select auth.uid())
  limit 1;
$$;

create or replace function public.current_institucion_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select c.institucion_id
  from public.cuenta_institucional c
  where c.auth_user_id = (select auth.uid())
  limit 1;
$$;

create or replace function public.has_role(role_code text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.usuario_rol ur
    join public.rol r on r.id = ur.rol_id
    where ur.auth_user_id = (select auth.uid())
      and ur.activo = true
      and r.codigo = role_code
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.has_role('DIRECCION')
      or public.has_role('CONTROL_ESCOLAR');
$$;

create or replace function public.current_alumno_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select a.id
  from public.alumno a
  join public.persona p on p.id = a.persona_id
  where p.auth_user_id = (select auth.uid())
  limit 1;
$$;

create or replace function public.current_maestro_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select m.id
  from public.maestro m
  join public.persona p on p.id = m.persona_id
  where p.auth_user_id = (select auth.uid())
  limit 1;
$$;

-- ---------------------------------------------------------------------
-- FUNCIÓN DE AUDITORÍA GENÉRICA
-- ---------------------------------------------------------------------
create or replace function public.audit_row_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old jsonb;
  v_new jsonb;
  v_record_id text;
  v_institucion uuid;
begin
  if tg_op = 'INSERT' then
    v_old := null;
    v_new := to_jsonb(new);
    v_record_id := coalesce(v_new->>'id', '');
  elsif tg_op = 'UPDATE' then
    v_old := to_jsonb(old);
    v_new := to_jsonb(new);
    v_record_id := coalesce(v_new->>'id', v_old->>'id', '');
  else
    v_old := to_jsonb(old);
    v_new := null;
    v_record_id := coalesce(v_old->>'id', '');
  end if;

  v_institucion := public.current_institucion_id();

  insert into public.auditoria (
    institucion_id,
    auth_user_id,
    entidad,
    registro_id,
    operacion,
    valor_anterior,
    valor_nuevo
  )
  values (
    v_institucion,
    auth.uid(),
    tg_table_schema || '.' || tg_table_name,
    v_record_id,
    tg_op::public.operacion_auditoria,
    v_old,
    v_new
  );

  if tg_op = 'DELETE' then
    return old;
  end if;

  return new;
end;
$$;

-- Auditoría especializada de cambios de calificación parcial.
create or replace function public.audit_calificacion_parcial()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.calificacion_publicada is distinct from old.calificacion_publicada then
    insert into public.historial_calificacion (
      inscripcion_curso_id,
      periodo_evaluacion_id,
      calificacion_anterior,
      calificacion_nueva,
      motivo,
      modificado_por
    )
    values (
      new.inscripcion_curso_id,
      new.periodo_evaluacion_id,
      old.calificacion_publicada,
      new.calificacion_publicada,
      coalesce(current_setting('app.motivo_cambio', true), 'Cambio registrado por el sistema'),
      auth.uid()
    );
  end if;
  return new;
end;
$$;

-- ---------------------------------------------------------------------
-- VALIDACIONES DE NEGOCIO
-- ---------------------------------------------------------------------
create or replace function public.validar_porcentaje_rubros()
returns trigger
language plpgsql
as $$
declare
  total numeric(7,2);
begin
  select coalesce(sum(porcentaje), 0)
    into total
  from public.rubro_evaluacion
  where curso_id = new.curso_id
    and periodo_evaluacion_id = new.periodo_evaluacion_id
    and id <> coalesce(new.id, gen_random_uuid());

  total := total + new.porcentaje;

  if total > 100 then
    raise exception 'La suma de los rubros no puede exceder 100%%. Total propuesto: %', total;
  end if;

  return new;
end;
$$;

create or replace function public.validar_entrega_actividad()
returns trigger
language plpgsql
as $$
declare
  v_limite timestamptz;
  v_permite_tardia boolean;
  v_max_intentos smallint;
begin
  select fecha_limite, permite_entrega_tardia, numero_intentos
    into v_limite, v_permite_tardia, v_max_intentos
  from public.actividad
  where id = new.actividad_id;

  if new.numero_intento > v_max_intentos then
    raise exception 'El número de intento excede el máximo permitido';
  end if;

  if new.fecha_entrega > v_limite and not v_permite_tardia then
    raise exception 'La actividad ya no acepta entregas';
  end if;

  if new.fecha_entrega > v_limite then
    new.estado := 'ENTREGADA_EXTEMPORANEA';
  else
    new.estado := 'ENTREGADA_A_TIEMPO';
  end if;

  return new;
end;
$$;

-- ---------------------------------------------------------------------
-- FUNCIÓN OPCIONAL PARA CREAR PERFIL DESDE auth.users
-- ---------------------------------------------------------------------
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_institucion uuid;
  v_persona uuid;
begin
  v_institucion := nullif(new.raw_user_meta_data->>'institucion_id', '')::uuid;

  -- No crea registros incompletos.
  if v_institucion is null
     or nullif(new.raw_user_meta_data->>'nombres', '') is null
     or nullif(new.raw_user_meta_data->>'apellido_paterno', '') is null then
    return new;
  end if;

  insert into public.persona (
    institucion_id,
    auth_user_id,
    nombres,
    apellido_paterno,
    apellido_materno,
    correo_institucional
  )
  values (
    v_institucion,
    new.id,
    new.raw_user_meta_data->>'nombres',
    new.raw_user_meta_data->>'apellido_paterno',
    nullif(new.raw_user_meta_data->>'apellido_materno', ''),
    new.email
  )
  returning id into v_persona;

  insert into public.cuenta_institucional (
    persona_id,
    auth_user_id,
    institucion_id,
    nombre_usuario
  )
  values (
    v_persona,
    new.id,
    v_institucion,
    coalesce(
      nullif(new.raw_user_meta_data->>'nombre_usuario', ''),
      new.email,
      new.id::text
    )
  );

  return new;
exception
  when others then
    -- Evita bloquear el alta en Auth por metadatos institucionales inválidos.
    raise warning 'No se creó el perfil institucional para auth.users %: %', new.id, sqlerrm;
    return new;
end;
$$;
