USE MUSIC  -- activating the database

select * from employee$

/* Q1: Who is the senior most employee based on job title? */ --mohan madan is the senior general manager 

select top 1 e.title , e.first_name,e.last_name from employee$ e
order by e.levels desc

/* Q2: Which countries have the most Invoices? */ -- USA 

select  count(*) invoice_count, i.billing_country from  invoice$ i
group by i.billing_country
order by invoice_count desc

/* Q3: What are top 3 values of total invoice? */
select top 3 total from invoice$ 
order by total desc

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */ --- answwer is Prague

	select top 1 i.billing_city,sum(i.total) as Invoice_total  
	from invoice$ i
	group by i.billing_city
	order by Invoice_total desc

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/ -- Frantisek wichterlova

select top 1 c.customer_id, c.first_name,c.last_name, sum(i.total) as total_spent
from customer$ c 
join invoice$ i 
on c.customer_id=i.customer_id
group by c.customer_id,c.first_name,c.last_name
order by total_spent  desc


/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

-- simple join the related table and filter the data for rock genre

SELECT DISTINCT email AS Email,first_name AS FirstName, last_name AS LastName, g.name AS Name
FROM customer$ c
JOIN invoice$ i
ON i.customer_id=c.customer_id
JOIN invoice_line$ iL
ON iL.invoice_id=i.invoice_id
JOIN track$ t
ON t.track_id=iL.track_id
JOIN genre$ g
ON g.genre_id=t.genre_id
WHERE g.name = 'Rock'
ORDER BY email;


/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

--filkter the data for rock genre by joining the tables and then retrun the  artirst name

select top 10 ar.artist_id,ar.name , count(ar.artist_id) as no_of_songs
from track$ t
join album$ a
on a.album_id=t.album_id
join artist$ ar
on a.artist_id=ar.artist_id
join genre$ g 
on g.genre_id=t.genre_id
where g.name = 'Rock'
group by ar.artist_id,ar.name
order by no_of_songs desc


/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

--use subquery to find avg of song lenghth then use greater than operator to finf the track names 

select t.name , t.milliseconds from track$ t
where  t.milliseconds >(
select avg(t.milliseconds) from track$ t 
)
order by t.milliseconds desc


/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */


-- use of cte to create a tempory table to first get the best selling artist for thos simply we need to find the total sales of a artirst by multiplyin unit price and quantity
--next using this temporary table join it with customer table to find the amount spent by customer firo the best artist

with best_seeling_artirst as (

select top 1  ar.artist_id,ar.name, sum(il.unit_price*il.quantity) as total_sales
from invoice_line$ iL
join track$ t
on il.track_id=t.track_id
join album$ al 
on t.album_id=al.album_id
join artist$ ar
on al.artist_id=ar.artist_id
group by ar.artist_id,ar.name
order by 3 desc

)

select c.customer_id,c.first_name,c.last_name,bsa.name,sum(il.unit_price*il.quantity) as amount_spent
from customer$ c
join invoice$ i
on i.customer_id=c.customer_id
join invoice_line$ iL
on il.invoice_id=i.invoice_id
join track$ t
on t.track_id=iL.track_id
join album$ al
on al.album_id=t.album_id
join best_seeling_artirst bsa 
on bsa.artist_id=al.artist_id
group by c.customer_id,c.first_name,c.last_name,bsa.name
order by 5 desc

/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

-- use cte to create a temporary table popularr genre which can be done by counting the quantity of song sold
-- then using row number function we give each genre heard by country a row number order by the purchases
-- to select the highest purchase we use where clause


with popular_genre as (

select count(il.quantity) as purchases ,i.billing_country,g.genre_id,g.name,
ROW_NUMBER() over (partition by i.billing_country order by count(il.quantity) desc) as Rowno
from invoice$ i
join invoice_line$ il
on i.invoice_id=il.invoice_id
join track$ t
on il.track_id=t.track_id
join genre$ g
on t.genre_id=g.genre_id
group by i.billing_country,g.genre_id,g.name

)

select * from popular_genre where Rowno <=1


/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */


--similar to the above question use find the total spent using sum function
--then using row number and partition we find each country total spent amount
--then using where clause we find the customer that as spent most for each country

with customer_with_country as (

select c.customer_id,c.first_name,c.last_name,i.billing_country,sum(i.total) as total_spent,
ROW_NUMBER()
over(partition by i.billing_country order by sum(i.total) desc) as Rowno

from invoice$ i
join customer$ c
on i.customer_id=c.customer_id
group by c.customer_id,c.first_name,c.last_name,i.billing_country
)
select * from customer_with_country where Rowno<=1




