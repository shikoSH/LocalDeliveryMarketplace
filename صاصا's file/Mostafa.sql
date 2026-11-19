----------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------- helpers ---------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

-- Name: Mostafa Ahmed Emam
-- ID: 64-14029

--------------------------------------------------- functions --------------------------------------------------------------

CREATE FUNCTION dbo.GetBusinessType (@business_id INT)
RETURNS VARCHAR(20)
AS
BEGIN
	DECLARE @type VARCHAR(20) = NULL;

	IF EXISTS (SELECT 1 FROM Restaurant WHERE business_id = @business_id)
		SET @type = 'Restaurant';
	ELSE IF EXISTS (SELECT 1 FROM Pharmacy WHERE business_id = @business_id)
		SET @type = 'Pharmacy';

		RETURN @type;
END;
GO


CREATE FUNCTION dbo.IsBusinessOpen (@business_id INT, @current_time TIME)
RETURNS BIT
AS
BEGIN
	DECLARE @opening_hour TIME, @closing_hour TIME;
	SELECT @opening_hour = b.opening_hour, @closing_hour = b.closing_hour
	FROM Business b
	WHERE b.business_id = @business_id;

	IF @opening_hour = @closing_hour
		RETURN 1;
	IF @opening_hour < @closing_hour
		IF @opening_hour <= @current_time AND @current_time < @closing_hour
			RETURN 1;
		ELSE
			RETURN 0;

	IF @opening_hour <= @current_time OR @current_time < @closing_hour
		RETURN 1;
	ELSE
		RETURN 0;

	RETURN 0;
END;
GO


CREATE FUNCTION dbo.GetBusinessStatus (@business_id INT)
RETURNS VARCHAR(20)
AS
BEGIN
	DECLARE @business_status VARCHAR(20);
	SELECT @business_status = b.status
	FROM Business b
	WHERE b.business_id = @business_id;

	RETURN @business_status;
END
GO
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------- allBusinessProfiles --------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

-- Name: Mostafa Ahmed Emam
-- ID: 64-14029
/*
Questions :
*/

CREATE VIEW allBusinessProfiles
AS
	SELECT
		b.business_id,
		b.name AS business_name,
		dbo.GetBusinessType(b.business_id) AS business_type,
		z.zone_name,
		u.first_name + ' ' + u.last_name AS partner_name,
		b.status,
		b.opening_hour,
		b.closing_hour
	FROM Business b
	LEFT JOIN Zone z ON b.zone_id = z.zone_id
	LEFT JOIN Users u ON b.partner_id = u.user_id;
GO

----------------------------------------------------------------------------------------------------------------------------
-------------------------------------------- PendingBusinessApprovals ------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

-- Name: Mostafa Ahmed Emam
-- ID: 64-14029
/*
Questions :
*/

CREATE VIEW PendingBusinessApprovals
AS
	SELECT
		bp.business_id,
		bp.business_name,
		bp.business_type,
		bp.zone_name,
		bp.partner_name
	FROM allBusinessProfiles bp
	WHERE bp.status = 'Pending';
GO

----------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------- My_Favorites ----------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

-- Name: Mostafa Ahmed Emam
-- ID: 64-14029
/*
Questions :
	1. should the function make sure that the business is opened at current time ?
		- The implementation checks the current time if the business is opened
*/

CREATE FUNCTION dbo.My_Favorites (@customer_id int)
RETURNS TABLE
AS
RETURN
(
	SELECT
		fp.product_id,
		p.name AS product_name,
		b.name AS business_name,
		CAST(
			CASE
				WHEN dbo.IsBusinessOpen(b.business_id, CAST(GETDATE() AS TIME)) = 1 AND b.status = 'Active' AND p.is_available = 1 THEN 1
				ELSE 0
			END
			AS bit
		) AS is_orderable
	FROM Favorite_Product fp
	LEFT JOIN Product  p ON fp.product_id = p.product_id
	LEFT JOIN Business b ON p.business_id = b.business_id
	WHERE fp.customer_id = @customer_id
);
GO

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------- Set_Product_Promotion ------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

