-- ============================================
-- HAKU - Sistema de Solicitudes de Rutas
-- Archivo 6: Vistas y Utilidades
-- ============================================

-- ============================================
-- 1. VISTA: Solicitudes Completas
-- ============================================

CREATE OR REPLACE VIEW vista_solicitudes_completas AS
SELECT 
  s.*,
  -- Datos del turista
  p.seudonimo as turista_nombre,
  p.url_foto_perfil as turista_foto,
  p.email as turista_email,
  -- Datos del guía (si está asignado)
  pg.seudonimo as guia_nombre,
  pg.url_foto_perfil as guia_foto,
  pg.rating as guia_rating,
  pg.email as guia_email,
  -- Contadores
  COUNT(DISTINCT post.id) FILTER (WHERE post.estado = 'pendiente') as postulaciones_pendientes,
  COUNT(DISTINCT post.id) FILTER (WHERE post.estado = 'aceptada') as postulaciones_aceptadas,
  COUNT(DISTINCT post.id) FILTER (WHERE post.estado = 'rechazada') as postulaciones_rechazadas,
  -- Datos de la ruta creada (si existe)
  r.codigo_acceso as ruta_codigo_acceso,
  r.es_privada as ruta_es_privada
FROM public.solicitudes_rutas s
LEFT JOIN public.perfiles p ON s.turista_id = p.id
LEFT JOIN public.perfiles pg ON s.guia_asignado_id = pg.id
LEFT JOIN public.postulaciones_guias post ON s.id = post.solicitud_id
LEFT JOIN public.rutas r ON s.ruta_creada_id = r.id
GROUP BY 
  s.id, 
  p.seudonimo, p.url_foto_perfil, p.email,
  pg.seudonimo, pg.url_foto_perfil, pg.rating, pg.email,
  r.codigo_acceso, r.es_privada;

COMMENT ON VIEW vista_solicitudes_completas IS 'Vista con datos completos de solicitudes, turistas, guías y contadores';

-- ============================================
-- 2. VISTA: Postulaciones con Datos de Guía
-- ============================================

CREATE OR REPLACE VIEW vista_postulaciones_completas AS
SELECT 
  post.*,
  -- Datos del guía
  p.seudonimo as guia_nombre,
  p.url_foto_perfil as guia_foto,
  p.rating as guia_rating,
  p.email as guia_email,
  p.numero_postulaciones_aceptadas,
  p.numero_postulaciones_totales,
  -- Datos de la solicitud
  s.titulo as solicitud_titulo,
  s.descripcion as solicitud_descripcion,
  s.fecha_deseada as solicitud_fecha,
  s.numero_personas as solicitud_personas,
  s.turista_id,
  -- Datos del turista
  pt.seudonimo as turista_nombre,
  pt.url_foto_perfil as turista_foto
FROM public.postulaciones_guias post
LEFT JOIN public.perfiles p ON post.guia_id = p.id
LEFT JOIN public.solicitudes_rutas s ON post.solicitud_id = s.id
LEFT JOIN public.perfiles pt ON s.turista_id = pt.id;

COMMENT ON VIEW vista_postulaciones_completas IS 'Vista con datos completos de postulaciones, guías, solicitudes y turistas';

-- ============================================
-- 3. VISTA: Estadísticas de Guías
-- ============================================

CREATE OR REPLACE VIEW vista_estadisticas_guias AS
SELECT 
  p.id,
  p.seudonimo,
  p.rating,
  p.numero_postulaciones_totales,
  p.numero_postulaciones_aceptadas,
  p.numero_postulaciones_rechazadas,
  -- Calcular tasa de aceptación
  CASE 
    WHEN p.numero_postulaciones_totales > 0 THEN
      ROUND((p.numero_postulaciones_aceptadas::numeric / p.numero_postulaciones_totales::numeric) * 100, 2)
    ELSE 0
  END as tasa_aceptacion_porcentaje,
  -- Contar rutas creadas
  COUNT(DISTINCT r.id) as rutas_creadas,
  -- Contar rutas activas
  COUNT(DISTINCT r.id) FILTER (WHERE r.estado = 'abierto') as rutas_activas,
  -- Promedio de precio de rutas
  ROUND(AVG(r.precio), 2) as precio_promedio_rutas
