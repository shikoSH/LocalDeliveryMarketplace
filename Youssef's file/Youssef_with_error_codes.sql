/* 4.2 c 
Average rating and number of feedbacks of every business (NULL and 0 if none).
Type: View
Name: BusinessRatingsSummary
Input: Nothing
Output: Table (business_id, business_name, avg_rating, ratings_count)
*/ 
GO
CREATE VIEW BusinessRatingsSummary
AS 
SELECT B.business_id, B.name AS business_name, AVG(CAST(F.rating AS DECIMAL(3,2))) AS avg_rating, COUNT(F.rating) AS ratings_count
FROM Business B
LEFT OUTER JOIN SubOrder S ON S.business_id = B.business_id
LEFT OUTER JOIN Feedback F ON F.suborder_id = S.suborder_id
GROUP BY B.business_id, B.name
GO

/* 4.2 f 
Every rider with the number of Delivered deliveries (0 if none) and the average rider rating (NULL if
none).
Type: View
Name: RiderPerformanceSummary
Input: Nothing
Output: Table (rider_id, rider_name, zone_name, completed_deliveries, avg_rating)
*/
GO
CREATE VIEW RiderPerformanceSummary
AS
SELECT R.rider_id, 
       CONCAT(U.first_name, ' ' + U.middle_name, ' ' + U.last_name) AS rider_name, 
       Z.zone_name, 
       COUNT(D.delivered_at) AS completed_deliveries, 
       AVG(CAST(D.rider_rating AS DECIMAL(3,2))) AS avg_rating 
FROM Rider R
INNER JOIN Users U ON U.user_id = R.rider_id
INNER JOIN Zone Z ON Z.zone_id = R.zone_id
LEFT OUTER JOIN Delivery D ON R.rider_id = D.rider_id
GROUP BY R.rider_id, U.first_name, U.middle_name, U.last_name, Z.zone_name
GO
--asked for delivered deliveries so COUNT(delivered_at) ddidnt count rating since may have bad rating (incomplete delivery) so i assumed delivered_at would be best

/* 4.2 h ZoneDeliveryPerformance
Per zone (the order's zone), the number of Delivered deliveries and their average tracking_time,
including zones with none (0 and NULL).
Type: View
Name: ZoneDeliveryPerformance
Input: Nothing
Output: Table (zone_id, zone_name, delivery_count, avg_tracking_time)
*/
GO
CREATE VIEW ZoneDeliveryPerformance
AS 
SELECT Z.zone_id, Z.zone_name, COUNT(D.delivery_id) AS delivery_count, AVG(D.tracking_time) AS avg_tracking_time
FROM Zone Z
LEFT OUTER JOIN Business B ON B.zone_id = Z.zone_id
LEFT OUTER JOIN SubOrder S ON S.business_id = B.business_id
LEFT OUTER JOIN Delivery D ON D.suborder_id = S.suborder_id AND D.delivered_at IS NOT NULL
GROUP BY Z.zone_id, Z.zone_name
GO

/* 4.4 m TopRiders
Top 5 riders by deliveries delivered in a period (ties: smallest rider_id). rider_rank is 1 to 5. Riders with
none are excluded.
Admin type: Super Admin or Zone Admin.
Type: Table-Valued Function
Name: TopRiders
Input: from_date date, to_date date
Output: Table (rider_rank, rider_id, rider_name, completed_delivery_count)
*/
GO
CREATE FUNCTION dbo.TopRiders (@from_date DATE, @to_date DATE)
RETURNS TABLE 
AS 
RETURN
(
    SELECT TOP 5 ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC, R.rider_id) AS rider_rank, 
           R.rider_id, 
           CONCAT(U.first_name, ' ' + U.middle_name, ' ' + U.last_name) AS rider_name, 
           COUNT(*) AS completed_delivery_count
    FROM Delivery D
    INNER JOIN Rider R ON R.rider_id = D.rider_id
    INNER JOIN User U ON U.user_id = R.rider_id
    INNER JOIN Zone Z ON Z.zone_id = R.zone_id
    INNER JOIN Admin A ON Z.zone_id = A.zone_id
    WHERE D.delivered_at IS NOT NULL 
    AND A.role IN ('Super Admin', 'Zone Admin')
    AND (CAST(D.delivered_at AS DATE) BETWEEN @from_date AND @to_date) 
    AND @from_date <= @to_date 
    GROUP BY R.rider_id, U.first_name, U.middle_name, U.last_name
    ORDER BY completed_delivery_count DESC, R.rider_id
);
GO 

