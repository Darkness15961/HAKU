-- ============================================
-- HAKU - Actualización para Rutas Privadas
-- Archivo 7: Agregar código de acceso a Rutas
-- ============================================

-- 1. Agregar columna codigo_acceso a la tabla rutas
ALTER TABLE public.rutas
ADD COLUMN IF NOT EXISTS codigo_acceso text;

-- 2. Agregar índice para búsquedas rápidas por código
CREATE INDEX IF NOT EXISTS idx_rutas_codigo_acceso ON public.rutas(codigo_acceso);

-- 3. Comentario explicativo
COMMENT ON COLUMN public.rutas.codigo_acceso IS 'Código único para unirse a rutas privadas';
