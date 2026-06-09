
/*
Murali Manohara
-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
use new_wheels;
SELECT * FROM new_wheels.customer_t;
select * from new_wheels.order_t;
select * from new_wheels.product_t;
select * from new_wheels.shipper_t;


/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/
select state,count(customer_id) as customer_count from customer_t
group by state
order by count(customer_id)desc;
-- Observations: Shows which states have the most customers, helping identify strong and weak markets

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.    */
select quarter_number,round(avg(case
when customer_feedback = 'Very Bad' then 1
when customer_feedback = 'Bad' then 2
when customer_feedback = 'Okay' then 3
when customer_feedback = 'Good' then 4
when customer_feedback = 'Very Good' then 5
else null end),2) as customer_rating , count(customer_feedback)
from order_t
group by quarter_number
order by quarter_number;
-- Observations: Average ratings by quarter reveal if customer satisfaction is improving or declining.

/* [Q3] Are customers getting more dissatisfied over time?
Hint: Need the percentage of different types of customer feedback in each quarter. 
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  And find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback.   */
select quarter, customer_feedback, feedback_count,round(feedback_count * 100.0 / total_feedback_in_quarter,2) as pct_of_quarter
from 
( select o.quarter_number as quarter, o.customer_feedback, count(*) as feedback_count,
sum(count(*)) over (partition by o.quarter_number) as total_feedback_in_quarter
from order_t o
group by o.quarter_number, o.customer_feedback ) t
order by quarter, feedback_count desc;
-- Observations: Feedback percentages show how much of each quarter’s feedback is negative or positive.

/* [Q4] Which are the top 5 vehicle makers preferred by the customer.
Hint: For each vehicle make what is the count of the customers. */
select vehicle_maker,count(customer_id) from product_t p join order_t o 
on p.product_id = o.product_id
group by vehicle_maker
order by count(customer_id) desc
limit 5;
-- observation: Highlights the top vehicle makers customers prefer the most.

/* [Q5] What is the most preferred vehicle make in each state? */
select state, vehicle_maker, customer_count
from
(select state, vehicle_maker, count(distinct o.customer_id) as customer_count,     -- NOTE that distinct doesn't make any diff here
row_number() over (partition by state order by count(distinct o.customer_id) desc) as rn
from order_t o join customer_t c
on o.customer_id = c.customer_id join product_t p
on o.product_id = p.product_id 
group by c.state, p.vehicle_maker) temp
where rn = 1;
-- observation: Shows the most preferred vehicle maker in each state, useful for regional planning.

-- -----------------------------------------------------------------------------------------------------------------------------------
/*QUESTIONS RELATED TO REVENUE and ORDERS 
-- [Q6] What is the trend of number of orders by quarters?
Hint: Count the number of orders for each quarter.*/
select quarter_number,count(order_id) as number_of_orders from order_t
group by quarter_number
order by quarter_number;
-- Observations: Quarterly order counts show whether demand is rising or falling.

/* [Q7] What is the quarter over quarter % change in revenue? 
Hint: Quarter over Quarter percentage change in revenue means 
what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
*/
with quarter_revenue as 
(select quarter_number, round(sum(vehicle_price * quantity * (1 - ifnull(discount,0))),2) as revenue
from order_t
group by quarter_number)
select q1.quarter_number as quarter, q1.revenue, round( (q1.revenue - coalesce(q0.revenue,0)) * 100.0 / nullif(coalesce(q0.revenue,0),0),2) as pct_change_vs_prev_quarter
from quarter_revenue q1 left join quarter_revenue q0
on q0.quarter_number = q1.quarter_number - 1
order by q1.quarter_number;

-- OR

with quarter_revenue as 
(select quarter_number,sum(vehicle_price * quantity * (1 - ifnull(discount,0))) as revenue
from order_t
group by quarter_number)
select q1.quarter_number as quarter,q1.revenue,round((q1.revenue - q0.revenue) * 100 / q0.revenue,2) as qo_q_pct_change
from quarter_revenue q1 join quarter_revenue q0
on q1.quarter_number = q0.quarter_number + 1
order by q1.quarter_number;
-- Observations: Quarter-over-quarter revenue change indicates growth or decline in business health.

/* [Q8] What is the trend of revenue and orders by quarters?
Hint: Find out the sum of revenue and count the number of orders for each quarter.*/
select quarter_number as quarter, count(*) as orders_count,round(sum(vehicle_price * quantity * (1 - ifnull(discount,0))),2) as total_revenue
from order_t
group by quarter_number
order by quarter_number;
-- Observations: Shows both revenue and orders per quarter to understand whether volume or pricing is driving trends.

-- ------------------------------------------------------------------------------------------------------------------------------------
/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?
Hint: Find out the average of discount for each credit card type.*/
select credit_card_type, round(avg(discount),4) as avg_discount,count(order_id) as orders_count
from order_t o join customer_t c
on o.customer_id = c.customer_id
group by credit_card_type
order by avg_discount desc;
-- Observations: Reveals which credit card types tend to receive higher or lower discounts.

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.. */
    
select quarter_number as quarter, round(avg(datediff(ship_date, order_date)),2) as avg_ship_days, count(*) as orders_shipped
from order_t
where ship_date is not null and order_date is not null
group by quarter_number
order by quarter_number;
-- Observations: Average shipping days per quarter show if delivery speed is getting better or worse.
