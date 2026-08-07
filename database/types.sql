-- =================================================================
--
-- Archivo: 02_types.sql
-- Descripción: Define todos los tipos enumerados (ENUM)
--              personalizados que se utilizan a lo largo de la
--              base de datos para estandarizar y restringir
--              los valores de ciertas columnas.
--
-- =================================================================

do $$ begin
  create type public.estado_general as enum ('ACTIVO','INACTIVO');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.estado_cuenta as enum (
    'PENDIENTE_ACTIVACION',
    'CONTRASENA_TEMPORAL',
    'ACTIVA',
    'BLOQUEADA',
    'SUSPENDIDA',
    'INACTIVA',
    'REVOCADA'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.estado_inscripcion as enum (
    'BORRADOR',
    'PAGO_PENDIENTE',
    'PAGO_EN_REVISION',
    'PAGO_RECHAZADO',
    'DOCUMENTOS_FISICOS_PENDIENTes',
    'EN_VALIDACION',
    'CONFIRMADA',
    'RECHAZADA',
    'CANCELADA'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.estado_entrega as enum (
    'NO_ENTREGADA',
    'ENTREGADA_A_TIEMPO',
    'ENTREGADA_EXTEMPORANEA',
    'EN_REVISION',
    'CALIFICADA',
    'REQUIERE_CORRECCION',
    'ANULADA'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.estado_asistencia as enum (
    'PENDIENTE',
    'PRESENTE',
    'RETARDO',
    'FALTA',
    'JUSTIFICADA',
    'RECHAZADA_UBICACION',
    'RECHAZADA_HORARIO',
    'MODIFICADA_MANUALMENTE'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.metodo_asistencia as enum (
    'BIOMETRIA_DISPOSITIVO',
    'FACIAL_KIOSCO',
    'QR',
    'PIN',
    'MANUAL'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.tipo_movimiento as enum ('ENTRADA','SALIDA');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.resultado_acceso as enum (
    'PERMITIDO',
    'DENEGADO',
    'NO_IDENTIFICADO',
    'ERROR'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.estado_pago as enum (
    'PENDIENTE',
    'EN_REVISION',
    'APROBADO',
    'RECHAZADO',
    'REQUIERE_ACLARACION'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.estado_pase as enum (
    'PENDIENTE',
    'ACTIVO',
    'SUSPENDIDO',
    'VENCIDO',
    'REVOCADO'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.estado_solicitud as enum (
    'SOLICITADA',
    'EN_REVISION',
    'APROBADA',
    'RECHAZADA',
    'LISTA',
    'ENTREGADA',
    'CANCELADA'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.operacion_auditoria as enum (
    'INSERT',
    'UPDATE',
    'DELETE',
    'LOGIN',
    'LOGOUT',
    'APROBACION',
    'RECHAZO',
    'SUSPENSION',
    'REACTIVACION'
  );
exception when duplicate_object then null; end $$;
