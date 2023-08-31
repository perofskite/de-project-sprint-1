-- вычисляем фактор Recency
insert into analysis.tmp_rfm_recency
with tab1 as (
select * from  analysis.orders o3 
where order_ts >= '2022-01-01'),
tab2 as (
select user_id , max(order_ts) as last_order
from tab1
group by user_id)
select user_id, ntile(5) over (order by last_order) as Recency from tab2