-- Name: Mostafa Ahmed Emam
-- ID: 64-14029
/*
Questions :
*/

CREATE PROCEDURE Set_Product_Promotion
	@product_id      INT,
	@discount_amount DECIMAL(10, 2)
AS
BEGIN
	DECLARE @price DECIMAL(10, 2);
	SELECT @price = p.price
	FROM Product p
	WHERE p.product_id = @product_id;

	IF @discount_amount IS NULL OR @discount_amount < 0 OR 2 * @discount_amount > @price
		RETURN -1;

	UPDATE p
	SET p.discount_amount = @discount_amount
	FROM Product p
	WHERE p.product_id = @product_id;

	RETURN 0;
END;
GO

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------- Toggle_Product_Status ------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

-- Name: Mostafa Ahmed Emam
-- ID: 64-14029
/*
Questions :
	1. what is is_available is it the status that the product end up in or the current status of the product ? 
		- The implementation is based that it's the status that the product should end up in.
*/

CREATE PROCEDURE Toggle_Product_Status
	@product_id   INT,
	@is_available BIT
AS
BEGIN
	DECLARE @business_status VARCHAR(20), @business_id INT;
	SELECT @business_id = p.business_id
	FROM Product p
	WHERE p.product_id = @product_id;

	SET @business_status = dbo.GetBusinessStatus(@business_id);

	IF @is_available IS NULL
		RETURN -1;

	IF @business_status = 'Suspended' AND @is_available = 1
		RETURN -4;

	UPDATE p
	SET p.is_available = @is_available
	FROM Product p
	WHERE p.product_id = @product_id;

	RETURN 0;
END;
GO

----------------------------------------------------------------------------------------------------------------------------
------------------------------------------------ Update_Business_Info ------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

-- Name: Mostafa Ahmed Emam
-- ID: 64-14029
/*
Questions :
*/

CREATE PROCEDURE Update_Business_Info
	@business_id  INT,
	@opening_hour TIME,
	@closing_hour TIME,
	@phone        CHAR(11),
	@link_website VARCHAR(255)
AS
BEGIN
	IF @opening_hour IS NULL OR @closing_hour IS NULL OR @phone IS NULL
		RETURN -1;

	IF @phone LIKE '%[^0-9]%' OR LEN(@phone) != 11
		RETURN -1;

	IF EXISTS (SELECT 1 FROM Business_Phone bp WHERE bp.business_id = @business_id AND bp.phone = @phone)
		RETURN -2;

	UPDATE b
	SET b.opening_hour = @opening_hour, b.closing_hour = @closing_hour, b.link_website = @link_website
	FROM Business b
	WHERE b.business_id = @business_id;

	INSERT INTO Business_Phone (business_id, phone)
	VALUES (@business_id, @phone);

	RETURN 0;
END;
GO

----------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------- Upsert_Product --------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

-- Name: Mostafa Ahmed Emam
-- ID: 64-14029
/*
Questions :
*/

CREATE PROCEDURE Upsert_Product
	@business_id  INT,
	@product_id   INT,
	@name         VARCHAR(100),
	@description  VARCHAR(255),
	@category     VARCHAR(50),
	@price        DECIMAL(10,2),
	@is_available BIT
AS
BEGIN
	DECLARE @business_status VARCHAR(20), @product_business_id INT, @product_discount DECIMAL(10, 2);
	SELECT @product_business_id = p.business_id, @product_discount = p.discount_amount
	FROM Product p
	WHERE p.product_id = @product_id;

	SET @business_status = dbo.GetBusinessStatus(@business_id);


	IF @name IS NULL OR @category IS NULL OR @price IS NULL OR @is_available IS NULL
		RETURN -1;
	
	IF @price <= 0
		RETURN -1;

	IF @business_status = 'Suspended'
		RETURN -4;

	IF @product_id IS NOT NULL
		BEGIN
			IF @product_business_id != @business_id
				RETURN -3;

			IF 2 * @product_discount > @price
				RETURN -1;

			UPDATE p
			SET p.name = @name, p.description = @description, p.category = @category, p.price = @price, p.is_available = @is_available
			FROM Product p
			WHERE p.product_id = @product_id;
		END
	ELSE
		INSERT INTO Product (name, description, category, price, is_available, business_id)
		VALUES (@name, @description, @category, @price, @is_available, @business_id);
	
	RETURN 0;
