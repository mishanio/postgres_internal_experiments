CREATE EXTENSION pageinspect;

CREATE TABLE padding(
i1 integer,
i2 integer,
b1 boolean,
b2 boolean
);

INSERT INTO padding VALUES (1,2,true,false);
SELECT lp_len FROM heap_page_items(get_raw_page('padding', 0));


-- Для экспериментов понадобится таблица с двумя столбцами и индексом по одному из них:
CREATE TABLE t(
id integer GENERATED ALWAYS AS IDENTITY,
s text
);
CREATE INDEX ON t(s);



SELECT '(0,'||lp||')' AS ctid,
CASE lp_flags
WHEN 0 THEN 'unused'
WHEN 1 THEN 'normal'
WHEN 2 THEN 'redirect to '||lp_off
WHEN 3 THEN 'dead'
END AS state,
t_xmin as xmin,
t_xmax as xmax,
(t_infomask & 256) > 0 AS xmin_committed,
(t_infomask & 512) > 0 AS xmin_aborted,
(t_infomask & 1024) > 0 AS xmax_committed,
(t_infomask & 2048) > 0 AS xmax_aborted
FROM heap_page_items(get_raw_page('t',0));

INSERT INTO t(s) VALUES ('FOO');

-- Функция для простого запуска запроса
CREATE FUNCTION heap_page(relname text, pageno integer)
RETURNS TABLE(ctid tid, state text, xmin text, xmax text)
AS $$
SELECT (pageno,lp)::text::tid AS ctid,
CASE lp_flags
WHEN 0 THEN 'unused'
WHEN 1 THEN 'normal'
WHEN 2 THEN 'redirect to '||lp_off
WHEN 3 THEN 'dead'
END AS state,
t_xmin || CASE
WHEN (t_infomask & 256) > 0 THEN ' c'
WHEN (t_infomask & 512) > 0 THEN ' a'
ELSE ''
END AS xmin,
t_xmax || CASE
WHEN (t_infomask & 1024) > 0 THEN ' c'
WHEN (t_infomask & 2048) > 0 THEN ' a'
ELSE ''
END AS xmax
FROM heap_page_items(get_raw_page(relname,pageno))
ORDER BY lp;
$$ LANGUAGE sql;

SELECT * FROM heap_page('t',0);