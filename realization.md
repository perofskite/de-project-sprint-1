# Витрина RFM

## 1.1. Выясните требования к целевой витрине.

{См. задание на платформе}
-----------


-- Витрина должна находиться в схеме analysis, название таблицы - dm_rfm_segments. 
-- Обновления: не нужны. Статус заказа: только Closed. Глубина: с начала 2022 года.

Витрина должна состоять из таких полей:
user_id INT NOT NULL PRIMARY key -- ИД юзера
recency (число от 1 до 5) INT NOT NULL CHECK(recency >= 1 AND recency <= 5) -- давность последнего заказа
frequency (число от 1 до 5) INT NOT NULL CHECK(frequency >= 1 AND frequency <= 5) -- частота заказов
monetary_value (число от 1 до 5) INT NOT NULL CHECK(monetary_value >= 1 AND monetary_value <= 5) -- сумма затрат клиента



## 1.2. Изучите структуру исходных данных.

{См. задание на платформе}

-----------

Структура ordertimes:
id int4 NOT NULL GENERATED ALWAYS AS IDENTITY -- ИД записи, генерируется автоматически при добавлении записи
product_id int4 NOT NULL, -- ИД продукта в заказе, связан с таблицей products as p: product_id = p.id
order_id int4 NOT NULL, -- ИД заказа, связан с таблицей orders as o: order_id = o.order_id
"name" varchar(2048) NOT NULL, -- название продукта в заказе, берется из таблицы products
price numeric(19, 5) NOT NULL DEFAULT 0, -- цена продукта в заказе, берется из таблицы products
discount numeric(19, 5) NOT NULL DEFAULT 0, -- скидка на заказ (все 0, поэтому не понятно, указывается ли в процентах)
quantity int4 NOT NULL, -- количество продуктов в заказе
CONSTRAINT orderitems_check CHECK (((discount >= (0)::numeric) AND (discount <= price))), -- скидка не может быть отрицательной и не может превышать цену (предполагаем, что скидка указывается не в процентах, а в деньгах)
CONSTRAINT orderitems_order_id_product_id_key UNIQUE (order_id, product_id), -- введено ограницение по уникальности, чтобы не дублировать заказы
CONSTRAINT orderitems_pkey PRIMARY KEY (id),
CONSTRAINT orderitems_price_check CHECK ((price >= (0)::numeric)), -- цена не может быть отрицательной
CONSTRAINT orderitems_quantity_check CHECK ((quantity > 0)) -- количество должно быть больше 0

Структура orders:
order_id int4 NOT NULL, -- ИД заказа, связан с таблицами ordertimes as o и orderstatuslog as os: o.order_id = order_id & os.order_id = order_id
order_ts timestamp NOT NULL, -- время заказа
user_id int4 NOT NULL, -- ИД пользователя, связан с таблицей users as u: user_id = u.id
bonus_payment numeric(19, 5) NOT NULL DEFAULT 0,
payment numeric(19, 5) NOT NULL DEFAULT 0, -- сумма оплаты
"cost" numeric(19, 5) NOT NULL DEFAULT 0, -- стоимость покупки
bonus_grant numeric(19, 5) NOT NULL DEFAULT 0, -- бонусы за оплату
status int4 NOT NULL, -- статус заказа, связан с таблицей orderstatuses as o: status = o.id
CONSTRAINT orders_check CHECK ((cost = (payment + bonus_payment))),
CONSTRAINT orders_pkey PRIMARY KEY (order_id)


Структура orderstatuses:
id int4 NOT NULL, -- ИД статуса
"key" varchar(255) NOT NULL, -- название статуса

Структура orderstatuslog:
id int4 NOT NULL GENERATED ALWAYS AS IDENTITY, -- ИД записи, генерируется автоматически при добавлении записи
order_id int4 NOT NULL, -- ИД заказа
status_id int4 NOT NULL, -- ИД статуса
dttm timestamp NOT NULL, -- время оформления заказа
CONSTRAINT orderstatuslog_order_id_status_id_key UNIQUE (order_id, status_id),  -- введено ограницение по уникальности, чтобы не дублировать заказы
CONSTRAINT orderstatuslog_pkey PRIMARY KEY (id)

Структура products:
id int4 NOT NULL, -- ИД продукта
"name" varchar(2048) NOT NULL, -- название продукта
price numeric(19, 5) NOT NULL DEFAULT 0, -- цена продукта
CONSTRAINT products_pkey PRIMARY KEY (id),
CONSTRAINT products_price_check CHECK ((price >= (0)::numeric)) -- цена не может быть отрицательной

Структура users:
id int4 NOT NULL, -- ИД пользователя
"name" varchar(2048) NULL, -- логин  пользователя
login varchar(2048) NOT NULL, -- ФИО пользователя
CONSTRAINT users_pkey PRIMARY KEY (id)

## 1.3. Проанализируйте качество данных

{См. задание на платформе}
-----------

SELECT count(*), count(id)
FROM production.orderitems o ; -- проверяем дубли в orderitems o. По аналогии делаем это с остальными таблицами:

SELECT count(*), count(order_id)
FROM production.orders o ;

SELECT count(*), count(order_id)
FROM production.orderstatuslog o ;

SELECT count(*), count(p.id)
FROM production.products p ;

SELECT count(*), count(u.id)
FROM production.users u ; -- дублей нет

--Проверяем таблицы на пропуски:

SELECT *
FROM production.users u  where u.name is null; --лучше сначала проверить свойства таблицы и найти поля, которые могут быть пустыми.
-- У нас это имя в юзерах, так что проверили только его.

--Также проверяем форматы данных в свойствах таблиц, нас устаривают все форматы, приводить их не надо.


## 1.4. Подготовьте витрину данных

-- вычисляем фактор Frequency
with tab1 as (
select *,
case when o2."key" = 'Closed' then 1 end as orders_amount from production.orderstatuslog o left join production.orderstatuses o2 
on o.status_id = o2.id 
left join production.orders o3 on o.order_id = o3.order_id 
left join production.users u on o3.user_id = u.id 
where o2."key" = 'Closed' and o.dttm >= '2022-01-01'),
tab2 as
(select user_id, sum(orders_amount) as orders_amount
from tab1
group by user_id, orders_amount)
select *, ntile(5) over (order by orders_amount)
from tab2

-- вычисляем фактор Monetary Value
with tab1 as (
select * from production.orderstatuslog o left join production.orderstatuses o2 
on o.status_id = o2.id 
left join production.orders o3 on o.order_id = o3.order_id 
left join production.users u on o3.user_id = u.id
where o2."key" = 'Closed' and o.dttm >= '2022-01-01'),
tab2 as (
select user_id, sum(payment) as orders_sum from tab1
group by user_id)
select *, ntile(5) over (order by orders_sum) from tab2

-- вычисляем фактор Recency
with tab1 as (
select * from production.orderstatuslog o left join production.orderstatuses o2 
on o.status_id = o2.id 
left join production.orders o3 on o.order_id = o3.order_id 
left join production.users u on o3.user_id = u.id
where o2."key" = 'Closed' and o.dttm >= '2022-01-01'),
tab2 as (
select user_id, max(dttm) as last_order
from tab1
group by user_id)
select *, ntile(5) over (order by last_order) from tab2

{См. задание на платформе}
### 1.4.1. Сделайте VIEW для таблиц из базы production.**

{См. задание на платформе}
```SQL
-- вычисляем фактор Frequency
insert into analysis.tmp_rfm_frequency
with tab1 as (
select *,
case when o2."key" = 'Closed' then 1 end as orders_amount from production.orderstatuslog o left join production.orderstatuses o2 
on o.status_id = o2.id 
left join production.orders o3 on o.order_id = o3.order_id 
left join production.users u on o3.user_id = u.id 
where o2."key" = 'Closed' and o.dttm >= '2022-01-01'),
tab2 as
(select user_id, sum(orders_amount) as orders_amount
from tab1
group by user_id, orders_amount)
select user_id, ntile(5) over (order by orders_amount) as Frequency
from tab2

-- вычисляем фактор Monetary Value
insert into analysis.tmp_rfm_monetary_value
with tab1 as (
select * from production.orderstatuslog o left join production.orderstatuses o2 
on o.status_id = o2.id 
left join production.orders o3 on o.order_id = o3.order_id 
left join production.users u on o3.user_id = u.id
where o2."key" = 'Closed' and o.dttm >= '2022-01-01'),
tab2 as (
select user_id, sum(payment) as orders_sum from tab1
group by user_id)
select user_id, ntile(5) over (order by orders_sum) as Monetary_Value from tab2

-- вычисляем фактор Recency
insert into analysis.tmp_rfm_recency
with tab1 as (
select * from production.orderstatuslog o left join production.orderstatuses o2 
on o.status_id = o2.id 
left join production.orders o3 on o.order_id = o3.order_id 
left join production.users u on o3.user_id = u.id
where o2."key" = 'Closed' and o.dttm >= '2022-01-01'),
tab2 as (
select user_id, max(dttm) as last_order
from tab1
group by user_id)
select user_id, ntile(5) over (order by last_order) as Recency from tab2


```

### 1.4.2. Напишите DDL-запрос для создания витрины.**

{См. задание на платформе}
```SQL
create table analysis.dm_rfm_segments 
 (
 user_id INT NOT NULL PRIMARY KEY,
 recency INT NOT NULL CHECK(monetary_value >= 1 AND monetary_value <= 5),
 frequency INT NOT NULL CHECK(monetary_value >= 1 AND monetary_value <= 5),
 monetary_value INT NOT NULL CHECK(monetary_value >= 1 AND monetary_value <= 5)
)


```

### 1.4.3. Напишите SQL запрос для заполнения витрины

{См. задание на платформе}
```SQL
insert into analysis.dm_rfm_segments
select f.user_id, recency, frequency, monetary_value from analysis.tmp_rfm_frequency f join 
analysis.tmp_rfm_monetary_value mv on f.user_id = mv.user_id
join analysis.tmp_rfm_recency r on f.user_id = r.user_id


```