END;
GO

----------------------------------------------------------------------------------------------------------------------------
------------------------------------------------- Toggle_Favorite ----------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

-- Name: Mostafa Ahmed Emam
-- ID: 64-14029
/*
Questions :
*/
CREATE PROCEDURE Toggle_Favorite
	@customer_id INT,
	@item_id     INT,
	@item_type   VARCHAR(20)
AS
BEGIN
	IF @item_type IS NULL OR @item_type NOT IN ('Business', 'Product')
		RETURN -1;

	IF @item_type = 'Business'
	BEGIN
		IF EXISTS (SELECT 1 FROM Favorite_Business fb WHERE fb.customer_id = @customer_id AND fb.business_id = @item_id)
			DELETE FROM Favorite_Business
			WHERE customer_id = @customer_id AND business_id = @item_id;
		ELSE
			INSERT INTO Favorite_Business (customer_id, business_id)
			VALUES (@customer_id, @item_id);
	END
	ELSE
	BEGIN
		IF EXISTS (SELECT 1 FROM Favorite_Product fp WHERE fp.customer_id = @customer_id AND fp.product_id = @item_id)
			DELETE FROM Favorite_Product
			WHERE customer_id = @customer_id AND product_id = @item_id;
		ELSE
			INSERT INTO Favorite_Product (customer_id, product_id)
			VALUES (@customer_id, @item_id);
	END

	RETURN 0;
END;
GO

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------- Register_Business ----------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

-- Name: Mostafa Ahmed Emam
-- ID: 64-14029
/*
Questions :
*/
CREATE PROCEDURE Register_Business
	@partner_id             INT,
	@name                   VARCHAR(100),
	@description            VARCHAR(255),
	@link_website           VARCHAR(255),
	@zone_id                INT,
	@opening_hour           TIME,
	@closing_hour           TIME,
	@expected_delivery_time INT,
	@phone                  CHAR(11),
	@business_type          VARCHAR(20),
	@cuisine_type           VARCHAR(50),
	@food_category          VARCHAR(50),
	@pharmacy_type          VARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON;

	-- only a Partner can register a business
	IF NOT EXISTS (SELECT 1 FROM Partner WHERE partner_id = @partner_id)
		RETURN -3;

	-- input validation
	IF @name IS NULL OR LTRIM(RTRIM(@name)) = ''
		RETURN -1;

	IF @opening_hour IS NULL OR @closing_hour IS NULL
		RETURN -1;

	IF @expected_delivery_time IS NULL OR @expected_delivery_time <= 0
		RETURN -1;

	IF @zone_id IS NULL OR NOT EXISTS (SELECT 1 FROM Zone WHERE zone_id = @zone_id)
		RETURN -1;

	IF @business_type IS NULL OR @business_type NOT IN ('Restaurant', 'Pharmacy')
		RETURN -1;

	IF @business_type = 'Restaurant' AND (NULLIF(LTRIM(RTRIM(@cuisine_type)), '') IS NULL OR NULLIF(LTRIM(RTRIM(@food_category)), '') IS NULL)
		RETURN -1;

	IF @business_type = 'Pharmacy' AND NULLIF(LTRIM(RTRIM(@pharmacy_type)), '') IS NULL
		RETURN -1;

	IF @phone IS NOT NULL AND (LEN(@phone) != 11 OR @phone LIKE '%[^0-9]%')
		RETURN -1;

	-- a partner owns at most one business
	DECLARE @bid INT, @status VARCHAR(20);
	SELECT @bid = business_id, @status = status
	FROM Business
	WHERE partner_id = @partner_id;

	IF @bid IS NOT NULL AND @status != 'Rejected'
		RETURN -2;

	IF @bid IS NULL
	BEGIN
		INSERT INTO Business (name, description, link_website, opening_hour, closing_hour, expected_delivery_time, status, suspension_reason, partner_id, zone_id)
		VALUES (@name, @description, @link_website, @opening_hour, @closing_hour, @expected_delivery_time, 'Pending', NULL, @partner_id, @zone_id);

		SET @bid = SCOPE_IDENTITY();
	END
	ELSE
	BEGIN
		-- Rejected business gets the new data and goes back to Pending
		UPDATE Business
		SET name = @name, description = @description, link_website = @link_website, opening_hour = @opening_hour, closing_hour = @closing_hour, expected_delivery_time = @expected_delivery_time, status = 'Pending', suspension_reason = NULL, zone_id = @zone_id
		WHERE business_id = @bid;

		-- its phones and Restaurant/Pharmacy row are replaced
		DELETE FROM Business_Phone WHERE business_id = @bid;
		DELETE FROM Restaurant WHERE business_id = @bid;
		DELETE FROM Pharmacy WHERE business_id = @bid;
	END

	IF @phone IS NOT NULL
		INSERT INTO Business_Phone (business_id, phone)
		VALUES (@bid, @phone);

	IF @business_type = 'Restaurant'
		INSERT INTO Restaurant (business_id, cuisine_type, food_category)
		VALUES (@bid, @cuisine_type, @food_category);
	ELSE
		INSERT INTO Pharmacy (business_id, pharmacy_type)
		VALUES (@bid, @pharmacy_type);

	RETURN 0;
