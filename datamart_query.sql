insert into analysis.dm_rfm_segments
select f.user_id, recency, frequency, monetary_value from analysis.tmp_rfm_frequency f join 
analysis.tmp_rfm_monetary_value mv on f.user_id = mv.user_id
join analysis.tmp_rfm_recency r on f.user_id = r.user_id

|user_id|recency|frequency|monetary_value|
|-------|-------|---------|--------------|
|0      |1      |3        |4             |
|1      |4      |3        |3             |
|2      |2      |3        |5             |
|3      |2      |3        |3             |
|4      |4      |3        |3             |
|5      |5      |5        |5             |
|6      |1      |4        |5             |
|7      |4      |2        |2             |
|8      |1      |1        |3             |
|9      |1      |2        |2             |
