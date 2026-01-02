-- ============================================
-- HAKU - Sistema de Solicitudes de Rutas
-- Archivo 5: Row Level Security (RLS)
-- ============================================

-- ============================================
-- 1. RLS PARA: solicitudes_rutas
-- ============================================

-- Habilitar RLS
ALTER TABLE public.solicitudes_rutas ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Turistas ven sus solicitudes" ON public.solicitudes_rutas;
DROP POLICY IF EXISTS "Turistas crean solicitudes" ON public.solicitudes_rutas;
DROP POLICY IF EXISTS "Turistas editan sus solicitudes" ON public.solicitudes_rutas;
DROP POLICY IF EXISTS "Guías ven solicitudes activas" ON public.solicitudes_rutas;
DROP POLICY IF EXISTS "Admins ven todas las solicitudes" ON public.solicitudes_rutas;

-- 1.1 Turistas ven sus propias solicitudes
CREATE POLICY "Turistas ven sus solicitudes"
  ON public.solicitudes_rutas FOR SELECT
  USING (auth.uid() = turista_id);

-- 1.2 Turistas crean solicitudes (solo si tienen DNI validado)
CREATE POLICY "Turistas crean solicitudes"
  ON public.solicitudes_rutas FOR INSERT
  WITH CHECK (
    auth.uid() = turista_id AND
    EXISTS (
      SELECT 1 FROM public.perfiles 
      WHERE id = auth.uid() 
      AND nombres IS NOT NULL
      AND apellido_paterno IS NOT NULL
      AND apellido_materno IS NOT NULL
    )
  );

-- 1.3 Turistas editan sus solicitudes (solo si están buscando guía)
CREATE POLICY "Turistas editan sus solicitudes"
  ON public.solicitudes_rutas FOR UPDATE
  USING (
    auth.uid() = turista_id AND 
    estado = 'buscando_guia'
  )
  WITH CHECK (
    auth.uid() = turista_id AND 
    estado = 'buscando_guia'
  );

-- 1.4 Guías ven solicitudes activas
CREATE POLICY "Guías ven solicitudes activas"
  ON public.solicitudes_rutas FOR SELECT
  USING (
    estado = 'buscando_guia' AND
    EXISTS (
      SELECT 1 FROM public.perfiles 
      WHERE id = auth.uid() 
      AND rol IN ('guia_local', 'guia_aprobado', 'admin')
    )
  );

-- 1.5 Admins ven todo
CREATE POLICY "Admins ven todas las solicitudes"
  ON public.solicitudes_rutas FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.perfiles 
      WHERE id = auth.uid() AND rol = 'admin'
    )
  );

-- ============================================
-- 2. RLS PARA: postulaciones_guias
-- ============================================

-- Habilitar RLS
ALTER TABLE public.postulaciones_guias ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Guías ven sus postulaciones" ON public.postulaciones_guias;
DROP POLICY IF EXISTS "Turistas ven postulaciones de sus solicitudes" ON public.postulaciones_guias;
DROP POLICY IF EXISTS "Guías crean postulaciones" ON public.postulaciones_guias;
DROP POLICY IF EXISTS "Admins ven todas las postulaciones" ON public.postulaciones_guias;

-- 2.1 Guías ven sus propias postulaciones
CREATE POLICY "Guías ven sus postulaciones"
  ON public.postulaciones_guias FOR SELECT
  USING (auth.uid() = guia_id);

-- 2.2 Turistas ven postulaciones de sus solicitudes
CREATE POLICY "Turistas ven postulaciones de sus solicitudes"
  ON public.postulaciones_guias FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.solicitudes_rutas 
      WHERE id = solicitud_id AND turista_id = auth.uid()
    )
  );

-- 2.3 Guías crean postulaciones (solo si son guías certificados y la solicitud está activa)
CREATE POLICY "Guías crean postulaciones"
  ON public.postulaciones_guias FOR INSERT
  WITH CHECK (
    auth.uid() = guia_id AND
    EXISTS (
      SELECT 1 FROM public.perfiles 
      WHERE id = auth.uid() 
      AND rol IN ('guia_local', 'guia_aprobado', 'admin')
    ) AND
    EXISTS (
      SELECT 1 FROM public.solicitudes_rutas 
      WHERE id = solicitud_id AND estado = 'buscando_guia'
    )
  );

-- 2.4 Admins ven todo
CREATE POLICY "Admins ven todas las postulaciones"
  ON public.postulaciones_guias FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.perfiles 
      WHERE id = auth.uid() AND rol = 'admin'
    )
  );

-- ============================================
-- 3. RLS PARA: intentos_acceso_ruta
-- ============================================

-- Habilitar RLS
ALTER TABLE public.intentos_acceso_ruta ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Usuarios ven sus intentos" ON public.intentos_acceso_ruta;
DROP POLICY IF EXISTS "Sistema registra intentos" ON public.intentos_acceso_ruta;
DROP POLICY IF EXISTS "Admins ven todos los intentos" ON public.intentos_acceso_ruta;

-- 3.1 Usuarios ven sus propios intentos
CREATE POLICY "Usuarios ven sus intentos"
  ON public.intentos_acceso_ruta FOR SELECT
  USING (auth.uid() = usuario_id);

-- 3.2 Sistema puede registrar intentos (INSERT desde funciones)
CREATE POLICY "Sistema registra intentos"
  ON public.intentos_acceso_ruta FOR INSERT
  WITH CHECK (true); -- Permitir INSERT desde funciones SECURITY DEFINER

-- 3.3 Admins ven todo
CREATE POLICY "Admins ven todos los intentos"
  ON public.intentos_acceso_ruta FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.perfiles 
      WHERE id = auth.uid() AND rol = 'admin'
    )
  );

-- ============================================
-- 4. ACTUALIZAR RLS PARA: rutas (Privacidad)
-- ============================================

-- Eliminar política existente
DROP POLICY IF EXISTS "Usuarios ven rutas según privacidad" ON public.rutas;

-- Crear nueva política que considera privacidad
CREATE POLICY "Usuarios ven rutas según privacidad"
  ON public.rutas FOR SELECT
  USING (
    -- Rutas públicas visibles: todos las ven
    (es_privada = false AND visible = true) OR
    
    -- Rutas privadas: solo el guía creador
    (es_privada = true AND guia_id = auth.uid()) OR
    
    -- Rutas privadas: usuarios inscritos (validaron código)
    (es_privada = true AND EXISTS (
      SELECT 1 FROM public.inscripciones 
      WHERE ruta_id = id AND usuario_id = auth.uid()
    )) OR
    
    -- Admins ven todo
    EXISTS (
      SELECT 1 FROM public.perfiles 
      WHERE id = auth.uid() AND rol = 'admin'
    )
  );

-- ============================================
-- CONFIRMACIÓN
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '✅ Políticas RLS creadas exitosamente:';
  RAISE NOTICE '   - solicitudes_rutas (5 políticas)';
  RAISE NOTICE '   - postulaciones_guias (4 políticas)';
  RAISE NOTICE '   - intentos_acceso_ruta (3 políticas)';
  RAISE NOTICE '   - rutas (actualizada para privacidad)';
END $$;