END;
GO


----------------------------------------------------------------------------------------------------------------------------
---------------------------------------------- BusinessSalesReport ---------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

-- Name: Mostafa Ahmed Emam
-- ID: 64-14029
/*
Questions :
*/
CREATE FUNCTION BusinessSalesReport
(
	@business_id INT,
	@from_date   DATE,
	@to_date     DATE
)
RETURNS TABLE
AS
RETURN
(
	SELECT
		p.product_id,
		p.name AS product_name,
		SUM(ci.quantity) AS units_sold,
		SUM(ci.quantity * ci.unit_price) AS revenue_per_product
	FROM SubOrder so
	JOIN Orders   o ON o.order_id = so.order_id
	JOIN CartItem ci ON ci.cart_id = o.cart_id
	JOIN Product  p ON p.product_id = ci.product_id AND p.business_id = so.business_id
	WHERE so.business_id = @business_id
		AND so.status != 'Cancelled'
		AND @from_date IS NOT NULL AND @to_date IS NOT NULL AND @from_date <= @to_date
		AND CAST(o.order_date AS DATE) BETWEEN @from_date AND @to_date
	GROUP BY p.product_id, p.name
);
GO

----------------------------------------------------------------------------------------------------------------------------
---------------------------------------------- Nearby_Businesses_By_Category -----------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

