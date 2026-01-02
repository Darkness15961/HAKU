-- ============================================
-- HAKU - Sistema de Solicitudes de Rutas
-- Archivo 1: Crear Tablas
-- ============================================

-- ============================================
-- 1. TABLA: solicitudes_rutas
-- ============================================

CREATE TABLE IF NOT EXISTS public.solicitudes_rutas (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  turista_id uuid NOT NULL,
  titulo text NOT NULL,
  descripcion text NOT NULL,
  lugares_ids bigint[] NOT NULL,
  fecha_deseada timestamp with time zone NOT NULL,
  numero_personas integer NOT NULL DEFAULT 1,
  presupuesto_maximo numeric(10,2),
  
  -- Estados: 'buscando_guia', 'guia_asignado', 'cancelada', 'completada'
  estado text NOT NULL DEFAULT 'buscando_guia',
  
  -- Relaciones cuando se acepta una postulación
  guia_asignado_id uuid,
  postulacion_aceptada_id bigint,
  ruta_creada_id bigint,
  
  -- Privacidad
  preferencia_privacidad text DEFAULT 'publica',
  grupo_objetivo text,
  
  -- Metadata
  fecha_creacion timestamp with time zone NOT NULL DEFAULT now(),
  fecha_cancelacion timestamp with time zone,
  motivo_cancelacion text,
  
  -- Referencias opcionales
  enlace_video_referencia text,
  notas_adicionales text,
  
  -- Contadores
  numero_postulaciones integer DEFAULT 0,
  
  CONSTRAINT solicitudes_rutas_pkey PRIMARY KEY (id),
  CONSTRAINT solicitudes_rutas_turista_id_fkey FOREIGN KEY (turista_id) 
    REFERENCES public.perfiles(id) ON DELETE CASCADE,
  CONSTRAINT solicitudes_rutas_guia_asignado_id_fkey FOREIGN KEY (guia_asignado_id) 
    REFERENCES public.perfiles(id),
  CONSTRAINT solicitudes_rutas_ruta_creada_id_fkey FOREIGN KEY (ruta_creada_id) 
    REFERENCES public.rutas(id),
    
  -- Validaciones
  CONSTRAINT check_estado_solicitud CHECK (
    estado IN ('buscando_guia', 'guia_asignado', 'cancelada', 'completada')
  ),
  CONSTRAINT check_fecha_futura CHECK (fecha_deseada > now()),
  CONSTRAINT check_numero_personas CHECK (numero_personas > 0),
  CONSTRAINT check_presupuesto CHECK (presupuesto_maximo IS NULL OR presupuesto_maximo > 0),
  CONSTRAINT check_preferencia_privacidad CHECK (preferencia_privacidad IN ('publica', 'privada'))
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_solicitudes_turista ON public.solicitudes_rutas(turista_id);
CREATE INDEX IF NOT EXISTS idx_solicitudes_estado ON public.solicitudes_rutas(estado);
CREATE INDEX IF NOT EXISTS idx_solicitudes_fecha ON public.solicitudes_rutas(fecha_deseada);
CREATE INDEX IF NOT EXISTS idx_solicitudes_guia ON public.solicitudes_rutas(guia_asignado_id);

-- Comentarios
COMMENT ON TABLE public.solicitudes_rutas IS 'Solicitudes de rutas creadas por turistas';
COMMENT ON COLUMN public.solicitudes_rutas.lugares_ids IS 'Array de IDs de lugares a visitar';
COMMENT ON COLUMN public.solicitudes_rutas.estado IS 'buscando_guia, guia_asignado, cancelada, completada';

-- ============================================
-- 2. TABLA: postulaciones_guias
-- ============================================

CREATE TABLE IF NOT EXISTS public.postulaciones_guias (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  solicitud_id bigint NOT NULL,
  guia_id uuid NOT NULL,
  
  -- Propuesta económica
  precio_ofertado numeric(10,2) NOT NULL,
  moneda text NOT NULL DEFAULT 'PEN',
  
  -- Detalles de la propuesta
  descripcion_propuesta text NOT NULL,
  itinerario_detallado text,
  servicios_incluidos text[],
  
  -- Estado: 'pendiente', 'aceptada', 'rechazada'
  estado text NOT NULL DEFAULT 'pendiente',
  
  -- Metadata
  fecha_postulacion timestamp with time zone NOT NULL DEFAULT now(),
  fecha_respuesta timestamp with time zone,
  
  CONSTRAINT postulaciones_guias_pkey PRIMARY KEY (id),
  CONSTRAINT postulaciones_guias_solicitud_id_fkey FOREIGN KEY (solicitud_id) 
    REFERENCES public.solicitudes_rutas(id) ON DELETE CASCADE,
  CONSTRAINT postulaciones_guias_guia_id_fkey FOREIGN KEY (guia_id) 
    REFERENCES public.perfiles(id) ON DELETE CASCADE,
    
  -- Validaciones
  CONSTRAINT check_estado_postulacion CHECK (
    estado IN ('pendiente', 'aceptada', 'rechazada')
  ),
  CONSTRAINT check_precio_positivo CHECK (precio_ofertado > 0),
  CONSTRAINT check_moneda CHECK (moneda IN ('PEN', 'USD')),
  
  -- Un guía solo puede postular una vez por solicitud
  CONSTRAINT unique_guia_solicitud UNIQUE(solicitud_id, guia_id)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_postulaciones_solicitud ON public.postulaciones_guias(solicitud_id);
CREATE INDEX IF NOT EXISTS idx_postulaciones_guia ON public.postulaciones_guias(guia_id);
CREATE INDEX IF NOT EXISTS idx_postulaciones_estado ON public.postulaciones_guias(estado);

-- Comentarios
COMMENT ON TABLE public.postulaciones_guias IS 'Propuestas de guías para solicitudes de rutas';

-- ============================================
-- 3. TABLA: intentos_acceso_ruta
-- ============================================

CREATE TABLE IF NOT EXISTS public.intentos_acceso_ruta (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  ruta_id bigint NOT NULL,
  usuario_id uuid,
  codigo_ingresado text NOT NULL,
  exitoso boolean NOT NULL,
  ip_address inet,
  fecha_intento timestamp with time zone NOT NULL DEFAULT now(),
  
  CONSTRAINT intentos_acceso_ruta_pkey PRIMARY KEY (id),
  CONSTRAINT intentos_acceso_ruta_ruta_id_fkey 
    FOREIGN KEY (ruta_id) REFERENCES public.rutas(id) ON DELETE CASCADE,
  CONSTRAINT intentos_acceso_ruta_usuario_id_fkey 
    FOREIGN KEY (usuario_id) REFERENCES public.perfiles(id)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_intentos_acceso_ruta ON public.intentos_acceso_ruta(ruta_id);
CREATE INDEX IF NOT EXISTS idx_intentos_acceso_usuario ON public.intentos_acceso_ruta(usuario_id);

COMMENT ON TABLE public.intentos_acceso_ruta IS 'Registro de intentos de acceso a rutas privadas';