/* 4.5 g BusinessFeedbackOverview
My average rating, number of feedbacks and count per star.
Type: Table-Valued Function
Name: BusinessFeedbackOverview
Input: business_id int
Output: Table (avg_rating, number_of_feedbacks, five_star, four_star, three_star, two_star, one_star)
*/
GO
CREATE FUNCTION dbo.BusinessFeedbackOverview (@business_id INT)
RETURNS TABLE 
AS 
RETURN
(
    SELECT AVG(CAST(F.rating AS DECIMAL(3,2))) AS avg_rating, COUNT(*) AS number_of_feedbacks,
    COUNT(CASE WHEN rating = 5 THEN 1 END) AS five_star,
    COUNT(CASE WHEN rating = 4 THEN 1 END) AS four_star,
    COUNT(CASE WHEN rating = 3 THEN 1 END) AS three_star,
    COUNT(CASE WHEN rating = 2 THEN 1 END) AS two_star,
    COUNT(CASE WHEN rating = 1 THEN 1 END) AS one_star
    FROM Feedback F 
    INNER JOIN SubOrder S ON S.suborder_id = F.suborder_id
    WHERE S.business_id = @business_id
);
-- COUNT(*) because id is unique so it must exist for feedback row to exist
GO

/* 4.6 l Submit_Feedback
Leave one feedback for a Delivered SubOrder.
Type: Stored Procedure
Name: Submit_Feedback
Input: suborder_id int, headline varchar(100), description varchar(500), rating int
Output: Nothing
*/
GO
CREATE PROCEDURE Submit_Feedback
    @suborder_id int, 
    @headline varchar(100), 
    @description varchar(500), 
    @rating int
AS
BEGIN
    IF @suborder_id IS NULL OR @headline IS NULL OR @rating IS NULL
    BEGIN
        RETURN -1;
    END
    IF @rating < 1 OR @rating > 5
    BEGIN
        RETURN -1;
    END
    IF NOT EXISTS (SELECT 1 FROM SubOrder WHERE suborder_id = @suborder_id)
    BEGIN
        RETURN -1;  -- suborder does not exist
    END
    IF NOT EXISTS (SELECT 1 FROM SubOrder WHERE suborder_id = @suborder_id AND status = 'Delivered')
    BEGIN
        RETURN -4;  -- wrong status, must be Delivered
    END
    IF EXISTS (SELECT 1 FROM Feedback WHERE suborder_id = @suborder_id)
    BEGIN
        RETURN -2;  -- feedback already exists for this suborder
    END
    INSERT INTO Feedback (headline, description, rating, suborder_id)
        VALUES (@headline, @description, @rating, @suborder_id);

    RETURN 0;
END
GO

/* 4.6 m Rate_Rider
Rate once the rider of a Delivered SubOrder (stored in Delivery.rider_rating).
Type: Stored Procedure
Name: Rate_Rider
Input: suborder_id int, rider_rating int
Output: Nothing
*/
CREATE PROCEDURE Rate_Rider
    @suborder_id INT, @rider_rating INT
