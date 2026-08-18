-- Paso 1: CTE base, limpia y agrupa
WITH ventas_mensuales AS (
    SELECT
        DATE_TRUNC('month', fecha_venta) AS mes,
        categoria,
        SUM(monto) AS venta_total
    FROM ventas
    GROUP BY DATE_TRUNC('month', fecha_venta), categoria
),

-- Paso 2: agrega el ranking sobre la CTE anterior
ventas_con_ranking AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY mes ORDER BY venta_total DESC) AS ranking_mes
    FROM ventas_mensuales
),

-- Paso 3: agrega el acumulado
ventas_con_acumulado AS (
    SELECT
        *,
        SUM(venta_total) OVER (PARTITION BY categoria ORDER BY mes) AS acumulado_categoria
    FROM ventas_con_ranking
)

-- Paso 4 (comparativa): se calcula sobre la CTE final
SELECT
    mes,
    categoria,
    venta_total,
    ranking_mes,
    acumulado_categoria,
    CASE
        WHEN venta_total > AVG(venta_total) OVER (PARTITION BY categoria)
        THEN 'Por encima'
        ELSE 'Por debajo'
    END AS comparativa_promedio
FROM ventas_con_acumulado
ORDER BY mes, ranking_mes;