-- Name: Mostafa Ahmed Emam
-- ID: 64-14029
/*
Questions :
*/
CREATE FUNCTION Nearby_Businesses_By_Category
(
	@address_id       INT,
	@product_category VARCHAR(50)
)
RETURNS @result TABLE
(
	business_id            INT,
	business_name          VARCHAR(100),
	zone_name              VARCHAR(50),
	same_zone              INT,
	zone_avg_delivery_time DECIMAL(10, 2)
)
AS
BEGIN
	DECLARE @addr_zone INT;
	SELECT @addr_zone = zone_id
	FROM Address
	WHERE address_id = @address_id;

	-- empty table on any error
	IF @addr_zone IS NULL OR @product_category IS NULL OR LTRIM(RTRIM(@product_category)) = ''
		RETURN;

	-- average tracking_time of Delivered deliveries per (business) zone
	INSERT INTO @result (business_id, business_name, zone_name, same_zone, zone_avg_delivery_time)
	SELECT
		b.business_id,
		b.name,
		z.zone_name,
		CASE WHEN b.zone_id = @addr_zone THEN 1 ELSE 0 END,
		za.avg_time
	FROM Business b
	JOIN Zone z ON z.zone_id = b.zone_id
	LEFT JOIN (
		SELECT
			b2.zone_id,
			CAST(AVG(CAST(d.tracking_time AS DECIMAL(10, 2))) AS DECIMAL(10, 2)) AS avg_time
		FROM Delivery d
		JOIN SubOrder so ON so.suborder_id = d.suborder_id
		JOIN Business b2 ON b2.business_id = so.business_id
		WHERE so.status = 'Delivered'
		GROUP BY b2.zone_id
	) za ON za.zone_id = b.zone_id
	WHERE b.status = 'Active'
		AND EXISTS (SELECT 1 FROM Product p WHERE p.business_id = b.business_id AND p.is_available = 1 AND p.category = @product_category)
	ORDER BY
		CASE WHEN b.zone_id = @addr_zone THEN 1 ELSE 0 END DESC, -- same zone first
		CASE WHEN za.avg_time IS NULL THEN 1 ELSE 0 END ASC, -- NULL averages last
		za.avg_time ASC,
		b.business_id ASC;

	RETURN;
END;
GO

----------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------- TopSellingProducts ----------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

-- Name: Mostafa Ahmed Emam
-- ID: 64-14029
/*
Questions :
*/
CREATE VIEW TopSellingProducts
AS
	SELECT TOP (10)
		p.product_id,
		p.name AS product_name,
		b.name AS business_name,
		CASE
			WHEN r.business_id IS NOT NULL THEN 'Restaurant'
			WHEN ph.business_id IS NOT NULL THEN 'Pharmacy'
		END AS business_type,
		SUM(ci.quantity) AS units_sold,
		SUM(ci.quantity * ci.unit_price) AS total_revenue
	FROM SubOrder so
	JOIN Orders   o ON o.order_id = so.order_id
	JOIN CartItem ci ON ci.cart_id = o.cart_id
	JOIN Product  p ON p.product_id = ci.product_id AND p.business_id = so.business_id -- item belongs to this suborder
	JOIN Business b ON b.business_id = p.business_id
	LEFT JOIN Restaurant r ON r.business_id = b.business_id
	LEFT JOIN Pharmacy   ph ON ph.business_id = b.business_id
	WHERE so.status != 'Cancelled'
	GROUP BY p.product_id, p.name, b.name, r.business_id, ph.business_id
	ORDER BY SUM(ci.quantity) DESC, p.product_id ASC;
GO

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------- Search_Platform-------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

-- Name: Mostafa Ahmed Emam
-- ID: 64-14029
/*
Questions :
*/
CREATE FUNCTION Search_Platform
(
	@customer_id INT,
	@keyword     VARCHAR(100)
)
RETURNS @result TABLE
(
	business_id   INT,
	business_name VARCHAR(100),
	priority      INT
)
AS
BEGIN
	DECLARE @zone INT;
	SELECT @zone = zone_id
	FROM Address
	WHERE customer_id = @customer_id AND is_active = 1;

	-- empty table on any error
	IF @zone IS NULL OR @keyword IS NULL OR LTRIM(RTRIM(@keyword)) = ''
		RETURN;

	INSERT INTO @result (business_id, business_name, priority)
	SELECT x.business_id, x.business_name, x.priority
	FROM (
		SELECT
			b.business_id,
			b.name AS business_name,
			CASE
				WHEN b.name = @keyword THEN 1 -- exact match
				WHEN CHARINDEX(@keyword, b.name) = 1 THEN 2 -- starts with
				ELSE 3 -- contains
			END AS priority
		FROM Business b
		WHERE b.status = 'Active' AND b.zone_id = @zone AND CHARINDEX(@keyword, b.name) > 0
	) x
	ORDER BY x.priority ASC, x.business_name ASC, x.business_id ASC;

	RETURN;
END;
GO