AS
BEGIN
    IF @suborder_id IS NULL OR @rider_rating IS NULL OR @rider_rating < 1 OR @rider_rating > 5
    BEGIN
        RETURN -1;
    END
    IF NOT EXISTS (SELECT 1 FROM Delivery WHERE suborder_id = @suborder_id)
    BEGIN
        RETURN -1;  -- no delivery/suborder found
    END
    IF NOT EXISTS (SELECT 1 FROM SubOrder WHERE suborder_id = @suborder_id AND status = 'Delivered')
    BEGIN
        RETURN -4;  -- wrong status, must be Delivered
    END
    IF EXISTS (SELECT 1 FROM Delivery WHERE suborder_id = @suborder_id AND rider_rating IS NOT NULL)
    BEGIN
        RETURN -2;  -- rider already rated
    END
    UPDATE Delivery 
    SET rider_rating = @rider_rating
    WHERE suborder_id = @suborder_id AND rider_rating IS NULL --says only once

    RETURN 0;
END;
GO

/* 4.6 q Recommended_Products
[Hard] Return up to 10 available products from Active businesses that serve the customer's active
address. Include only products the customer has never ordered and whose categories the customer has
ordered from before. Prioritize most ordered categories by the customer, breaking ties by the smallest
product_id.
Type: Table-Valued Function
Name: Recommended_Products
Input: customer_id int
Output: Table (product_id, product_name, business_name, category, final_price)
*/
CREATE FUNCTION dbo.Recommended_Products (@customer_id INT)
RETURNS TABLE 
AS 
RETURN 
(
    SELECT TOP 10 P.product_id, P.name AS product_name, B.name AS business_name, P.category, P.price AS final_price
    FROM Product P
    INNER JOIN Business B ON P.business_id = B.business_id
    INNER JOIN (SELECT  P1.category, COUNT(*) AS order_count
                FROM Product P1 
                INNER JOIN CartItem CI ON CI.product_id = P1.product_id
                INNER JOIN Orders O2 ON CI.cart_id = O2.cart_id
                INNER JOIN Cart C2 ON C2.cart_id = CI.cart_id 
                WHERE C2.customer_id = @customer_id
                GROUP BY P1.category) AS category_count ON P.category = category_count.category
    WHERE B.zone_id = (SELECT zone_id FROM Address WHERE customer_id = @customer_id AND is_active = 1) 
    AND B.status = 'Active' 
    AND P.is_available = 1
    AND P.product_id NOT IN (
            SELECT CI3.product_id
            FROM Orders O
            INNER JOIN CartItem CI3 ON CI3.cart_id = O.cart_id
            INNER JOIN Cart CR ON CR.cart_id = O.cart_id
            WHERE CR.customer_id = @customer_id
    )
    --3adi 3a4an mafee4 nulls since its also a primary key
    ORDER BY category_count.order_count DESC, P.product_id ASC
);
GO
--A customer has exactly one active address (is_active = 1); all other addresses of the customer have

/* 4.7 a Set_Rider_Availability
Set my availability. Unavailable riders keep their current deliveries but get no new ones.
Type: Stored Procedure
Name: Set_Rider_Availability
Input: rider_id int, is_available bit
Output: Nothing
*/
GO
CREATE PROCEDURE Set_Rider_Availability
(@rider_id INT, @is_available BIT)
AS 
BEGIN 
    IF @rider_id IS NULL OR @is_available IS NULL
    BEGIN
        RETURN -1;
    END
    IF NOT EXISTS (SELECT 1 FROM Rider WHERE rider_id = @rider_id)
    BEGIN
        RETURN -3;  -- not a rider
    END
    UPDATE Rider 
    SET is_available = @is_available
    WHERE rider_id = @rider_id

    RETURN 0;
END
GO 

