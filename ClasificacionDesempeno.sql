-- ============================================================================
-- Evaluar desempeño académico con funciones personalizadas
-- Función: ClasificarDesempeño
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. TABLA BASE
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS notas;

CREATE TABLE notas (
    id_nota        INT AUTO_INCREMENT PRIMARY KEY,
    id_estudiante  INT NOT NULL,
    asignatura     VARCHAR(50) NOT NULL,
    calificacion   DECIMAL(3,1) NOT NULL
);

-- ----------------------------------------------------------------------------
-- 2. DATOS DE PRUEBA
-- ----------------------------------------------------------------------------
INSERT INTO notas (id_estudiante, asignatura, calificacion) VALUES
(1, 'Matemáticas', 2.5),
(1, 'Español',     2.8),
(2, 'Matemáticas', 3.2),
(2, 'Español',     3.8),
(3, 'Matemáticas', 4.5),
(3, 'Español',     4.8),
(4, 'Matemáticas', 3.0),
(4, 'Español',     4.0);

-- ----------------------------------------------------------------------------
-- 3. FUNCIÓN ClasificarDesempeño
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS ClasificarDesempeño;

DELIMITER $$

CREATE FUNCTION ClasificarDesempeño(p_id_estudiante INT)
RETURNS VARCHAR(20)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_promedio DECIMAL(4,2);
    DECLARE v_clasificacion VARCHAR(20);

    -- Calcular el promedio de calificaciones del estudiante
    SELECT AVG(calificacion) INTO v_promedio
    FROM notas
    WHERE id_estudiante = p_id_estudiante;

    -- Si el estudiante no tiene registros, evitar error de NULL
    IF v_promedio IS NULL THEN
        RETURN 'Sin registros';
    END IF;

    -- Lógica condicional de clasificación
    IF v_promedio < 3.0 THEN
        SET v_clasificacion = 'Bajo';
    ELSEIF v_promedio >= 3.0 AND v_promedio <= 4.0 THEN
        SET v_clasificacion = 'Aceptable';
    ELSE
        SET v_clasificacion = 'Sobresaliente';
    END IF;

    RETURN v_clasificacion;
END$$

DELIMITER ;

-- ----------------------------------------------------------------------------
-- 4. USO DE LA FUNCIÓN EN UNA CONSULTA SELECT
-- ----------------------------------------------------------------------------
SELECT DISTINCT
    id_estudiante,
    ClasificarDesempeño(id_estudiante) AS Clasificacion
FROM notas
ORDER BY id_estudiante;

-- ----------------------------------------------------------------------------
-- 5. EVIDENCIA / VERIFICACIÓN DE LA LÓGICA CONDICIONAL
-- ----------------------------------------------------------------------------
-- Promedio esperado por estudiante (referencia manual):
--   Estudiante 1: (2.5 + 2.8) / 2 = 2.65  -> Bajo
--   Estudiante 2: (3.2 + 3.8) / 2 = 3.50  -> Aceptable
--   Estudiante 3: (4.5 + 4.8) / 2 = 4.65  -> Sobresaliente
--   Estudiante 4: (3.0 + 4.0) / 2 = 3.50  -> Aceptable

SELECT
    id_estudiante,
    ROUND(AVG(calificacion), 2) AS promedio_calculado,
    ClasificarDesempeño(id_estudiante) AS clasificacion_funcion
FROM notas
GROUP BY id_estudiante
ORDER BY id_estudiante;

-- Caso límite: estudiante sin registros en la tabla notas
SELECT ClasificarDesempeño(999) AS clasificacion_estudiante_inexistente;