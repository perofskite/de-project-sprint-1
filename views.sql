-- создаем представления в схеме analysis

CREATE or replace view analysis.orderitems as select * from production.orderitems o 

CREATE or replace view analysis.orders as select * from production.orders

CREATE or replace view analysis.users as select * from production.users

CREATE or replace view analysis.products as select * from production.products

CREATE or replace view analysis.orderstatuses as select * from production.orderstatuses