/* 4.7 b My_Active_Deliveries
My active deliveries. (status is the SubOrder status)
Type: Table-Valued Function
Name: My_Active_Deliveries
Input: rider_id int
Output: Table (delivery_id, order_id, suborder_id, business_name, customer_name,
address_description, zone_name, status, assigned_at)
*/
CREATE FUNCTION dbo.My_Active_Deliveries
(@rider_id INT)
RETURNS TABLE 
AS 
RETURN 
(
    SELECT D.delivery_id, O.order_id, S.suborder_id, B.name AS business_name, 
           CONCAT(U.first_name, ' ' + U.middle_name, ' ' + U.last_name) AS customer_name, 
           A.description AS address_description, Z.zone_name, S.status, D.assigned_at
    FROM Delivery D 
    INNER JOIN SubOrder S ON S.suborder_id = D.suborder_id
    INNER JOIN Orders O ON O.order_id = S.order_id
    INNER JOIN Business B ON B.business_id = S.business_id
    INNER JOIN Cart C ON C.cart_id = O.cart_id
    INNER JOIN Users U ON U.user_id = C.customer_id
    INNER JOIN Address A ON A.customer_id = C.customer_id AND A.is_active = 1
    INNER JOIN Zone Z ON A.zone_id = Z.zone_id
    WHERE D.rider_id = @rider_id
    AND S.status IN ('Assigned', 'Picked Up')
);
GO

/* 4.7 c Mark_Picked_Up
Mark an Assigned delivery as Picked Up (its SubOrder goes from Assigned to Picked Up), stamp
picked_up_at and recompute the order status.
Type: Stored Procedure
Name: Mark_Picked_Up
Input: delivery_id int
Output: Nothing
*/
GO
CREATE PROCEDURE Mark_Picked_Up (@delivery_id INT) 
AS 
BEGIN
    DECLARE @suborder_id INT
    DECLARE @order_id INT
    
    SELECT @suborder_id = suborder_id 
    FROM Delivery 
    WHERE delivery_id = @delivery_id

    IF @delivery_id IS NULL OR @suborder_id IS NULL
    BEGIN
        RETURN -1;  -- delivery does not exist
    END
    IF NOT EXISTS (SELECT 1 FROM SubOrder WHERE suborder_id = @suborder_id AND status = 'Assigned')
    BEGIN
        RETURN -4;  -- wrong status, must be Assigned
    END

    UPDATE Delivery 
    SET picked_up_at = CURRENT_TIMESTAMP
    WHERE delivery_id = @delivery_id 

    UPDATE SubOrder 
    SET status = 'Picked Up'
    WHERE suborder_id = @suborder_id

    SELECT @order_id = order_id 
    FROM SubOrder 
    WHERE suborder_id = @suborder_id

    --recompute order status
    UPDATE Orders 
    SET status = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM SubOrder WHERE order_id = @order_id AND status <> 'Cancelled') THEN 'Cancelled'
        WHEN NOT EXISTS (SELECT 1 FROM SubOrder WHERE order_id = @order_id AND status NOT IN ('Delivered', 'Cancelled')) THEN 'Delivered'
        WHEN EXISTS (SELECT 1 FROM SubOrder WHERE order_id = @order_id AND status IN ('Assigned', 'Picked Up', 'Delivered')) THEN 'In Progress'
        ELSE 'Placed' END
    WHERE order_id = @order_id

    RETURN 0;
END
GO

