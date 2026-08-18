# Descripción de la consulta SQL - Ventas mensuales por categoría

Este código construye una tabla de ventas mensuales por categoría, usando CTEs (Common Table Expressions) encadenadas.

## Paso 1 — `ventas_mensuales`

CTE base que limpia y agrupa los datos. Agrupa las ventas por mes (truncando la fecha al primer día del mes con `DATE_TRUNC`) y categoría, sumando el monto total vendido en cada combinación mes-categoría.

```sql
SELECT
    DATE_TRUNC('month', fecha_venta) AS mes,
    categoria,
    SUM(monto) AS venta_total
FROM ventas
GROUP BY DATE_TRUNC('month', fecha_venta), categoria
```

## Paso 2 — `ventas_con_ranking`

Toma la tabla anterior y le agrega un ranking (`RANK()`) que ordena las categorías dentro de cada mes según su venta total, de mayor a menor. Así se puede ver qué categoría fue la más vendida en cada mes.

```sql
SELECT
    *,
    RANK() OVER (PARTITION BY mes ORDER BY venta_total DESC) AS ranking_mes
FROM ventas_mensuales
```

## Paso 3 — `ventas_con_acumulado`

Agrega una suma acumulada (`SUM() OVER`) del monto vendido por categoría a lo largo del tiempo, ordenando por mes. Esto muestra cómo va creciendo la venta total de cada categoría mes a mes.

```sql
SELECT
    *,
    SUM(venta_total) OVER (PARTITION BY categoria ORDER BY mes) AS acumulado_categoria
FROM ventas_con_ranking
```

## Paso 4 — SELECT final (comparativa)

Toma todo lo anterior y agrega una comparación adicional: para cada fila, calcula el promedio histórico de ventas de esa categoría (`AVG() OVER`, particionado por categoría) y marca si esa venta mensual estuvo "Por encima" o "Por debajo" de su propio promedio. El resultado se ordena por mes y por ranking.

```sql
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
```

## Resumen

La consulta responde tres preguntas a la vez para cada categoría y mes:

1. Cuánto se vendió.
2. Qué lugar ocupó ese mes respecto a las demás categorías (ranking).
3. Cuánto lleva acumulado la categoría hasta ese mes, y si ese mes estuvo por encima o por debajo de su promedio histórico.
