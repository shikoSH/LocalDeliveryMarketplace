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
	IF @name IS NULL OR @zone_id IS NULL OR @opening_hour IS NULL OR @closing_hour IS NULL OR  @expected_delivery_time IS NULL OR @phone IS NULL
		RETURN -1;
	IF @expected_delivery_time <= 0
		RETURN -1;
	IF @phone LIKE '%[^0-9]%' OR LEN(@phone) != 11
		RETURN -1;
	RETURN 0;
END;