/* 4.7 d Mark_Delivered
Mark a Picked Up delivery as Delivered (its SubOrder goes from Picked Up to Delivered), stamp
delivered_at, store tracking_time in minutes since pickup and recompute the order status.
Type: Stored Procedure
Name: Mark_Delivered
Input: delivery_id int
Output: Nothing
*/
GO
CREATE PROCEDURE Mark_Delivered
(@delivery_id INT)
AS
BEGIN
    DECLARE @suborder_id INT
    DECLARE @order_id INT
    SELECT @suborder_id = suborder_id 
    FROM Delivery 
    WHERE delivery_id = @delivery_id

    IF @delivery_id IS NULL OR @suborder_id IS NULL
    BEGIN
        RETURN -1;  -- delivery does not exist
    END
    IF NOT EXISTS (SELECT 1 FROM SubOrder WHERE suborder_id = @suborder_id AND status = 'Picked Up')
    BEGIN
        RETURN -4;  -- wrong status, must be Picked Up
    END

    UPDATE Delivery 
    SET delivered_at = CURRENT_TIMESTAMP,
        tracking_time = DATEDIFF(MINUTE, picked_up_at, CURRENT_TIMESTAMP)
    WHERE delivery_id = @delivery_id 

    UPDATE SubOrder 
    SET status = 'Delivered'
    WHERE suborder_id = @suborder_id

    SELECT @order_id = order_id 
    FROM SubOrder 
    WHERE suborder_id = @suborder_id

    --recompute order status
    UPDATE Orders 
    SET status = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM SubOrder WHERE order_id = @order_id AND status <> 'Cancelled') THEN 'Cancelled'
        WHEN NOT EXISTS (SELECT 1 FROM SubOrder WHERE order_id = @order_id AND status NOT IN ('Delivered', 'Cancelled')) THEN 'Delivered'
        WHEN EXISTS (SELECT 1 FROM SubOrder WHERE order_id = @order_id AND status IN ('Assigned', 'Picked Up', 'Delivered')) THEN 'In Progress'
        ELSE 'Placed' END
    WHERE order_id = @order_id

    RETURN 0;
END
GO

/* 4.7 e My_Earnings
My earnings for deliveries delivered in a date range.
Type: Table-Valued Function
Name: My_Earnings
Input: rider_id int, from_date date, to_date date
Output: Table (completed_deliveries, total_delivery_fees, total_earnings)
*/

CREATE FUNCTION dbo.My_Earnings 
    (@rider_id INT, @from_date DATE, @to_date DATE)
RETURNS TABLE 
AS 
RETURN 
(
    SELECT 
        COUNT(D.delivery_id) AS completed_deliveries, 
        ISNULL(SUM(S.delivery_fee), 0) AS total_delivery_fees, 
        ISNULL(SUM(S.delivery_fee), 0) * 0.8 AS total_earnings
    FROM Delivery D
    INNER JOIN SubOrder S ON D.suborder_id = S.suborder_id
    WHERE CAST(D.delivered_at AS DATE) BETWEEN @from_date AND @to_date
      AND D.rider_id = @rider_id
      AND D.delivered_at IS NOT NULL
      AND @from_date <= @to_date --invalid or NULL dates give an empty table
      AND EXISTS (SELECT 1 FROM Rider WHERE rider_id = @rider_id) --unknown rider gives an empty table
);
GO

/* 4.7 f My_Rating_Summary
My average rider rating, number of ratings and count per star.
Type: Table-Valued Function
Name: My_Rating_Summary
Input: rider_id int
Output: Table (avg_rating, ratings_count, five_star, four_star, three_star, two_star, one_star)
*/

CREATE FUNCTION dbo.My_Rating_Summary
    (@rider_id INT)
RETURNS TABLE 
AS 
RETURN 
(
    SELECT AVG(CAST(rider_rating AS DECIMAL(3,2))) avg_rating, COUNT(rider_rating) ratings_count,
    COUNT(CASE WHEN rider_rating = 5 THEN 1 END) AS five_star,
    COUNT(CASE WHEN rider_rating = 4 THEN 1 END) AS four_star,
    COUNT(CASE WHEN rider_rating = 3 THEN 1 END) AS three_star,
    COUNT(CASE WHEN rider_rating = 2 THEN 1 END) AS two_star,
    COUNT(CASE WHEN rider_rating = 1 THEN 1 END) AS one_star
    FROM Delivery
    WHERE rider_id = @rider_id
    AND EXISTS (SELECT 1 FROM Rider WHERE rider_id = @rider_id) --unknown rider gives an empty table
)
GO

