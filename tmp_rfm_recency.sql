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