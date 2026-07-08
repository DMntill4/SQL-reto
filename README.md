# Evaluar Desempeño Académico con Funciones Personalizadas

Función SQL definida por el usuario que clasifica el desempeño de un estudiante según el promedio de sus calificaciones registradas en la tabla `notas`.

## Contenido del repositorio

| Archivo | Descripción |
|---|---|
| `ClasificarDesempeno.sql` | Script completo: tabla, datos de prueba, función y consultas de evidencia |
| `README.md` | Este documento |

## Objetivo

Crear una función (`ClasificarDesempeño`) que:

1. Reciba el `id` de un estudiante.
2. Consulte todas sus calificaciones en la tabla `notas`.
3. Calcule el promedio.
4. Retorne una clasificación textual según el promedio:

| Rango de promedio | Clasificación |
|---|---|
| `< 3.0` | `Bajo` |
| `3.0` a `4.0` (inclusive) | `Aceptable` |
| `> 4.0` | `Sobresaliente` |

## Estructura de la tabla `notas`

```sql
CREATE TABLE notas (
    id_nota        INT AUTO_INCREMENT PRIMARY KEY,
    id_estudiante  INT NOT NULL,
    asignatura     VARCHAR(50) NOT NULL,
    calificacion   DECIMAL(3,1) NOT NULL
);
```

## La función

```sql
DELIMITER $$

CREATE FUNCTION ClasificarDesempeño(p_id_estudiante INT)
RETURNS VARCHAR(20)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_promedio DECIMAL(4,2);
    DECLARE v_clasificacion VARCHAR(20);

    SELECT AVG(calificacion) INTO v_promedio
    FROM notas
    WHERE id_estudiante = p_id_estudiante;

    IF v_promedio IS NULL THEN
        RETURN 'Sin registros';
    END IF;

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
```

## Uso

```sql
SELECT DISTINCT
    id_estudiante,
    ClasificarDesempeño(id_estudiante) AS Clasificacion
FROM notas
ORDER BY id_estudiante;
```

## Evidencia de la lógica condicional

Con los datos de prueba incluidos en el script:

| id_estudiante | promedio | clasificación esperada | clasificación de la función |
|---|---|---|---|
| 1 | 2.65 | Bajo | Bajo |
| 2 | 3.50 | Aceptable | Aceptable |
| 3 | 4.65 | Sobresaliente | Sobresaliente |
| 4 | 3.50 | Aceptable | Aceptable |

Esto confirma que las tres ramas del bloque `IF / ELSEIF / ELSE` se ejecutan correctamente frente a valores por debajo del límite, dentro del rango, y por encima del límite.

También se incluye un caso límite: un `id_estudiante` sin registros en `notas` retorna `'Sin registros'` en vez de fallar por `NULL`, evitando que `AVG()` sobre un conjunto vacío rompa la lógica condicional.

## Justificación: ¿`DETERMINISTIC` o `NOT DETERMINISTIC`?

La función se declara **`NOT DETERMINISTIC`**, por las siguientes razones:

1. **Depende de datos externos mutables.** La función ejecuta un `SELECT ... FROM notas` internamente. El resultado no depende solo del parámetro de entrada (`p_id_estudiante`), sino del estado actual de la tabla `notas`. Si se inserta, actualiza o elimina una nota de ese estudiante entre dos llamadas, el resultado cambia aunque el parámetro sea el mismo.

2. **Definición formal en MySQL.** Una función es `DETERMINISTIC` únicamente si, dado el mismo conjunto de parámetros, siempre retorna el mismo resultado, sin importar el estado de la base de datos. Como esta función lee datos que varían en el tiempo, no cumple ese criterio.

3. **Consecuencias prácticas de declararla mal.** Marcarla incorrectamente como `DETERMINISTIC` puede causar inconsistencias en configuraciones con *binary logging* en modo `STATEMENT`, o generar advertencias si `log_bin_trust_function_creators` está desactivado, ya que MySQL exige declarar correctamente si una función es segura de replicar basada en la sentencia.

4. **Característica adicional (`READS SQL DATA`).** Se declara así porque la función lee de una tabla pero no la modifica, lo cual MySQL exige indicar explícitamente para funciones con `SELECT` interno (a diferencia de `NO SQL` o `MODIFIES SQL DATA`).

## Cómo ejecutar

1. Abrir el archivo `ClasificarDesempeno.sql` en MySQL Workbench.
2. Ejecutar el script completo (crea la tabla, inserta los datos de prueba, crea la función y corre las consultas de evidencia).
3. Revisar los resultados de los últimos `SELECT` para verificar la clasificación de cada estudiante.