-- ============================================
-- HAKU - Políticas de Almacenamiento (Storage)
-- Archivo 09: Permisos para Fotos de Lugares/Hakuparadas
-- ============================================

-- 1. Crear el bucket 'lugares' si no existe (normalmente se hace en dashboard, pero por si acaso)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('lugares', 'lugares', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Habilitar RLS en objetos de storage (si no estaba ya)
-- Nota: storage.objects suele tener RLS activo por defecto.

-- 3. POLÍTICAS

-- A. LECTURA PÚBLICA: Todo el mundo puede ver las fotos
DROP POLICY IF EXISTS "Fotos de lugares son publicas" ON storage.objects;
CREATE POLICY "Fotos de lugares son publicas"
ON storage.objects FOR SELECT
USING ( bucket_id = 'lugares' );

-- B. SUBIDA (INSERT): Usuarios autenticados pueden subir fotos
DROP POLICY IF EXISTS "Usuarios autenticados suben fotos lugares" ON storage.objects;
CREATE POLICY "Usuarios autenticados suben fotos lugares"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'lugares' AND
  auth.role() = 'authenticated'
);

-- C. EDICIÓN/BORRADO: Usuarios pueden editar SUS propias fotos (o todo si eres admin)
DROP POLICY IF EXISTS "Usuarios gestionan sus propias fotos lugares" ON storage.objects;
CREATE POLICY "Usuarios gestionan sus propias fotos lugares"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'lugares' AND
  (auth.uid() = owner OR 
   EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin'))
);

DROP POLICY IF EXISTS "Usuarios borran sus propias fotos lugares" ON storage.objects;
CREATE POLICY "Usuarios borran sus propias fotos lugares"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'lugares' AND
  (auth.uid() = owner OR 
   EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin'))
);

-- Confirmación
DO $$
BEGIN
  RAISE NOTICE '✅ Políticas de Storage (Bucket: lugares) configuradas.';
END $$;
