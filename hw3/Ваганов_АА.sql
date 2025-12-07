-- 1. Вывести распределение (количество) клиентов по сферам деятельности, отсортировав результат по убыванию количества.
select job_industry_category, count(job_industry_category)
from customer c
group by job_industry_category
order by count(job_industry_category) desc

-- 2. Найти общую сумму дохода (list_price*quantity) по всем подтвержденным заказам за каждый месяц по сферам деятельности клиентов.
-- Отсортировать результат по году, месяцу и сфере деятельности.
select EXTRACT(YEAR FROM o.order_date::date) AS year, EXTRACT(MONTH FROM o.order_date::date) AS month, sum(p.list_price*oi.quantity), c.job_industry_category
from order_items oi
    join orders o
on oi.order_id = o.order_id
    join product p on p.product_id = oi.product_id
    join customer c on c.customer_id = o.customer_id
where order_status = 'Approved'
group by year, month, c.job_industry_category
order by year, month, c.job_industry_category

-- 3. Вывести количество уникальных онлайн-заказов для всех брендов в рамках подтвержденных заказов клиентов из сферы IT.
-- Включить бренды, у которых нет онлайн-заказов от IT-клиентов, — для них должно быть указано количество 0.
select p.brand,
       count(distinct o.order_id) as it_online_orders_cnt
from product p
         left join order_items oi on oi.product_id = p.product_id
         left join orders o on o.order_id = oi.order_id
    and o.online_order = true
    and o.order_status = 'Approved'
         left join customer c on c.customer_id = o.customer_id
    and c.job_industry_category = 'IT'
group by p.brand
order by p.brand;


-- 4. Найти по всем клиентам: сумму всех заказов (общего дохода), максимум, минимум и количество заказов,
-- а также среднюю сумму заказа по каждому клиенту.
-- Отсортировать результат по убыванию суммы всех заказов и количества заказов.
-- Выполнить двумя способами: используя только GROUP BY и используя только оконные функции.
-- Сравнить результат.
select c.customer_id, sum(p.list_price * oi.quantity),
       max(p.list_price * oi.quantity),
       min(p.list_price * oi.quantity),
       count(o.order_id),
       avg(p.list_price * oi.quantity)
from order_items oi
         join orders o on oi.order_id = o.order_id
         join customer c on c.customer_id = o.customer_id
         join product p on p.product_id = oi.product_id
where order_status = 'Approved'
group by c.customer_id
order by sum(p.list_price * oi.quantity) desc, count(o.order_id) desc

-- 5. Найти имена и фамилии клиентов с топ-3 минимальной и топ-3 максимальной суммой транзакций за весь период
--(учесть клиентов, у которых нет заказов, приняв их сумму транзакций за 0).
select first_name, last_name, trx_amount_sum, 'top-3 MAX' as flag
from (
         select *, DENSE_RANK() OVER(ORDER BY trx_amount_sum desc) AS Dense_Rank
         from (
                  select c.first_name, c.last_name, sum(p.list_price * oi.quantity) as trx_amount_sum
                  from order_items oi
                           join orders o on oi.order_id = o.order_id
                           join product p on p.product_id = oi.product_id
                           join customer c on c.customer_id = o.customer_id
                  group by c.customer_id
              ))
where dense_rank < 4
union
select first_name,
       last_name,
       trx_amount_sum as trx_amount_sum,
       'top-3 MIN'    as flag
from (
         select *,
                dense_rank() over (order by trx_amount_sum) as dense_rank
         from (
                  select c.customer_id,
                         c.first_name,
                         c.last_name,
                         coalesce(sum(p.list_price * oi.quantity), 0) as trx_amount_sum
                  from customer c
                           left join orders o on c.customer_id = o.customer_id
                           left join order_items oi on o.order_id = oi.order_id
                           left join product p on p.product_id = oi.product_id
                  group by c.customer_id, c.first_name, c.last_name
              )
     )
where dense_rank < 4
order by trx_amount_sum desc;





