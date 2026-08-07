-- =================================================================
--
-- Archivo: 04_schema.sql
-- Descripción: Contiene la definición de todas las tablas
--              (CREATE TABLE) que componen el esquema de la
--              base de datos, organizadas por módulos funcionales.
--
-- =================================================================

-- ---------------------------------------------------------------------
-- ORGANIZACIÓN INSTITUCIONAL
-- ---------------------------------------------------------------------
create table if not exists public.institucion (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  siglas text not null,
  clave_institucion text not null,
  direccion text,
  zona_horaria text not null default 'America/Mexico_City',
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_institucion_siglas unique (siglas),
  constraint uq_institucion_clave unique (clave_institucion),
  constraint ck_institucion_nombre check (length(trim(nombre)) >= 3)
);

create table if not exists public.area_administrativa (
  id uuid primary key default gen_random_uuid(),
  institucion_id uuid not null references public.institucion(id) on delete restrict,
  nombre text not null,
  descripcion text,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_area_nombre unique (institucion_id, nombre)
);

create table if not exists public.departamento_academico (
  id uuid primary key default gen_random_uuid(),
  institucion_id uuid not null references public.institucion(id) on delete restrict,
  nombre text not null,
  siglas text,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_departamento_nombre unique (institucion_id, nombre),
  constraint uq_departamento_siglas unique (institucion_id, siglas)
);

-- ---------------------------------------------------------------------
-- IDENTIDAD, PERSONAS Y ROLES
-- ---------------------------------------------------------------------
create table if not exists public.persona (
  id uuid primary key default gen_random_uuid(),
  institucion_id uuid not null references public.institucion(id) on delete restrict,
  auth_user_id uuid unique references auth.users(id) on delete set null,
  nombres text not null,
  apellido_paterno text not null,
  apellido_materno text,
  correo_institucional text,
  correo_recuperacion text,
  telefono_recuperacion text,
  fecha_nacimiento date,
  foto_storage_path text,
  medio_recuperacion_verificado boolean not null default false,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_persona_correo_institucional unique (institucion_id, correo_institucional),
  constraint ck_persona_nombres check (length(trim(nombres)) >= 2),
  constraint ck_persona_apellido check (length(trim(apellido_paterno)) >= 2)
);

create table if not exists public.cuenta_institucional (
  id uuid primary key default gen_random_uuid(),
  persona_id uuid unique references public.persona(id) on delete cascade,
  auth_user_id uuid not null unique references auth.users(id) on delete cascade,
  institucion_id uuid not null references public.institucion(id) on delete restrict,
  nombre_usuario text not null,
  estado public.estado_cuenta not null default 'CONTRASENA_TEMPORAL',
  requiere_cambio_password boolean not null default true,
  intentos_fallidos integer not null default 0,
  bloqueado_hasta timestamptz,
  ultimo_acceso timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_cuenta_usuario unique (institucion_id, nombre_usuario),
  constraint ck_cuenta_intentos check (intentos_fallidos >= 0)
);

