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