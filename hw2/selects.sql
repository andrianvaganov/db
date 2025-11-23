-- 1. Вывести все уникальные бренды, у которых есть хотя бы один продукт со стандартной стоимостью выше 1500 долларов,
-- и суммарными продажами не менее 1000 единиц
select distinct p.brand from product p where p.standard_cost > 1500 and
        (
            select sum(oi.quantity)
            from order_items oi
            where oi.product_id = p.product_id
        ) >= 1000;

-- 2. Для каждого дня в диапазоне с 2017-04-01 по 2017-04-09 включительно вывести количество подтвержденных
-- онлайн-заказов и количество уникальных клиентов, совершивших эти заказы

select distinct o.order_date,
                (
                    select count(o2.order_id)
                    from orders o2 where o.order_date = o2.order_date and o2.order_status = 'Approved' and o2.online_order = true
                ) as order_count,
                (
                    select count(distinct o2.customer_id)
                    from orders o2 where o.order_date = o2.order_date and o2.order_status = 'Approved' and o2.online_order = true
                ) as unique_customers
from orders o
where (o.order_date between '2017-04-01' and '2017-04-09')
  and o.order_status = 'Approved'
  and o.online_order = true

-- 3. Вывести профессии клиентов:
-- из сферы IT, чья профессия начинается с Senior;
-- из сферы Financial Services, чья профессия начинается с Lead.
-- Для обеих групп учитывать только клиентов старше 35 лет. Объединить выборки с помощью UNION ALL.
select distinct c.job_title
from customer c
where c.job_title like 'Senior%' and c.job_industry_category = 'IT' and c.dob < (select (now() - interval '35 years')::date)
union all
select distinct c2.job_title
from customer c2
where c2.job_title like 'Lead%' and c2.job_industry_category = 'Financial Services' and c2.dob < (select (now() - interval '35 years')::date);

--4. Вывести бренды, которые были куплены клиентами из сферы Financial Services, но не были куплены клиентами из сферы IT
select distinct p.brand from order_items oi
                                 left join orders o on oi.order_id = o.order_id
                                 left join product p on p.product_id = oi.product_id
                                 left join customer c on c.customer_id = o.customer_id
WHERE c.job_industry_category = 'Financial Services'
  and p.brand not in
      (
          select distinct p2.brand from order_items oi2
                                            left join orders o2 on oi2.order_id = o2.order_id
                                            left join product p2 on p2.product_id = oi2.product_id
                                            left join customer c2 on c2.customer_id = o2.customer_id
          where c2.job_industry_category = 'IT'
      )


-- 5. Вывести 10 клиентов (ID, имя, фамилия), которые совершили наибольшее количество онлайн-заказов (в штуках)
-- брендов Giant Bicycles, Norco Bicycles, Trek Bicycles, при условии, что они активны и имеют оценку имущества
-- (property_valuation) выше среднего среди клиентов из того же штата.

select c.customer_id, c.first_name, c.last_name
from order_items oi
         join orders o on oi.order_id = o.order_id
         join product p on p.product_id = oi.product_id
         join customer c on c.customer_id = o.customer_id
where o.online_order = true
  and c.deceased_indicator = 'N'
  and p.brand in ('Giant Bicycles', 'Norco Bicycles', 'Trek Bicycles')
  and c.property_valuation::numeric > (
    select avg(property_valuation::numeric)
    from customer c2
    where c2.state = c.state
)
group by c.customer_id, c.first_name, c.last_name
order by count(*) desc
    limit 10


-- 6. Вывести всех клиентов (ID, имя, фамилия), у которых нет подтвержденных онлайн-заказов за последний год,
-- но при этом они владеют автомобилем и их сегмент благосостояния не Mass Customer.
select
    c.customer_id,
    c.first_name,
    c.last_name
from customer c
where c.owns_car = 'Yes'
  and not c.wealth_segment = 'Mass Customer'
  and not exists (
        select 1
        from orders o
        where o.customer_id = c.customer_id
          and o.online_order = true
          and o.order_status = 'Approved'
          and o.order_date >= current_date - interval '1 year'
    );

-- 7. Вывести всех клиентов из сферы 'IT' (ID, имя, фамилия), которые купили 2 из 5 продуктов с самой высокой list_price в продуктовой линейке Road.

select
    c.customer_id,
    c.first_name,
    c.last_name
from customer c
where c.job_industry_category = 'IT'
  and (
    select count(distinct oi.product_id)
    from orders o
             join order_items oi on oi.order_id = o.order_id
             join product p      on p.product_id = oi.product_id
    where o.customer_id = c.customer_id
      and p.product_id in (
        select p2.product_id
        from product p2
        where p2.product_line = 'Road'
        order by p2.list_price desc
    limit 5
    )
    ) >= 2;

--8 Вывести клиентов (ID, имя, фамилия, сфера деятельности) из сфер IT или Health, которые совершили
-- не менее 3 подтвержденных заказов в период 2017-01-01 по 2017-03-01,
-- и при этом их общий доход от этих заказов превышает 10 000 долларов.
--Разделить вывод на две группы (IT и Health) с помощью UNION.

select
    c.customer_id,
    c.first_name,
    c.last_name,
    c.job_industry_category
from customer c
where c.job_industry_category = 'IT'
  and (
          select count(distinct o.order_id)
          from orders o
          where o.customer_id = c.customer_id
            and o.order_status = 'Approved'
            and o.order_date between date '2017-01-01' and date '2017-03-01'
      ) >= 3
  and (
          select sum(oi.quantity * oi.item_list_price_at_sale)
          from orders o
                   join order_items oi on oi.order_id = o.order_id
          where o.customer_id = c.customer_id
            and o.order_status = 'Approved'
            and o.order_date between date '2017-01-01' and date '2017-03-01'
      ) > 10000
union
select
    c.customer_id,
    c.first_name,
    c.last_name,
    c.job_industry_category
from customer c
where c.job_industry_category = 'Health'
  and (
          select count(distinct o.order_id)
          from orders o
          where o.customer_id = c.customer_id
            and o.order_status = 'Approved'
            and o.order_date between date '2017-01-01' and date '2017-03-01'
      ) >= 3
  and (
          select sum(oi.quantity * oi.item_list_price_at_sale)
          from orders o
                   join order_items oi on oi.order_id = o.order_id
          where o.customer_id = c.customer_id
            and o.order_status = 'Approved'
            and o.order_date between date '2017-01-01' and date '2017-03-01'
      ) > 10000;































































