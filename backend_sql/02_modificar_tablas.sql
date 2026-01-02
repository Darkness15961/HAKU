-- ============================================
-- HAKU - Sistema de Solicitudes de Rutas
-- Archivo 2: Modificar Tablas Existentes
-- ============================================

-- ============================================
-- 1. MODIFICAR TABLA: rutas
-- ============================================

-- Agregar campos para privacidad
ALTER TABLE public.rutas 
ADD COLUMN IF NOT EXISTS es_privada boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS codigo_acceso text,
ADD COLUMN IF NOT EXISTS fecha_generacion_codigo timestamp with time zone,
ADD COLUMN IF NOT EXISTS origen_solicitud_id bigint;

-- Agregar constraint único para código
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'rutas_codigo_acceso_unique'
  ) THEN
    ALTER TABLE public.rutas 
    ADD CONSTRAINT rutas_codigo_acceso_unique UNIQUE (codigo_acceso);
  END IF;
END $$;

-- Constraint: Si es privada, debe tener código
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'check_privada_con_codigo'
  ) THEN
    ALTER TABLE public.rutas 
    ADD CONSTRAINT check_privada_con_codigo 
    CHECK (
      (es_privada = false) OR 
      (es_privada = true AND codigo_acceso IS NOT NULL)
    );
  END IF;
END $$;

-- Agregar foreign key a solicitudes
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'rutas_origen_solicitud_id_fkey'
  ) THEN
    ALTER TABLE public.rutas 
    ADD CONSTRAINT rutas_origen_solicitud_id_fkey 
    FOREIGN KEY (origen_solicitud_id) 
    REFERENCES public.solicitudes_rutas(id);
  END IF;
END $$;

-- Índices
CREATE INDEX IF NOT EXISTS idx_rutas_codigo_acceso 
ON public.rutas(codigo_acceso) 
WHERE codigo_acceso IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_rutas_origen_solicitud 
ON public.rutas(origen_solicitud_id);

CREATE INDEX IF NOT EXISTS idx_rutas_es_privada 
ON public.rutas(es_privada);

-- Comentarios
COMMENT ON COLUMN public.rutas.es_privada IS 'Si es true, requiere código para inscribirse';
COMMENT ON COLUMN public.rutas.codigo_acceso IS 'Código único para acceso a rutas privadas (ej: HAKU-2024-A7B3)';
COMMENT ON COLUMN public.rutas.origen_solicitud_id IS 'ID de la solicitud que originó esta ruta (si aplica)';

-- ============================================
-- 2. MODIFICAR TABLA: perfiles
-- ============================================

-- Agregar campos para estadísticas de guías
ALTER TABLE public.perfiles 
ADD COLUMN IF NOT EXISTS numero_postulaciones_aceptadas integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS numero_postulaciones_rechazadas integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS numero_postulaciones_totales integer DEFAULT 0;

-- Comentarios
COMMENT ON COLUMN public.perfiles.numero_postulaciones_aceptadas IS 'Contador de propuestas aceptadas (para guías)';
COMMENT ON COLUMN public.perfiles.numero_postulaciones_rechazadas IS 'Contador de propuestas rechazadas (para guías)';
COMMENT ON COLUMN public.perfiles.numero_postulaciones_totales IS 'Total de postulaciones enviadas (para guías)';

-- ============================================
-- CONFIRMACIÓN
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '✅ Tablas modificadas exitosamente:';
  RAISE NOTICE '   - rutas (agregados campos de privacidad)';
  RAISE NOTICE '   - perfiles (agregados contadores de postulaciones)';
END $$;
