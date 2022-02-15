CREATE SCHEMA dannys_diner;
-- SET search_path = dannys_diner;

CREATE TABLE dannys_diner.sales (
    customer_id VARCHAR(1),
    order_date DATE,
    product_id INTEGER
);

INSERT INTO dannys_diner.sales
  (customer_id,order_date,product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE dannys_diner.menu (
    product_id INTEGER,
    product_name VARCHAR(5),
    price INTEGER
);

INSERT INTO dannys_diner.menu
  (product_id,product_name,price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE dannys_diner.members (
    customer_id VARCHAR(1),
    join_date DATE
);

INSERT INTO dannys_diner.members
  (customer_id,join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
-- What is the total amount each customer spent at the restaurant?

SELECT sales.customer_id, SUM(menu.price) 'total sales' FROM dannys_diner.sales sales
left JOIN dannys_diner.menu menu on menu.product_id=sales.product_id
GROUP BY customer_id;

-- How many days has each customer visited the restaurant?

-- solution 1
SELECT customer_id, COUNT(distinct(order_date)) as 'Total Visits'
FROM dannys_diner.sales sales GROUP BY customer_id;

-- solution 2
SELECT customer_id, COUNT(customer_id) FROM
(SELECT sales.customer_id, COUNT(sales.customer_id)
FROM dannys_diner.sales sales GROUP BY sales.order_date , sales.customer_id) a
GROUP BY customer_id;


-- What was the first item from the menu purchased by each customer?

with tbl1 as 
(select *, rank() over (partition by sales.customer_id order by sales.order_date) as row_num
from dannys_diner.sales ) 
select tbl1.customer_id, tbl1.order_date, menu.product_name from tbl1
left join dannys_diner.menu menu on tbl1.product_id = menu.product_id
where tbl1.row_num=1;

-- What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT m.product_name, COUNT(s.product_id) count FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m ON m.product_id = s.product_id
GROUP BY s.product_id ORDER BY count DESC limit 1;

-- Which item was the most popular for each customer?

with cte as (select s.customer_id, m.product_name, count(s.product_id) order_count,
rank() over (partition by customer_id order by count(s.product_id) desc ) rnk from dannys_diner.sales s
left join dannys_diner.menu m on m.product_id=s.product_id 
group by s.customer_id, s.product_id)
select customer_id, product_name, order_count from cte where rnk=1;

-- Which item was purchased first by the customer after they became a member?

with cte as (select s.customer_id,mem.join_date,s.order_date,mnu.product_name,
row_number() over (partition by customer_id order by order_date) row_num
 from dannys_diner.sales s
left join dannys_diner.members mem on s.customer_id=mem.customer_id
left join dannys_diner.menu mnu on s.product_id=mnu.product_id 
where join_date<order_date 
order by customer_id,order_date)
select customer_id,join_date,order_date,product_name from cte where row_num=1;

-- Which item was purchased just before the customer became a member?

with cte as (select s.customer_id,mem.join_date,s.order_date,mnu.product_name,
rank() over (partition by customer_id order by order_date desc) rnk
 from dannys_diner.sales s
left join dannys_diner.members mem on s.customer_id=mem.customer_id
left join dannys_diner.menu mnu on s.product_id=mnu.product_id 
where join_date>order_date 
order by customer_id,order_date)
select customer_id,join_date,order_date,product_name from cte where rnk=1;

-- What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, COUNT(*) 'total items', SUM(m.price) 'amount spent' FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m ON s.product_id = m.product_id
LEFT JOIN dannys_diner.members me ON me.customer_id = s.customer_id
WHERE s.order_date < me.join_date GROUP BY customer_id;

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier,
-- how many points would each customer have?
@
with point_tbl as (
select s.customer_id,order_date,m.product_id,product_name,price,
case 
	when m.product_id =1 then price * 20
	else price * 10
end as points 
from dannys_diner.sales s 
left join dannys_diner.menu m on s.product_id=m.product_id
join dannys_diner.members mem on mem.customer_id=s.customer_id)
select customer_id, sum(points) 'total points' from point_tbl
group by customer_id order by customer_id;

-- In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?

with point_tbl as (
select s.customer_id,order_date,m.product_id,product_name,price,join_date,
case 
	when order_date between join_date and date_add(join_date, interval 6 day) then price * 20
	when m.product_id = 1 then price * 20
	else price * 10
end as points 
from dannys_diner.sales s 
left join dannys_diner.menu m on s.product_id=m.product_id
join dannys_diner.members mem on mem.customer_id=s.customer_id)
select customer_id, sum(points) 'total points' from point_tbl
where order_date < STR_TO_DATE('31-01-2021','%d-%m-%Y')
group by customer_id order by customer_id;