/* 4.7 g My_Delivery_History
My Delivered and Cancelled deliveries assigned in a date range. (status is the SubOrder status)
Type: Table-Valued Function
Name: My_Delivery_History
Input: rider_id int, from_date date, to_date date
Output: Table (delivery_id, order_id, business_name, status, assigned_at, picked_up_at,
delivered_at, tracking_time)
*/
CREATE FUNCTION dbo.My_Delivery_History
(@rider_id INT, @from_date DATE, @to_date DATE)
RETURNS TABLE 
AS 
RETURN 
(
    SELECT D.delivery_id, S.order_id, B.name AS business_name, S.status, D.assigned_at, D.picked_up_at, D.delivered_at, D.tracking_time
    FROM Delivery D 
    INNER JOIN SubOrder S ON S.suborder_id = D.suborder_id
    INNER JOIN Business B ON B.business_id = S.business_id
    WHERE S.status IN ('Delivered', 'Cancelled') 
    AND CAST(D.assigned_at AS DATE) BETWEEN @from_date AND @to_date
    AND D.rider_id = @rider_id
    AND @from_date <= @to_date --invalid or NULL dates give an empty table
);
GO 

/* 4.8 b Reconcile_Order_Totals
[Hard] Return every order whose total_amount differs from the sum of its SubOrders' total_price and
delivery_fee (cancelled ones included) minus discount_amount, whose payment amount differs from
total_amount, or that has no payment. Do not fix anything.
Type: Table-Valued Function
Name: Reconcile_Order_Totals
Input: Nothing
Output: Table (order_id, expected_total, order_total, payment_amount)
*/
CREATE FUNCTION dbo.Expected_Total
(@order_id INT)
RETURNS DECIMAL(10,2)
AS 
BEGIN 
    DECLARE @out DECIMAL(10,2)
    IF @order_id IS NULL
    BEGIN
        RETURN -1;  -- invalid input
    END
    IF NOT EXISTS (SELECT 1 FROM Orders WHERE order_id = @order_id)
    BEGIN
        RETURN -1;  -- order does not exist
    END
    SELECT  @out = (SUM(S.total_price) + SUM(S.delivery_fee) - O.discount_amount)
    FROM SubOrder S
    INNER JOIN Orders O ON O.order_id = S.order_id
    WHERE O.order_id = @order_id
    GROUP BY O.discount_amount

    RETURN ISNULL(@out,0)
END 
GO

CREATE FUNCTION dbo.Reconcile_Order_Totals
()
RETURNS TABLE
AS
RETURN
(   
    SELECT O.order_id, dbo.Expected_Total(O.order_id) AS expected_total, O.total_amount AS order_total, P.payment_amount
    FROM Orders O 
    LEFT OUTER JOIN Payment P ON P.order_id = O.order_id
    WHERE dbo.Expected_Total(O.order_id) <> O.total_amount OR P.payment_amount <> O.total_amount OR P.payment_amount IS NULL  
);
GO

/* 4.8 d Platform_Health_Snapshot
Dashboard snapshot: Active businesses, available riders, orders placed today, average tracking_time of
today's deliveries and feedbacks rated 2 or less today.
Type: Table-Valued Function
Name: Platform_Health_Snapshot
Input: Nothing
Output: Table (active_businesses, available_riders, orders_today, avg_delivery_time_today,
low_ratings_today) 
*/
CREATE FUNCTION dbo.Platform_Health_Snapshot
()
RETURNS TABLE
AS
RETURN
(
    SELECT (
            SELECT COUNT(*)
            FROM Business
            WHERE status = 'Active'
            ) AS active_businesses, 
            (SELECT COUNT(*)
            FROM Rider R
            WHERE is_available = 1) 
            AS available_riders, 

            (SELECT COUNT(*)
            FROM Orders
            WHERE CAST(order_date AS DATE) = CAST(GETDATE() AS DATE)) 
            AS orders_today, 

            (SELECT AVG(tracking_time)
            FROM Delivery
            WHERE CAST(assigned_at AS DATE) = CAST(GETDATE() AS DATE)) 
            AS avg_delivery_time_today, 

            (SELECT COUNT(*) 
            FROM Feedback 
            WHERE rating<=2 
            AND CAST(feedback_date AS DATE) = CAST(GETDATE() AS DATE)) AS low_ratings_today
)
GO