FROM public.perfiles p
LEFT JOIN public.rutas r ON p.id = r.guia_id
WHERE p.rol IN ('guia_local', 'guia_aprobado')
GROUP BY p.id, p.seudonimo, p.rating, p.numero_postulaciones_totales, 
         p.numero_postulaciones_aceptadas, p.numero_postulaciones_rechazadas;

COMMENT ON VIEW vista_estadisticas_guias IS 'Estadísticas completas de guías: postulaciones, rutas y tasas de éxito';

-- ============================================
-- 4. FUNCIÓN: Obtener Solicitudes Disponibles para Guía
-- ============================================

-- ============================================
-- 4. FUNCIÓN: Obtener Solicitudes Disponibles para Guía
-- ============================================

CREATE OR REPLACE FUNCTION obtener_solicitudes_disponibles(
  p_guia_id uuid,
  p_limite integer DEFAULT 20,
  p_offset integer DEFAULT 0
)
RETURNS TABLE (
  id bigint,
  titulo text,
  descripcion text,
  fecha_deseada timestamp with time zone,
  numero_personas integer,
  presupuesto_maximo numeric,
  numero_postulaciones integer,
  turista_nombre text,
  turista_foto text,
  ya_postule boolean,
  -- Nuevos campos requeridos por Dart
  turista_id uuid,
  lugares_ids bigint[],
  estado text,
  fecha_creacion timestamp with time zone,
  preferencia_privacidad text,
  grupo_objetivo text,
  enlace_video_referencia text,
  notas_adicionales text,
  guia_asignado_id uuid,
  postulacion_aceptada_id bigint,
  ruta_creada_id bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id,
    s.titulo,
    s.descripcion,
    s.fecha_deseada,
    s.numero_personas,
    s.presupuesto_maximo,
    s.numero_postulaciones,
    p.seudonimo as turista_nombre,
    p.url_foto_perfil as turista_foto,
    EXISTS(
      SELECT 1 FROM public.postulaciones_guias 
      WHERE solicitud_id = s.id AND guia_id = p_guia_id
    ) as ya_postule,
    -- Mapeo de nuevos campos
    s.turista_id,
    ARRAY(SELECT jsonb_array_elements_text(s.lugares_ids)::bigint) as lugares_ids, -- Conversión si se guardó como JSONB, o directo s.lugares_ids si es array
    s.estado,
    s.fecha_creacion,
    s.preferencia_privacidad,
    s.grupo_objetivo,
    s.enlace_video_referencia,
    s.notas_adicionales,
    s.guia_asignado_id,
    s.postulacion_aceptada_id,
    s.ruta_creada_id
  FROM public.solicitudes_rutas s
  LEFT JOIN public.perfiles p ON s.turista_id = p.id
  WHERE s.estado = 'buscando_guia'
    AND s.fecha_deseada > now()
  ORDER BY s.fecha_creacion DESC
  LIMIT p_limite
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION obtener_solicitudes_disponibles IS 'Obtiene solicitudes disponibles para que un guía postule';

-- ============================================
-- 5. FUNCIÓN: Obtener Mis Solicitudes (Turista)
-- ============================================

DROP FUNCTION IF EXISTS obtener_mis_solicitudes(uuid);

CREATE OR REPLACE FUNCTION obtener_mis_solicitudes(
  p_turista_id uuid
)
RETURNS TABLE (
  id bigint,
  titulo text,
  descripcion text,
  estado text,
  fecha_deseada timestamp with time zone,
  numero_personas integer,
  numero_postulaciones integer,
  guia_nombre text,
  guia_foto text,
  guia_rating double precision,
  ruta_id bigint,
  codigo_acceso text,
  -- Cambios para Dart
  turista_id uuid,
  lugares_ids bigint[],
  presupuesto_maximo numeric,
  grupo_objetivo text,
  fecha_creacion timestamp with time zone,
  preferencia_privacidad text,
  enlace_video_referencia text,
  notas_adicionales text,
  guia_asignado_id uuid,
  postulacion_aceptada_id bigint,
  fecha_cancelacion timestamp with time zone,
  motivo_cancelacion text,
  ruta_creada_id bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id,
    s.titulo,
    s.descripcion,
    s.estado,
    s.fecha_deseada,
    s.numero_personas,
    s.numero_postulaciones,
    pg.seudonimo as guia_nombre,
    pg.url_foto_perfil as guia_foto,
    pg.rating as guia_rating,
    s.ruta_creada_id as ruta_id,
    r.codigo_acceso,
    -- Campos adicionales
    s.turista_id,
    ARRAY(SELECT jsonb_array_elements_text(s.lugares_ids)::bigint) as lugares_ids,
    s.presupuesto_maximo,
    s.grupo_objetivo,
    s.fecha_creacion,
    s.preferencia_privacidad,
    s.enlace_video_referencia,
    s.notas_adicionales,
    s.guia_asignado_id,
    s.postulacion_aceptada_id,
    s.fecha_cancelacion,
    s.motivo_cancelacion,
    s.ruta_creada_id
  FROM public.solicitudes_rutas s
  LEFT JOIN public.perfiles pg ON s.guia_asignado_id = pg.id
  LEFT JOIN public.rutas r ON s.ruta_creada_id = r.id
  WHERE s.turista_id = p_turista_id
  ORDER BY s.fecha_creacion DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION obtener_mis_solicitudes IS 'Obtiene todas las solicitudes de un turista';

-- ============================================
-- 6. FUNCIÓN: Obtener Mis Postulaciones (Guía)
-- ============================================

DROP FUNCTION IF EXISTS obtener_mis_postulaciones(uuid);

CREATE OR REPLACE FUNCTION obtener_mis_postulaciones(
  p_guia_id uuid
)
RETURNS TABLE (
  id bigint,
  solicitud_id bigint,
  solicitud_titulo text,
  precio_ofertado numeric,
  estado text,
  fecha_postulacion timestamp with time zone,
  turista_nombre text,
  turista_foto text,
  fecha_deseada timestamp with time zone,
  -- Nuevos campos
  guia_id uuid,
  moneda text,
  descripcion_propuesta text,
  itinerario_detallado text,
  servicios_incluidos text[],
  fecha_respuesta timestamp with time zone,
  guia_nombre text,
  guia_foto text,
  guia_rating double precision
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    post.id,
    post.solicitud_id,
    s.titulo as solicitud_titulo,
    post.precio_ofertado,
    post.estado,
    post.fecha_postulacion,
    p.seudonimo as turista_nombre,
    p.url_foto_perfil as turista_foto,
    s.fecha_deseada,
    -- Campos faltantes
    post.guia_id,
    post.moneda,
    post.descripcion_propuesta,
    post.itinerario_detallado,
    post.servicios_incluidos,
    post.fecha_respuesta,
    -- Datos del propio guia (redundante pero requerido por el entity si usa el mismo modelo)
    g.seudonimo as guia_nombre,
    g.url_foto_perfil as guia_foto,
    g.rating as guia_rating
  FROM public.postulaciones_guias post
  LEFT JOIN public.solicitudes_rutas s ON post.solicitud_id = s.id
  LEFT JOIN public.perfiles p ON s.turista_id = p.id
  LEFT JOIN public.perfiles g ON post.guia_id = g.id
  WHERE post.guia_id = p_guia_id
  ORDER BY post.fecha_postulacion DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION obtener_mis_postulaciones IS 'Obtiene todas las postulaciones de un guía';

-- ============================================
-- CONFIRMACIÓN
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '✅ Vistas y funciones de utilidad creadas:';
  RAISE NOTICE '   - vista_solicitudes_completas';
  RAISE NOTICE '   - vista_postulaciones_completas';
  RAISE NOTICE '   - vista_estadisticas_guias';
  RAISE NOTICE '   - obtener_solicitudes_disponibles()';
  RAISE NOTICE '   - obtener_mis_solicitudes()';
  RAISE NOTICE '   - obtener_mis_postulaciones()';
END $$;
