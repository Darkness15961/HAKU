-- ============================================
-- HAKU - Seguridad (RLS) para Hakuparadas
-- Archivo 8: Políticas de Seguridad
-- ============================================

-- 1. Habilitar RLS
ALTER TABLE public.hakuparadas ENABLE ROW LEVEL SECURITY;

-- 2. Limpieza de políticas antiguas (si existen)
DROP POLICY IF EXISTS "Lectura publica de hakuparadas aprobadas" ON public.hakuparadas;
DROP POLICY IF EXISTS "Usuarios autenticados pueden sugerir" ON public.hakuparadas;
DROP POLICY IF EXISTS "Admins tienen control total" ON public.hakuparadas;

-- 3. Definir Políticas

-- A. LECTURA: Todo el mundo (incluso anónimos si quisieras) puede ver las aprobadas
--    Nota: El Service ya filtra por 'verificado=true', pero esto asegura a nivel DB.
CREATE POLICY "Lectura publica de hakuparadas aprobadas"
  ON public.hakuparadas FOR SELECT
  USING (visible = true); 
  -- Opcional: AND verificado = true (si quieres ser super estricto, 
  -- pero a veces los admins necesitan ver las no verificadas y ellos también caen en SELECT)
  -- Para los admins, la política C (abajo) les da acceso a todo, así que aquí
  -- podemos dejar "visible = true" para el público general.
  
-- B. ESCRITURA (INSERT): Cualquier usuario logueado puede sugerir
CREATE POLICY "Usuarios autenticados pueden sugerir"
  ON public.hakuparadas FOR INSERT
  WITH CHECK (
    auth.role() = 'authenticated'
    -- Opcional: Forzar que verificado sea false aqui? 
    -- Normalmente se hace con un Trigger o Default value. 
    -- RLS solo checkea si TIENES PERMISO para insertar la fila tal cual viene.
  );

-- C. ADMIN TOTAL: Los admins pueden ver ocultas, editar, borrar y aprobar
CREATE POLICY "Admins tienen control total"
  ON public.hakuparadas FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.perfiles
      WHERE id = auth.uid()
      AND rol = 'admin'
    )
  );

-- Comentario de confirmación
COMMENT ON TABLE public.hakuparadas IS 'Puntos de interés protegidos por RLS (Archivo 08)';
