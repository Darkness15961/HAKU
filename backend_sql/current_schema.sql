-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.categorias (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  nombre text NOT NULL,
  url_imagen text,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  descripcion text,
  CONSTRAINT categorias_pkey PRIMARY KEY (id)
);
CREATE TABLE public.empresas_aliadas (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  ruc character varying NOT NULL UNIQUE,
  razon_social text NOT NULL,
  nombre_comercial text,
  categoria text NOT NULL,
  descripcion text,
  telefono character varying,
  email text,
  sitio_web text,
  direccion text,
  logo_url text,
  latitud double precision,
  longitud double precision,
  verificada boolean DEFAULT false,
  fecha_verificacion timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone DEFAULT now(),
  created_by uuid,
  CONSTRAINT empresas_aliadas_pkey PRIMARY KEY (id),
  CONSTRAINT empresas_aliadas_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.perfiles(id)
);
CREATE TABLE public.favoritos (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  usuario_id uuid,
  lugar_id bigint,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT favoritos_pkey PRIMARY KEY (id),
  CONSTRAINT favoritos_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.perfiles(id),
  CONSTRAINT favoritos_lugar_id_fkey FOREIGN KEY (lugar_id) REFERENCES public.lugares(id)
);
CREATE TABLE public.hakuparadas (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  nombre text NOT NULL,
  descripcion text NOT NULL,
  foto_referencia text NOT NULL,
  latitud double precision NOT NULL,
  longitud double precision NOT NULL,
  categoria text NOT NULL,
  provincia_id bigint NOT NULL,
  lugar_id bigint,
  publicado_por uuid,
  verificado boolean DEFAULT false,
  verificado_por uuid,
  fecha_verificacion timestamp with time zone,
  visible boolean DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT hakuparadas_pkey PRIMARY KEY (id),
  CONSTRAINT hakuparadas_provincia_id_fkey FOREIGN KEY (provincia_id) REFERENCES public.provincias(id),
  CONSTRAINT hakuparadas_lugar_id_fkey FOREIGN KEY (lugar_id) REFERENCES public.lugares(id),
  CONSTRAINT hakuparadas_publicado_por_fkey FOREIGN KEY (publicado_por) REFERENCES public.perfiles(id),
  CONSTRAINT hakuparadas_verificado_por_fkey FOREIGN KEY (verificado_por) REFERENCES public.perfiles(id)
);
CREATE TABLE public.inscripciones (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  usuario_id uuid,
  ruta_id bigint,
  estado_pago text DEFAULT 'pendiente'::text,
  fecha_inscripcion timestamp with time zone DEFAULT now(),
  asistio boolean DEFAULT false,
  fecha_asistencia timestamp with time zone,
  CONSTRAINT inscripciones_pkey PRIMARY KEY (id),
  CONSTRAINT inscripciones_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.perfiles(id),
  CONSTRAINT inscripciones_ruta_id_fkey FOREIGN KEY (ruta_id) REFERENCES public.rutas(id)
);
CREATE TABLE public.intentos_acceso_ruta (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  ruta_id bigint NOT NULL,
  usuario_id uuid,
  codigo_ingresado text NOT NULL,
  exitoso boolean NOT NULL,
  ip_address inet,
  fecha_intento timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT intentos_acceso_ruta_pkey PRIMARY KEY (id),
  CONSTRAINT intentos_acceso_ruta_ruta_id_fkey FOREIGN KEY (ruta_id) REFERENCES public.rutas(id),
  CONSTRAINT intentos_acceso_ruta_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.perfiles(id)
);
CREATE TABLE public.lugares (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  nombre text NOT NULL,
  descripcion text,
  url_imagen text,
  video_tiktok_url text,
  latitud double precision,
  longitud double precision,
  direccion_referencia text,
  rating real DEFAULT 0.0,
  horario text,
  provincia_id bigint,
  registrado_por uuid,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  reviews_count integer DEFAULT 0,
  CONSTRAINT lugares_pkey PRIMARY KEY (id),
  CONSTRAINT lugares_provincia_id_fkey FOREIGN KEY (provincia_id) REFERENCES public.provincias(id),
  CONSTRAINT lugares_registrado_por_fkey FOREIGN KEY (registrado_por) REFERENCES public.perfiles(id)
);
CREATE TABLE public.lugares_sugeridos (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  nombre_tentativo text,
  descripcion text,
  foto_url text,
  latitud double precision,
  longitud double precision,
  usuario_id uuid,
  estado text DEFAULT 'pendiente'::text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT lugares_sugeridos_pkey PRIMARY KEY (id),
  CONSTRAINT lugares_sugeridos_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.perfiles(id)
);
CREATE TABLE public.notificaciones (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  usuario_id uuid NOT NULL,
  titulo text NOT NULL,
  cuerpo text NOT NULL,
  leido boolean DEFAULT false,
  tipo text CHECK (tipo = ANY (ARRAY['cancelacion'::text, 'confirmacion'::text, 'aviso'::text, 'sistema'::text])),
  referencia_id text,
  referencia_tipo text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT notificaciones_pkey PRIMARY KEY (id),
  CONSTRAINT notificaciones_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.perfiles(id)
);
CREATE TABLE public.perfiles (
  id uuid NOT NULL,
  seudonimo text,
  email text,
  dni text,
  url_foto_perfil text,
  rol text DEFAULT 'turista'::text,
  solicitud_estado text DEFAULT 'no_iniciado'::text,
  solicitud_experiencia text,
  solicitud_certificado_url text,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  rating double precision DEFAULT 4.5,
  empresa_id bigint,
  apellido_paterno text,
  apellido_materno text,
  nombres text,
  tipo_documento text DEFAULT 'DNI'::text,
  numero_postulaciones_aceptadas integer DEFAULT 0,
  numero_postulaciones_rechazadas integer DEFAULT 0,
  numero_postulaciones_totales integer DEFAULT 0,
  CONSTRAINT perfiles_pkey PRIMARY KEY (id),
  CONSTRAINT perfiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id),
  CONSTRAINT perfiles_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES public.empresas_aliadas(id)
);
CREATE TABLE public.postulaciones_guias (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  solicitud_id bigint NOT NULL,
  guia_id uuid NOT NULL,
  precio_ofertado numeric NOT NULL CHECK (precio_ofertado > 0::numeric),
  moneda text NOT NULL DEFAULT 'PEN'::text CHECK (moneda = ANY (ARRAY['PEN'::text, 'USD'::text])),
  descripcion_propuesta text NOT NULL,
  itinerario_detallado text,
  servicios_incluidos ARRAY,
  estado text NOT NULL DEFAULT 'pendiente'::text CHECK (estado = ANY (ARRAY['pendiente'::text, 'aceptada'::text, 'rechazada'::text])),
  fecha_postulacion timestamp with time zone NOT NULL DEFAULT now(),
  fecha_respuesta timestamp with time zone,
  CONSTRAINT postulaciones_guias_pkey PRIMARY KEY (id),
  CONSTRAINT postulaciones_guias_solicitud_id_fkey FOREIGN KEY (solicitud_id) REFERENCES public.solicitudes_rutas(id),
  CONSTRAINT postulaciones_guias_guia_id_fkey FOREIGN KEY (guia_id) REFERENCES public.perfiles(id)
);
CREATE TABLE public.provincias (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  nombre text NOT NULL,
  descripcion text,
  url_imagen text,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT provincias_pkey PRIMARY KEY (id)
);
CREATE TABLE public.recuerdos (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  usuario_id uuid NOT NULL,
  ruta_id bigint NOT NULL,
  foto_url text NOT NULL,
  comentario text,
  latitud double precision NOT NULL,
  longitud double precision NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT recuerdos_pkey PRIMARY KEY (id),
  CONSTRAINT recuerdos_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.perfiles(id),
  CONSTRAINT recuerdos_ruta_id_fkey FOREIGN KEY (ruta_id) REFERENCES public.rutas(id)
);
CREATE TABLE public.resenas (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  usuario_id uuid,
  lugar_id bigint,
  ruta_id bigint,
  calificacion integer CHECK (calificacion >= 1 AND calificacion <= 5),
  comentario text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT resenas_pkey PRIMARY KEY (id),
  CONSTRAINT resenas_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.perfiles(id),
  CONSTRAINT resenas_lugar_id_fkey FOREIGN KEY (lugar_id) REFERENCES public.lugares(id),
  CONSTRAINT resenas_ruta_id_fkey FOREIGN KEY (ruta_id) REFERENCES public.rutas(id)
);
CREATE TABLE public.ruta_detalles (
  ruta_id bigint NOT NULL,
  lugar_id bigint NOT NULL,
  orden_visita integer,
  CONSTRAINT ruta_detalles_pkey PRIMARY KEY (ruta_id, lugar_id),
  CONSTRAINT ruta_detalles_ruta_id_fkey FOREIGN KEY (ruta_id) REFERENCES public.rutas(id),
  CONSTRAINT ruta_detalles_lugar_id_fkey FOREIGN KEY (lugar_id) REFERENCES public.lugares(id)
);
CREATE TABLE public.rutas (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  titulo text NOT NULL,
  descripcion text,
  url_imagen_principal text,
  precio numeric DEFAULT 0.00,
  cupos_totales integer DEFAULT 10,
  dias integer DEFAULT 1,
  categoria text,
  enlace_grupo_whatsapp text,
  visible boolean DEFAULT true,
  estado text DEFAULT 'abierto'::text,
  guia_id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  fecha_cierre_inscripcion timestamp with time zone,
  equipamiento_ruta ARRAY,
  fecha_evento timestamp without time zone,
  punto_encuentro text,
  categoria_id bigint,
  es_privada boolean DEFAULT false,
  codigo_acceso text UNIQUE,
  fecha_generacion_codigo timestamp with time zone,
  origen_solicitud_id bigint,
  geometria_json jsonb,
  distancia_metros numeric DEFAULT 0,
  duracion_segundos numeric DEFAULT 0,
  CONSTRAINT rutas_pkey PRIMARY KEY (id),
  CONSTRAINT rutas_guia_id_fkey FOREIGN KEY (guia_id) REFERENCES public.perfiles(id),
  CONSTRAINT fk_rutas_categoria FOREIGN KEY (categoria_id) REFERENCES public.categorias(id),
  CONSTRAINT rutas_origen_solicitud_id_fkey FOREIGN KEY (origen_solicitud_id) REFERENCES public.solicitudes_rutas(id)
);
CREATE TABLE public.solicitudes_rutas (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  turista_id uuid NOT NULL,
  titulo text NOT NULL,
  descripcion text NOT NULL,
  lugares_ids ARRAY NOT NULL,
  fecha_deseada timestamp with time zone NOT NULL CHECK (fecha_deseada > now()),
  numero_personas integer NOT NULL DEFAULT 1 CHECK (numero_personas > 0),
  presupuesto_maximo numeric CHECK (presupuesto_maximo IS NULL OR presupuesto_maximo > 0::numeric),
  estado text NOT NULL DEFAULT 'buscando_guia'::text CHECK (estado = ANY (ARRAY['buscando_guia'::text, 'guia_asignado'::text, 'cancelada'::text, 'completada'::text])),
  guia_asignado_id uuid,
  postulacion_aceptada_id bigint,
  ruta_creada_id bigint,
  preferencia_privacidad text DEFAULT 'publica'::text CHECK (preferencia_privacidad = ANY (ARRAY['publica'::text, 'privada'::text])),
  grupo_objetivo text,
  fecha_creacion timestamp with time zone NOT NULL DEFAULT now(),
  fecha_cancelacion timestamp with time zone,
  motivo_cancelacion text,
  enlace_video_referencia text,
  notas_adicionales text,
  numero_postulaciones integer DEFAULT 0,
  CONSTRAINT solicitudes_rutas_pkey PRIMARY KEY (id),
  CONSTRAINT solicitudes_rutas_turista_id_fkey FOREIGN KEY (turista_id) REFERENCES public.perfiles(id),
  CONSTRAINT solicitudes_rutas_guia_asignado_id_fkey FOREIGN KEY (guia_asignado_id) REFERENCES public.perfiles(id),
  CONSTRAINT solicitudes_rutas_ruta_creada_id_fkey FOREIGN KEY (ruta_creada_id) REFERENCES public.rutas(id)
);