create table if not exists public.rol (
  id uuid primary key default gen_random_uuid(),
  codigo text not null unique,
  nombre text not null unique,
  descripcion text,
  es_sistema boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.permiso (
  id uuid primary key default gen_random_uuid(),
  codigo text not null unique,
  descripcion text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.usuario_rol (
  auth_user_id uuid not null references auth.users(id) on delete cascade,
  rol_id uuid not null references public.rol(id) on delete cascade,
  asignado_por uuid references auth.users(id) on delete set null,
  fecha_asignacion timestamptz not null default now(),
  activo boolean not null default true,
  primary key (auth_user_id, rol_id)
);

create table if not exists public.rol_permiso (
  rol_id uuid not null references public.rol(id) on delete cascade,
  permiso_id uuid not null references public.permiso(id) on delete cascade,
  primary key (rol_id, permiso_id)
);

-- ---------------------------------------------------------------------
-- ESTRUCTURA ACADÉMICA
-- ---------------------------------------------------------------------
create table if not exists public.carrera (
  id uuid primary key default gen_random_uuid(),
  institucion_id uuid not null references public.institucion(id) on delete restrict,
  departamento_id uuid references public.departamento_academico(id) on delete set null,
  nombre text not null,
  siglas text not null,
  duracion_semestres smallint not null,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_carrera_siglas unique (institucion_id, siglas),
  constraint ck_carrera_duracion check (duracion_semestres between 1 and 20)
);

create table if not exists public.plan_estudios (
  id uuid primary key default gen_random_uuid(),
  carrera_id uuid not null references public.carrera(id) on delete restrict,
  nombre text not null,
  version text not null,
  fecha_inicio_vigencia date not null,
  fecha_fin_vigencia date,
  creditos_totales numeric(8,2) not null default 0,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_plan_version unique (carrera_id, version),
  constraint ck_plan_fechas check (
    fecha_fin_vigencia is null or fecha_fin_vigencia >= fecha_inicio_vigencia
  ),
  constraint ck_plan_creditos check (creditos_totales >= 0)
);

create table if not exists public.materia (
  id uuid primary key default gen_random_uuid(),
  institucion_id uuid not null references public.institucion(id) on delete restrict,
  clave text not null,
  nombre text not null,
  creditos numeric(6,2) not null default 0,
  horas_teoricas smallint not null default 0,
  horas_practicas smallint not null default 0,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_materia_clave unique (institucion_id, clave),
  constraint ck_materia_creditos check (creditos >= 0),
  constraint ck_materia_horas check (horas_teoricas >= 0 and horas_practicas >= 0)
);

create table if not exists public.plan_materia (
  id uuid primary key default gen_random_uuid(),
  plan_estudios_id uuid not null references public.plan_estudios(id) on delete cascade,
  materia_id uuid not null references public.materia(id) on delete restrict,
  semestre_sugerido smallint not null,
  es_obligatoria boolean not null default true,
  creditos_plan numeric(6,2),
  created_at timestamptz not null default now(),
  constraint uq_plan_materia unique (plan_estudios_id, materia_id),
  constraint ck_plan_materia_semestre check (semestre_sugerido between 1 and 20),
  constraint ck_plan_materia_creditos check (creditos_plan is null or creditos_plan >= 0)
);

create table if not exists public.materia_prerrequisito (
  plan_materia_id uuid not null references public.plan_materia(id) on delete cascade,
  prerrequisito_plan_materia_id uuid not null references public.plan_materia(id) on delete cascade,
  tipo_requisito text not null default 'OBLIGATORIO',
  primary key (plan_materia_id, prerrequisito_plan_materia_id),
  constraint ck_prerrequisito_distinto check (plan_materia_id <> prerrequisito_plan_materia_id)
);

create table if not exists public.periodo_escolar (
  id uuid primary key default gen_random_uuid(),
  institucion_id uuid not null references public.institucion(id) on delete restrict,
  nombre text not null,
  fecha_inicio date not null,
  fecha_fin date not null,
  fecha_inicio_inscripcion timestamptz,
  fecha_fin_inscripcion timestamptz,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_periodo_nombre unique (institucion_id, nombre),
  constraint ck_periodo_fechas check (fecha_fin >= fecha_inicio),
  constraint ck_periodo_inscripcion check (
    fecha_inicio_inscripcion is null or fecha_fin_inscripcion is null
    or fecha_fin_inscripcion >= fecha_inicio_inscripcion
  )
);

create table if not exists public.grupo (
  id uuid primary key default gen_random_uuid(),
  periodo_escolar_id uuid not null references public.periodo_escolar(id) on delete restrict,
  carrera_id uuid not null references public.carrera(id) on delete restrict,
  nombre text not null,
  semestre smallint not null,
  turno text,
  cupo_maximo integer not null default 40,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_grupo unique (periodo_escolar_id, carrera_id, nombre),
  constraint ck_grupo_semestre check (semestre between 1 and 20),
  constraint ck_grupo_cupo check (cupo_maximo > 0)
);

create table if not exists public.salon (
  id uuid primary key default gen_random_uuid(),
  institucion_id uuid not null references public.institucion(id) on delete restrict,
  nombre text not null,
  edificio text,
  capacidad integer,
  latitud numeric(10,7),
  longitud numeric(10,7),
  radio_asistencia_metros integer not null default 100,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_salon unique (institucion_id, nombre),
  constraint ck_salon_capacidad check (capacidad is null or capacidad > 0),
  constraint ck_salon_latitud check (latitud is null or latitud between -90 and 90),
  constraint ck_salon_longitud check (longitud is null or longitud between -180 and 180),
  constraint ck_salon_radio check (radio_asistencia_metros between 1 and 5000)
);

-- ---------------------------------------------------------------------
-- ESPECIALIZACIONES DE PERSONA
-- ---------------------------------------------------------------------
create table if not exists public.alumno (
  id uuid primary key default gen_random_uuid(),
  persona_id uuid not null unique references public.persona(id) on delete cascade,
  matricula text not null,
  carrera_id uuid not null references public.carrera(id) on delete restrict,
  plan_estudios_id uuid references public.plan_estudios(id) on delete restrict,
  fecha_ingreso date not null,
  semestre_actual smallint,
  estatus_academico text not null default 'ACTIVO',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_alumno_matricula unique (matricula),
  constraint ck_alumno_semestre check (semestre_actual is null or semestre_actual between 1 and 20)
);

create table if not exists public.maestro (
  id uuid primary key default gen_random_uuid(),
  persona_id uuid not null unique references public.persona(id) on delete cascade,
  numero_empleado text not null unique,
  departamento_id uuid references public.departamento_academico(id) on delete set null,
  fecha_ingreso date,
  estatus_laboral text not null default 'ACTIVO',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.personal_administrativo (
  id uuid primary key default gen_random_uuid(),
  persona_id uuid not null unique references public.persona(id) on delete cascade,
  numero_empleado text unique,
  area_id uuid references public.area_administrativa(id) on delete set null,
  cargo text not null,
  estatus_laboral text not null default 'ACTIVO',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- OFERTA ACADÉMICA E INSCRIPCIÓN
-- ---------------------------------------------------------------------
create table if not exists public.curso (
  id uuid primary key default gen_random_uuid(),
  periodo_escolar_id uuid not null references public.periodo_escolar(id) on delete restrict,
  plan_materia_id uuid not null references public.plan_materia(id) on delete restrict,
  grupo_id uuid not null references public.grupo(id) on delete restrict,
  maestro_id uuid references public.maestro(id) on delete set null,
  cupo_maximo integer not null default 40,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_curso unique (periodo_escolar_id, plan_materia_id, grupo_id),
  constraint ck_curso_cupo check (cupo_maximo > 0)
);

create table if not exists public.horario_curso (
  id uuid primary key default gen_random_uuid(),
  curso_id uuid not null references public.curso(id) on delete cascade,
  salon_id uuid not null references public.salon(id) on delete restrict,
  dia_semana smallint not null,
  hora_inicio time not null,
  hora_fin time not null,
  created_at timestamptz not null default now(),
  constraint uq_horario_curso unique (curso_id, dia_semana, hora_inicio),
  constraint ck_horario_dia check (dia_semana between 1 and 7),
  constraint ck_horario_horas check (hora_fin > hora_inicio)
);

create table if not exists public.inscripcion (
  id uuid primary key default gen_random_uuid(),
  alumno_id uuid not null references public.alumno(id) on delete restrict,
  periodo_escolar_id uuid not null references public.periodo_escolar(id) on delete restrict,
  plan_estudios_id uuid not null references public.plan_estudios(id) on delete restrict,
  estado public.estado_inscripcion not null default 'BORRADOR',
  fecha_solicitud timestamptz not null default now(),
  fecha_confirmacion timestamptz,
  validado_por uuid references auth.users(id) on delete set null,
  observaciones text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_inscripcion unique (alumno_id, periodo_escolar_id)
);

create table if not exists public.inscripcion_curso (
  id uuid primary key default gen_random_uuid(),
  inscripcion_id uuid not null references public.inscripcion(id) on delete cascade,
  curso_id uuid not null references public.curso(id) on delete restrict,
  fecha_registro timestamptz not null default now(),
  estado text not null default 'INSCRITO',
  calificacion_final numeric(5,2),
  resultado text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_inscripcion_curso unique (inscripcion_id, curso_id),
  constraint ck_calificacion_final check (
    calificacion_final is null or calificacion_final between 0 and 100
  )
);

-- ---------------------------------------------------------------------
-- PAGOS Y DOCUMENTOS DE INSCRIPCIÓN
-- ---------------------------------------------------------------------
create table if not exists public.archivo (
  id uuid primary key default gen_random_uuid(),
  institucion_id uuid not null references public.institucion(id) on delete restrict,
  storage_bucket text not null,
  storage_path text not null,
  nombre_original text not null,
  tipo_mime text,
  extension text,
  tamanio_bytes bigint,
  sha256 text,
  cargado_por uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint uq_archivo_storage unique (storage_bucket, storage_path),
  constraint ck_archivo_tamano check (tamanio_bytes is null or tamanio_bytes >= 0)
);

create table if not exists public.pago (
  id uuid primary key default gen_random_uuid(),
  inscripcion_id uuid not null references public.inscripcion(id) on delete cascade,
  concepto text not null,
  monto numeric(12,2) not null,
  referencia text,
  fecha_pago_declarada date,
  comprobante_archivo_id uuid references public.archivo(id) on delete set null,
  estado public.estado_pago not null default 'PENDIENTE',
  validado_por uuid references auth.users(id) on delete set null,
  fecha_validacion timestamptz,
  motivo_rechazo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ck_pago_monto check (monto >= 0)
);

create table if not exists public.requisito_inscripcion (
  id uuid primary key default gen_random_uuid(),
  periodo_escolar_id uuid not null references public.periodo_escolar(id) on delete cascade,
  nombre_documento text not null,
  obligatorio boolean not null default true,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  constraint uq_requisito_inscripcion unique (periodo_escolar_id, nombre_documento)
);

create table if not exists public.documento_inscripcion_alumno (
  id uuid primary key default gen_random_uuid(),
  inscripcion_id uuid not null references public.inscripcion(id) on delete cascade,
  requisito_inscripcion_id uuid not null references public.requisito_inscripcion(id) on delete restrict,
  fecha_entrega timestamptz,
  recibido_por uuid references auth.users(id) on delete set null,
  estado text not null default 'PENDIENTE',
  observaciones text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_documento_inscripcion unique (inscripcion_id, requisito_inscripcion_id)
);

-- ---------------------------------------------------------------------
-- EVALUACIONES, ACTIVIDADES Y ENTREGAS
-- ---------------------------------------------------------------------
create table if not exists public.periodo_evaluacion (
  id uuid primary key default gen_random_uuid(),
  periodo_escolar_id uuid not null references public.periodo_escolar(id) on delete cascade,
  nombre text not null,
  numero smallint not null,
  fecha_inicio date not null,
  fecha_fin date not null,
  fecha_limite_calificaciones timestamptz not null,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_periodo_evaluacion unique (periodo_escolar_id, numero),
  constraint ck_evaluacion_numero check (numero > 0),
  constraint ck_evaluacion_fechas check (fecha_fin >= fecha_inicio)
);

create table if not exists public.rubro_evaluacion (
  id uuid primary key default gen_random_uuid(),
  curso_id uuid not null references public.curso(id) on delete cascade,
  periodo_evaluacion_id uuid not null references public.periodo_evaluacion(id) on delete cascade,
  nombre text not null,
  porcentaje numeric(5,2) not null,
  descripcion text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_rubro unique (curso_id, periodo_evaluacion_id, nombre),
  constraint ck_rubro_porcentaje check (porcentaje > 0 and porcentaje <= 100)
);

create table if not exists public.tipo_actividad (
  id uuid primary key default gen_random_uuid(),
  nombre text not null unique,
  descripcion text,
  activo boolean not null default true
);

create table if not exists public.actividad (
  id uuid primary key default gen_random_uuid(),
  rubro_evaluacion_id uuid not null references public.rubro_evaluacion(id) on delete cascade,
  tipo_actividad_id uuid not null references public.tipo_actividad(id) on delete restrict,
  nombre text not null,
  descripcion text,
  fecha_publicacion timestamptz not null default now(),
  fecha_limite timestamptz not null,
  puntaje_maximo numeric(7,2) not null default 100,
  permite_entrega_tardia boolean not null default false,
  numero_intentos smallint not null default 1,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ck_actividad_puntaje check (puntaje_maximo > 0),
  constraint ck_actividad_intentos check (numero_intentos > 0)
);

create table if not exists public.entrega_actividad (
  id uuid primary key default gen_random_uuid(),
  actividad_id uuid not null references public.actividad(id) on delete cascade,
  inscripcion_curso_id uuid not null references public.inscripcion_curso(id) on delete cascade,
  numero_intento smallint not null default 1,
  fecha_entrega timestamptz not null default now(),
  estado public.estado_entrega not null default 'ENTREGADA_A_TIEMPO',
  comentario_alumno text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_entrega_intento unique (actividad_id, inscripcion_curso_id, numero_intento),
  constraint ck_entrega_intento check (numero_intento > 0)
);

create table if not exists public.entrega_archivo (
  entrega_actividad_id uuid not null references public.entrega_actividad(id) on delete cascade,
  archivo_id uuid not null references public.archivo(id) on delete cascade,
  primary key (entrega_actividad_id, archivo_id)
);

create table if not exists public.calificacion_entrega (
  id uuid primary key default gen_random_uuid(),
  entrega_actividad_id uuid not null unique references public.entrega_actividad(id) on delete cascade,
  calificacion numeric(7,2) not null,
  retroalimentacion text,
  calificado_por uuid not null references auth.users(id) on delete restrict,
  fecha_calificacion timestamptz not null default now(),
  estado text not null default 'PUBLICADA',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ck_calificacion_entrega check (calificacion >= 0)
);

create table if not exists public.calificacion_parcial (
  id uuid primary key default gen_random_uuid(),
  inscripcion_curso_id uuid not null references public.inscripcion_curso(id) on delete cascade,
  periodo_evaluacion_id uuid not null references public.periodo_evaluacion(id) on delete cascade,
  calificacion_calculada numeric(5,2),
  calificacion_publicada numeric(5,2),
  fecha_publicacion timestamptz,
  publicado_por uuid references auth.users(id) on delete set null,
  estado text not null default 'BORRADOR',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_calificacion_parcial unique (inscripcion_curso_id, periodo_evaluacion_id),
  constraint ck_calificacion_calculada check (
    calificacion_calculada is null or calificacion_calculada between 0 and 100
  ),
  constraint ck_calificacion_publicada check (
    calificacion_publicada is null or calificacion_publicada between 0 and 100
  )
);

create table if not exists public.historial_calificacion (
  id uuid primary key default gen_random_uuid(),
  inscripcion_curso_id uuid not null references public.inscripcion_curso(id) on delete restrict,
  periodo_evaluacion_id uuid references public.periodo_evaluacion(id) on delete restrict,
  calificacion_anterior numeric(5,2),
  calificacion_nueva numeric(5,2) not null,
  motivo text not null,
  modificado_por uuid references auth.users(id) on delete set null,
  direccion_ip inet,
  created_at timestamptz not null default now(),
  constraint ck_historial_calificacion_nueva check (calificacion_nueva between 0 and 100)
);

-- ---------------------------------------------------------------------
-- ASISTENCIA ACADÉMICA
-- ---------------------------------------------------------------------
create table if not exists public.sesion_clase (
  id uuid primary key default gen_random_uuid(),
  curso_id uuid not null references public.curso(id) on delete cascade,
  salon_id uuid references public.salon(id) on delete set null,
  fecha date not null,
  hora_inicio time not null,
  hora_fin time not null,
  asistencia_abierta_desde timestamptz,
  asistencia_abierta_hasta timestamptz,
  latitud numeric(10,7),
  longitud numeric(10,7),
  radio_metros integer not null default 100,
  estado text not null default 'PROGRAMADA',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_sesion_clase unique (curso_id, fecha, hora_inicio),
  constraint ck_sesion_horas check (hora_fin > hora_inicio),
  constraint ck_sesion_ventana check (
    asistencia_abierta_desde is null or asistencia_abierta_hasta is null
    or asistencia_abierta_hasta >= asistencia_abierta_desde
  ),
  constraint ck_sesion_latitud check (latitud is null or latitud between -90 and 90),
  constraint ck_sesion_longitud check (longitud is null or longitud between -180 and 180),
  constraint ck_sesion_radio check (radio_metros between 1 and 5000)
);

create table if not exists public.asistencia (
  id uuid primary key default gen_random_uuid(),
  sesion_clase_id uuid not null references public.sesion_clase(id) on delete cascade,
  inscripcion_curso_id uuid not null references public.inscripcion_curso(id) on delete cascade,
  estado public.estado_asistencia not null default 'PENDIENTE',
  metodo public.metodo_asistencia not null,
  fecha_hora_registro timestamptz not null default now(),
  latitud_registro numeric(10,7),
  longitud_registro numeric(10,7),
  distancia_metros numeric(10,2),
  validacion_biometrica boolean not null default false,
  validada_por_maestro boolean not null default false,
  observaciones text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_asistencia unique (sesion_clase_id, inscripcion_curso_id),
  constraint ck_asistencia_latitud check (
    latitud_registro is null or latitud_registro between -90 and 90
  ),
  constraint ck_asistencia_longitud check (
    longitud_registro is null or longitud_registro between -180 and 180
  ),
  constraint ck_asistencia_distancia check (distancia_metros is null or distancia_metros >= 0)
);

create table if not exists public.asistencia_historial (
  id uuid primary key default gen_random_uuid(),
  asistencia_id uuid not null references public.asistencia(id) on delete cascade,
  estado_anterior public.estado_asistencia,
  estado_nuevo public.estado_asistencia not null,
  motivo text not null,
  modificado_por uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- BIOMETRÍA Y CONSENTIMIENTO
-- ---------------------------------------------------------------------
create table if not exists public.perfil_biometrico (
  id uuid primary key default gen_random_uuid(),
  persona_id uuid not null unique references public.persona(id) on delete cascade,
  embedding_cifrado bytea,
  embedding_storage_path text,
  algoritmo text not null,
  version_modelo text not null,
  dimension_embedding integer,
  nivel_calidad numeric(5,2),
  activo boolean not null default true,
  fecha_registro timestamptz not null default now(),
  fecha_actualizacion timestamptz not null default now(),
  constraint ck_embedding_dimension check (
    dimension_embedding is null or dimension_embedding > 0
  ),
  constraint ck_embedding_calidad check (
    nivel_calidad is null or nivel_calidad between 0 and 100
  ),
  constraint ck_embedding_fuente check (
    embedding_cifrado is not null or embedding_storage_path is not null
  )
);

create table if not exists public.consentimiento_biometrico (
  id uuid primary key default gen_random_uuid(),
  persona_id uuid not null references public.persona(id) on delete cascade,
  version_aviso text not null,
  aceptado boolean not null,
  fecha_respuesta timestamptz not null default now(),
  direccion_ip inet,
  evidencia_archivo_id uuid references public.archivo(id) on delete set null,
  constraint uq_consentimiento_version unique (persona_id, version_aviso)
);

-- ---------------------------------------------------------------------
-- ACCESO FÍSICO
-- ---------------------------------------------------------------------
create table if not exists public.punto_acceso (
  id uuid primary key default gen_random_uuid(),
  institucion_id uuid not null references public.institucion(id) on delete restrict,
  nombre text not null,
  tipo text not null,
  permite_entrada boolean not null default true,
  permite_salida boolean not null default true,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_punto_acceso unique (institucion_id, nombre)
);

create table if not exists public.dispositivo_acceso (
  id uuid primary key default gen_random_uuid(),
  institucion_id uuid not null references public.institucion(id) on delete restrict,
  auth_user_id uuid unique references auth.users(id) on delete set null,
  nombre text not null,
  numero_serie text not null unique,
  tipo_dispositivo text not null,
  ubicacion text,
  estado text not null default 'ACTIVO',
  ultima_conexion timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.punto_dispositivo (
  punto_acceso_id uuid not null references public.punto_acceso(id) on delete cascade,
  dispositivo_acceso_id uuid not null references public.dispositivo_acceso(id) on delete cascade,
  primary key (punto_acceso_id, dispositivo_acceso_id)
);

create table if not exists public.evento_acceso (
  id uuid primary key default gen_random_uuid(),
  persona_id uuid references public.persona(id) on delete set null,
  punto_acceso_id uuid not null references public.punto_acceso(id) on delete restrict,
  dispositivo_acceso_id uuid not null references public.dispositivo_acceso(id) on delete restrict,
  fecha_hora timestamptz not null default now(),
  tipo_movimiento public.tipo_movimiento not null,
  metodo_validacion text not null,
  resultado public.resultado_acceso not null,
  nivel_confianza numeric(6,5),
  motivo_denegacion text,
  modo_sin_conexion boolean not null default false,
  metadatos jsonb not null default '{}'::jsonb,
  constraint ck_acceso_confianza check (
    nivel_confianza is null or nivel_confianza between 0 and 1
  )
);

create table if not exists public.codigo_acceso_temporal (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null references auth.users(id) on delete cascade,
  hash_codigo text not null,
  tipo_codigo text not null,
  fecha_generacion timestamptz not null default now(),
  fecha_expiracion timestamptz not null,
  fecha_uso timestamptz,
  estado text not null default 'ACTIVO',
  generado_por uuid references auth.users(id) on delete set null,
  constraint ck_codigo_expiracion check (fecha_expiracion > fecha_generacion)
);

-- ---------------------------------------------------------------------
-- CRÉDITOS COMPLEMENTARIOS
-- ---------------------------------------------------------------------
create table if not exists public.tipo_credito (
  id uuid primary key default gen_random_uuid(),
  institucion_id uuid not null references public.institucion(id) on delete restrict,
  nombre text not null,
  descripcion text,
  cantidad_requerida numeric(10,2),
  unidad_medida text not null default 'CREDITOS',
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  constraint uq_tipo_credito unique (institucion_id, nombre),
  constraint ck_credito_requerido check (
    cantidad_requerida is null or cantidad_requerida >= 0
  )
);

create table if not exists public.credito_alumno (
  id uuid primary key default gen_random_uuid(),
  alumno_id uuid not null references public.alumno(id) on delete cascade,
  tipo_credito_id uuid not null references public.tipo_credito(id) on delete restrict,
  cantidad numeric(10,2) not null,
  fecha_obtencion date not null,
  institucion_emisora text,
  descripcion text,
  evidencia_archivo_id uuid references public.archivo(id) on delete set null,
  validado_por uuid references auth.users(id) on delete set null,
  fecha_validacion timestamptz,
  estado text not null default 'PENDIENTE',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ck_credito_cantidad check (cantidad > 0)
);

-- ---------------------------------------------------------------------
-- TRÁMITES Y DOCUMENTOS
-- ---------------------------------------------------------------------
create table if not exists public.tipo_documento (
  id uuid primary key default gen_random_uuid(),
  institucion_id uuid not null references public.institucion(id) on delete restrict,
  nombre text not null,
  descripcion text,
  tiene_costo boolean not null default false,
  costo numeric(12,2) not null default 0,
  dias_estimados integer,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  constraint uq_tipo_documento unique (institucion_id, nombre),
  constraint ck_documento_costo check (costo >= 0),
  constraint ck_documento_dias check (dias_estimados is null or dias_estimados >= 0)
);

create table if not exists public.solicitud_documento (
  id uuid primary key default gen_random_uuid(),
  alumno_id uuid not null references public.alumno(id) on delete restrict,
  tipo_documento_id uuid not null references public.tipo_documento(id) on delete restrict,
  fecha_solicitud timestamptz not null default now(),
  estado public.estado_solicitud not null default 'SOLICITADA',
  observaciones text,
  atendido_por uuid references auth.users(id) on delete set null,
  fecha_respuesta timestamptz,
  archivo_resultado_id uuid references public.archivo(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- VEHÍCULOS Y PASES
-- ---------------------------------------------------------------------
create table if not exists public.tipo_vehiculo (
  id uuid primary key default gen_random_uuid(),
  nombre text not null unique,
  descripcion text,
  activo boolean not null default true
);

create table if not exists public.vehiculo (
  id uuid primary key default gen_random_uuid(),
  institucion_id uuid not null references public.institucion(id) on delete restrict,
  persona_responsable_id uuid not null references public.persona(id) on delete restrict,
  tipo_vehiculo_id uuid not null references public.tipo_vehiculo(id) on delete restrict,
  placas text not null,
  marca text,
  modelo text,
  color text,
  anio smallint,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_vehiculo_placas unique (institucion_id, placas),
  constraint ck_vehiculo_anio check (anio is null or anio between 1900 and 2200)
);

create table if not exists public.pase_vehicular (
  id uuid primary key default gen_random_uuid(),
  vehiculo_id uuid not null references public.vehiculo(id) on delete cascade,
  fecha_inicio date not null,
  fecha_fin date not null,
  estado public.estado_pase not null default 'PENDIENTE',
  autorizado_por uuid references auth.users(id) on delete set null,
  fecha_autorizacion timestamptz,
  motivo_revocacion text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ck_pase_fechas check (fecha_fin >= fecha_inicio)
);

create table if not exists public.evento_acceso_vehicular (
  id uuid primary key default gen_random_uuid(),
  pase_vehicular_id uuid not null references public.pase_vehicular(id) on delete restrict,
  punto_acceso_id uuid not null references public.punto_acceso(id) on delete restrict,
  dispositivo_acceso_id uuid references public.dispositivo_acceso(id) on delete set null,
  tipo_movimiento public.tipo_movimiento not null,
  fecha_hora timestamptz not null default now(),
  resultado public.resultado_acceso not null,
  observaciones text
);

-- ---------------------------------------------------------------------
-- NOTIFICACIONES
-- ---------------------------------------------------------------------
create table if not exists public.notificacion (
  id uuid primary key default gen_random_uuid(),
  institucion_id uuid not null references public.institucion(id) on delete restrict,
  titulo text not null,
  mensaje text not null,
  tipo text not null,
  creado_por uuid references auth.users(id) on delete set null,
  fecha_creacion timestamptz not null default now(),
  fecha_expiracion timestamptz,
  metadatos jsonb not null default '{}'::jsonb
);

create table if not exists public.notificacion_destinatario (
  notificacion_id uuid not null references public.notificacion(id) on delete cascade,
  auth_user_id uuid not null references auth.users(id) on delete cascade,
  fecha_envio timestamptz,
  fecha_lectura timestamptz,
  estado_envio text not null default 'PENDIENTE',
  primary key (notificacion_id, auth_user_id)
);

-- ---------------------------------------------------------------------
-- SUSPENSIONES Y AUDITORÍA
-- ---------------------------------------------------------------------
create table if not exists public.suspension_sistema (
  id uuid primary key default gen_random_uuid(),
  institucion_id uuid not null references public.institucion(id) on delete restrict,
  fecha_inicio timestamptz not null,
  fecha_fin timestamptz,
  motivo text not null,
  alcance text not null,
  creada_por uuid references auth.users(id) on delete set null,
  estado text not null default 'PROGRAMADA',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ck_suspension_fechas check (
    fecha_fin is null or fecha_fin >= fecha_inicio
  )
);

create table if not exists public.auditoria (
  id bigint generated always as identity primary key,
  institucion_id uuid references public.institucion(id) on delete set null,
  auth_user_id uuid references auth.users(id) on delete set null,
  entidad text not null,
  registro_id text,
  operacion public.operacion_auditoria not null,
  valor_anterior jsonb,
  valor_nuevo jsonb,
  motivo text,
  direccion_ip inet,
  agente_usuario text,
  created_at timestamptz not null default now()
);
