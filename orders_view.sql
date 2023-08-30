create or replace view analysis.orders as
with tab1 as (
select order_id, max(dttm) as dt from production.orderstatuslog
group by order_id),
tab2 as (
select * from production.orderstatuslog),
tab3 as (
select tab1.order_id, status_id from tab1 join tab2 on tab1.order_id = tab2.order_id and
tab1.dt = tab2.dttm)
select o.order_id, o.order_ts, o.user_id, o.bonus_payment,
o.payment, o."cost", o.bonus_grant, tab3.status_id as status from production.orders o full join tab3 on tab3.order_id = o.order_id 