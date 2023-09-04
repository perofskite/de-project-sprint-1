-- вычисляем фактор Recency 
insert into analysis.tmp_rfm_recency 
with tab1 as 
(select o.user_id, max(case when o2.key = 'Closed' then order_ts::timestamp else null end) as last_order from analysis.orders o 
left join analysis.orderstatuses o2 on o.status = o2.id 
where order_ts >= '2022-01-01'
group by o.user_id)
select 
user_id, NTILE(5) over (order by last_order::timestamp nulls first) as recency
from tab1
