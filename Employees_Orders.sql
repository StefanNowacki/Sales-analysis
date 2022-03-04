-- Number of employees in department and job position
SELECT
    CASE GROUPING(d.department_name)
        WHEN 1 THEN
            'all departments'
        ELSE
            department_name
    END AS department,
    CASE GROUPING(j.job_title)
        WHEN 1 THEN
            'all jobs'
        ELSE
            j.job_title
    END AS job ,
    COUNT(*) AS number_of_employees,
    SUM(e.salary) AS total_salary
FROM
    employees     e
    LEFT JOIN departments   d ON e.department_id = d.department_id
    JOIN jobs          j ON e.job_id = j.job_id
GROUP BY
    ROLLUP(d.department_name,
           j.job_title);


-- sales by gender and income level
SELECT
    c.income_level,
    SUM(
        CASE
            WHEN c.gender = 'F' THEN
                o.order_total
            ELSE
                0
        END
    ) AS "women sell",
    SUM(
        CASE
            WHEN gender = 'M' THEN
                o.order_total
            ELSE
                0
        END
    ) "men sell",
    round(SUM(
        CASE
            WHEN c.gender = 'F' THEN
                o.order_total
            ELSE
                0
        END
    ) / SUM(o.order_total) * 100, 2) AS "%_women",
    round(SUM(
     CASE
            WHEN c.gender = 'M' THEN
                o.order_total
            ELSE
                0
        END
     )/ SUM(o.order_total) * 100, 2) AS "%_men"
    
FROM
    orders      o
    JOIN customers   c ON o.customer_id = c.customer_id
WHERE
    o.order_status NOT IN (
        0,
        1,
        6
    )
GROUP BY
    c.income_level
ORDER BY
    c.income_level;


-- sales by sales channel
SELECT
    last_day(trunc(order_date)) day_of_sell,
    SUM(
        CASE
            WHEN order_mode = 'direct' THEN
                order_total
            ELSE
                0
        END
    ) AS direct,
    SUM(
        CASE
            WHEN order_mode = 'online' THEN
                order_total
            ELSE
                0
        END
    ) AS "ONLINE",
    round(SUM(
        CASE
            WHEN order_mode = 'online' THEN
                order_total
            ELSE
                0
        END
    ) / SUM(order_total), 2) * 100 AS proc_sales_online
FROM
    orders
WHERE
    order_status NOT IN (
        0,
        1,
        6
    )
GROUP BY
    last_day(trunc(order_date));


-- sales by employee with salary, average maring by transaction and sales.
CREATE PRIVATE TEMPORARY TABLE ora$ptt_seller_data
AS
(
SELECT
e.first_name
|| ' '
|| e.last_name AS seller,
salary AS salary,
SUM(o.order_total) AS sales
--AVG(e.commission_pct)as srednia 
FROM
orders o
JOIN hr.employees e ON o.sales_rep_id = e.employee_id
WHERE
order_status NOT IN ( 0, 1, 6 )
GROUP BY
e.first_name
|| ' '
|| e.last_name,
salary
);

CREATE PRIVATE TEMPORARY TABLE ora$ptt_margin
    AS
        ( SELECT
            e.first_name
            || ' '
               || e.last_name AS seller,
            round(AVG((oi.unit_price / p.min_price * 100) - 100), 2) AS avg_margin_transaction,
            round(100 *(SUM(oi.unit_price * oi.quantity) / SUM(p.min_price * oi.quantity) - 1), 2) AS avg_margin_sales
        FROM
            orders                o
            JOIN order_items           oi ON o.order_id = oi.order_id
            JOIN product_information   p ON oi.product_id = p.product_id
            JOIN employees             e ON o.sales_rep_id = e.employee_id
        WHERE
            p.min_price <> 0
            AND o.order_status NOT IN (
                0,
                1,
                6
            )
        GROUP BY
            e.first_name
            || ' '
               || e.last_name
        );

SELECT
    *
FROM
    ora$ptt_seller_data;

SELECT
    *
FROM
    ora$ptt_margin;
SELECT
    tab1.*,
    tab2.avg_margin_transaction,
    tab2.avg_margin_sales
FROM
    ora$ptt_seller_data   tab1
    JOIN ora$ptt_margin   tab2 ON tab1.seller = tab2.seller;


SELECT
    tab1.*,
    tab2.avg_margin_transaction,
    tab2.avg_margin_sales
FROM
    ora$ptt_seller_data   tab1
    JOIN ora$ptt_margin   tab2 ON tab1.seller = tab2.seller
ORDER BY
    tab1.sales ASC;


-- sales by manager with number of clients, salary, average maring by transaction and sales. 
SELECT
    e.first_name
    || ' '
       || e.last_name AS sales_manager,
    SUM(o.order_total) AS sum_of_sales,
    MAX(e.salary) AS salary,
    MAX(e.commission_pct) AS margin,
    COUNT(DISTINCT c.customer_id) AS number_of_clients,
    round(AVG((oi.unit_price / p.min_price * 100) - 100), 2) AS avg_margin_transaction,
    round(100 *(SUM(oi.unit_price * oi.quantity) / SUM(p.min_price * oi.quantity) - 1), 2) AS avg_margin_sales
FROM
    orders                o
    JOIN customers             c ON o.customer_id = c.customer_id
    JOIN employees             e ON c.account_mgr_id = e.employee_id
    JOIN order_items           oi ON o.order_id = oi.order_id
    JOIN product_information   p ON oi.product_id = p.product_id
WHERE
    p.min_price <> 0
    AND o.order_status NOT IN (
        0,
        1,
        6
    )
GROUP BY
    e.first_name
    || ' '
       || e.last_name
ORDER BY
    sales_manager ASC;

-- Ranking of sales by country and gender
SELECT
    c.nls_territory   AS country,
    c.gender          AS gender,
    SUM(o.order_total) AS total_amount_sell,
    RANK() OVER(
        ORDER BY
            SUM(o.order_total) DESC
    ) AS top_buying_ranking
FROM
    customers   c
    JOIN orders      o ON c.customer_id = o.customer_id
GROUP BY
    c.nls_territory,
    c.gender;
    
-- sales buy country and day    
SELECT
    c.nls_territory AS country,
    last_day(trunc(o.order_date)) AS day_of_sell,
    SUM(o.order_total) total_sell_amount
FROM
    customers   c
    JOIN orders      o ON c.customer_id = o.customer_id
WHERE
    o.order_status NOT IN (
        0,
        1
    )
GROUP BY
    c.nls_territory,
    last_day(trunc(o.order_date))
ORDER BY
    country ASC,
    day_of_sell ASC;

