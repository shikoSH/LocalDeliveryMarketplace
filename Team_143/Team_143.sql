-- Team_143.sql : our own helpers for Milestone 3.
-- Run AFTER the given database script and seed_data.sql (it only adds objects).
USE LocalDeliveryMarketplace_Team_00;
GO

-- Product categories, for "browse by category".
CREATE VIEW h_ProductCategories
AS
SELECT DISTINCT p.category
FROM Product p
JOIN Business b ON b.business_id = p.business_id
WHERE p.is_available = 1 AND b.status = 'Active';
GO

-- Favorites of a customer (businesses and products) with their names.
CREATE FUNCTION h_MyFavoriteItems (@customer_id INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 'Business' AS item_type, b.business_id AS item_id, b.name AS item_name
    FROM Favorite_Business fb JOIN Business b ON b.business_id = fb.business_id
    WHERE fb.customer_id = @customer_id
    UNION ALL
    SELECT 'Product', p.product_id, p.name
    FROM Favorite_Product fp JOIN Product p ON p.product_id = fp.product_id
    WHERE fp.customer_id = @customer_id
);
GO

-- Ownership checks: the website uses them so a user can only act on own records
-- (several Milestone 2 procedures take only an id and do not know who is asking).
CREATE FUNCTION h_CustomerOwnsOrder (@customer_id INT, @order_id INT)
RETURNS BIT
AS
BEGIN
    RETURN CASE WHEN EXISTS (SELECT 1 FROM Orders o JOIN Cart c ON c.cart_id = o.cart_id
                             WHERE o.order_id = @order_id AND c.customer_id = @customer_id)
                THEN 1 ELSE 0 END;
END;
GO

CREATE FUNCTION h_CustomerOwnsSubOrder (@customer_id INT, @suborder_id INT)
RETURNS BIT
AS
BEGIN
    RETURN CASE WHEN EXISTS (SELECT 1 FROM SubOrder s
                             JOIN Orders o ON o.order_id = s.order_id
                             JOIN Cart c ON c.cart_id = o.cart_id
                             WHERE s.suborder_id = @suborder_id AND c.customer_id = @customer_id)
                THEN 1 ELSE 0 END;
END;
GO

CREATE FUNCTION h_RiderOwnsDelivery (@rider_id INT, @delivery_id INT)
RETURNS BIT
AS
BEGIN
    RETURN CASE WHEN EXISTS (SELECT 1 FROM Delivery WHERE delivery_id = @delivery_id AND rider_id = @rider_id)
                THEN 1 ELSE 0 END;
END;
GO

CREATE FUNCTION h_PartnerOwnsProduct (@partner_id INT, @product_id INT)
RETURNS BIT
AS
BEGIN
    RETURN CASE WHEN EXISTS (SELECT 1 FROM Product p JOIN Business b ON b.business_id = p.business_id
                             WHERE p.product_id = @product_id AND b.partner_id = @partner_id)
                THEN 1 ELSE 0 END;
END;
GO

-- Cart lines of a cart with the business status/hours, for the checkout warnings.
CREATE FUNCTION h_CartBusinessState (@cart_id INT)
RETURNS TABLE
AS
RETURN
(
    SELECT DISTINCT b.business_id, b.name AS business_name, b.status,
           dbo.h_IsBusinessOpen(b.opening_hour, b.closing_hour, CAST(GETDATE() AS TIME)) AS is_open_now
    FROM CartItem ci
    JOIN Product p ON p.product_id = ci.product_id
    JOIN Business b ON b.business_id = p.business_id
    WHERE ci.cart_id = @cart_id
);
GO

-- Most recent day that has orders: default date of the daily revenue page.
CREATE VIEW h_LastOrderDay
AS
SELECT CAST(MAX(order_date) AS DATE) AS last_day FROM Orders;
GO
