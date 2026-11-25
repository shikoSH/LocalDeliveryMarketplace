-- ====================================================================================================
-- 4.1.a  Database statement (LocalDeliveryMarketplace_Team_XX)
-- Student 4: Ahmed Hassan | ID: 65-33776
-- ====================================================================================================

-- 4.1.a  Ahmed Hassan - 65_33776
CREATE DATABASE LocalDeliveryMarketplace_Team_143;
GO
USE LocalDeliveryMarketplace_Team_143;
GO


-- ====================================================================================================
-- 4.1.b  createAllTables
-- Student 4: Ahmed Hassan | ID: 65-33776
-- ====================================================================================================

-- 4.1.b  Ahmed Hassan - 65_33776
CREATE PROCEDURE createAllTables
AS
BEGIN
    CREATE TABLE Zone (
        zone_id       INT IDENTITY(1,1) NOT NULL,
        zone_name     VARCHAR(50)   NOT NULL,
        delivery_fee  DECIMAL(10,2) NOT NULL,
        CONSTRAINT PK_Zone PRIMARY KEY (zone_id),
        CONSTRAINT UQ_Zone_name UNIQUE (zone_name),
        CONSTRAINT CK_Zone_fee CHECK (delivery_fee >= 0)
    );

    CREATE TABLE Users (
        user_id         INT IDENTITY(1,1) NOT NULL,
        first_name      VARCHAR(30)  NOT NULL,
        middle_name     VARCHAR(30)  NULL,
        last_name       VARCHAR(30)  NOT NULL,
        username        VARCHAR(30)  NOT NULL,
        password        VARCHAR(30)  NOT NULL,
        email           VARCHAR(100) NOT NULL,
        dob             DATE         NULL,
        account_status  VARCHAR(20)  NOT NULL CONSTRAINT DF_Users_status DEFAULT 'Active',
        CONSTRAINT PK_Users PRIMARY KEY (user_id),
        CONSTRAINT UQ_Users_username UNIQUE (username),
        CONSTRAINT UQ_Users_email UNIQUE (email)
    );

    CREATE TABLE User_Phone (
        user_id INT      NOT NULL,
        phone   CHAR(11) NOT NULL,
        CONSTRAINT PK_User_Phone PRIMARY KEY (user_id, phone),
        CONSTRAINT FK_UserPhone_User FOREIGN KEY (user_id) REFERENCES Users(user_id)
    );

    CREATE TABLE Admin (
        admin_id INT         NOT NULL,
        role     VARCHAR(20) NOT NULL CONSTRAINT DF_Admin_role DEFAULT 'Super Admin',
        zone_id  INT         NULL,
        CONSTRAINT PK_Admin PRIMARY KEY (admin_id),
        CONSTRAINT FK_Admin_User FOREIGN KEY (admin_id) REFERENCES Users(user_id),
        CONSTRAINT FK_Admin_Zone FOREIGN KEY (zone_id) REFERENCES Zone(zone_id)
    );

    CREATE TABLE Partner (
        partner_id INT NOT NULL,
        CONSTRAINT PK_Partner PRIMARY KEY (partner_id),
        CONSTRAINT FK_Partner_User FOREIGN KEY (partner_id) REFERENCES Users(user_id)
    );

    CREATE TABLE Rider (
        rider_id      INT         NOT NULL,
        vehicle_type  VARCHAR(30) NOT NULL,
        plate_no      VARCHAR(15) NOT NULL,
        license_no    VARCHAR(20) NOT NULL,
        is_available  BIT         NOT NULL CONSTRAINT DF_Rider_avail DEFAULT 1,
        zone_id       INT         NOT NULL,
        CONSTRAINT PK_Rider PRIMARY KEY (rider_id),
        CONSTRAINT FK_Rider_User FOREIGN KEY (rider_id) REFERENCES Users(user_id),
        CONSTRAINT FK_Rider_Zone FOREIGN KEY (zone_id) REFERENCES Zone(zone_id),
        CONSTRAINT UQ_Rider_plate UNIQUE (plate_no),
        CONSTRAINT UQ_Rider_license UNIQUE (license_no)
    );

    CREATE TABLE Customer (
        customer_id     INT           NOT NULL,
        wallet_balance  DECIMAL(10,2) NOT NULL CONSTRAINT DF_Customer_wallet DEFAULT 0,
        CONSTRAINT PK_Customer PRIMARY KEY (customer_id),
        CONSTRAINT FK_Customer_User FOREIGN KEY (customer_id) REFERENCES Users(user_id),
        CONSTRAINT CK_Customer_wallet CHECK (wallet_balance >= 0)
    );

    CREATE TABLE Address (
        address_id   INT IDENTITY(1,1) NOT NULL,
        description  VARCHAR(150) NOT NULL,
        is_active    BIT          NOT NULL CONSTRAINT DF_Address_active DEFAULT 1,
        customer_id  INT          NOT NULL,
        zone_id      INT          NOT NULL,
        CONSTRAINT PK_Address PRIMARY KEY (address_id),
        CONSTRAINT FK_Address_Customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
        CONSTRAINT FK_Address_Zone FOREIGN KEY (zone_id) REFERENCES Zone(zone_id)
    );

    CREATE TABLE Card (
        card_id           INT IDENTITY(1,1) NOT NULL,
        card_no           CHAR(16)     NOT NULL,
        card_holder_name  VARCHAR(100) NOT NULL,
        expiration_date   DATE         NOT NULL,
        customer_id       INT          NOT NULL,
        CONSTRAINT PK_Card PRIMARY KEY (card_id),
        CONSTRAINT FK_Card_Customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
        CONSTRAINT UQ_Card_customer_no UNIQUE (customer_id, card_no)
    );

    CREATE TABLE Business (
        business_id             INT IDENTITY(1,1) NOT NULL,
        name                    VARCHAR(100) NOT NULL,
        description             VARCHAR(255) NULL,
        link_website            VARCHAR(255) NULL,
        opening_hour            TIME         NOT NULL,
        closing_hour            TIME         NOT NULL,
        expected_delivery_time  INT          NOT NULL,
        status                  VARCHAR(20)  NOT NULL CONSTRAINT DF_Business_status DEFAULT 'Pending',
        suspension_reason       VARCHAR(255) NULL,
        partner_id              INT          NOT NULL,
        zone_id                 INT          NOT NULL,
        CONSTRAINT PK_Business PRIMARY KEY (business_id),
        CONSTRAINT FK_Business_Partner FOREIGN KEY (partner_id) REFERENCES Partner(partner_id),
        CONSTRAINT FK_Business_Zone FOREIGN KEY (zone_id) REFERENCES Zone(zone_id),
        CONSTRAINT UQ_Business_partner UNIQUE (partner_id),
        CONSTRAINT CK_Business_edt CHECK (expected_delivery_time > 0)
    );

    CREATE TABLE Business_Phone (
        business_id INT      NOT NULL,
        phone       CHAR(11) NOT NULL,
        CONSTRAINT PK_Business_Phone PRIMARY KEY (business_id, phone),
        CONSTRAINT FK_BPhone_Business FOREIGN KEY (business_id) REFERENCES Business(business_id)
    );

    CREATE TABLE Restaurant (
        business_id    INT         NOT NULL,
        cuisine_type   VARCHAR(50) NOT NULL,
        food_category  VARCHAR(50) NOT NULL,
        CONSTRAINT PK_Restaurant PRIMARY KEY (business_id),
        CONSTRAINT FK_Restaurant_Business FOREIGN KEY (business_id) REFERENCES Business(business_id)
    );

    CREATE TABLE Pharmacy (
        business_id    INT         NOT NULL,
        pharmacy_type  VARCHAR(50) NOT NULL,
        CONSTRAINT PK_Pharmacy PRIMARY KEY (business_id),
        CONSTRAINT FK_Pharmacy_Business FOREIGN KEY (business_id) REFERENCES Business(business_id)
    );

    CREATE TABLE Blacklist (
        customer_id INT          NOT NULL,
        admin_id    INT          NOT NULL,
        reason      VARCHAR(255) NOT NULL,
        CONSTRAINT PK_Blacklist PRIMARY KEY (customer_id),
        CONSTRAINT FK_Blacklist_Customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
        CONSTRAINT FK_Blacklist_Admin FOREIGN KEY (admin_id) REFERENCES Admin(admin_id)
    );

    CREATE TABLE Product (
        product_id       INT IDENTITY(1,1) NOT NULL,
        name             VARCHAR(100)  NOT NULL,
        description      VARCHAR(255)  NULL,
        category         VARCHAR(50)   NOT NULL,
        price            DECIMAL(10,2) NOT NULL,
        discount_amount  DECIMAL(10,2) NOT NULL CONSTRAINT DF_Product_discount DEFAULT 0,
        is_available     BIT           NOT NULL CONSTRAINT DF_Product_avail DEFAULT 1,
        business_id      INT           NOT NULL,
        CONSTRAINT PK_Product PRIMARY KEY (product_id),
        CONSTRAINT FK_Product_Business FOREIGN KEY (business_id) REFERENCES Business(business_id),
        CONSTRAINT CK_Product_price CHECK (price > 0),
        CONSTRAINT CK_Product_discount CHECK (discount_amount >= 0 AND discount_amount <= 0.5 * price)
    );

    CREATE TABLE Favorite_Business (
        customer_id INT NOT NULL,
        business_id INT NOT NULL,
        CONSTRAINT PK_Favorite_Business PRIMARY KEY (customer_id, business_id),
        CONSTRAINT FK_FavB_Customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
        CONSTRAINT FK_FavB_Business FOREIGN KEY (business_id) REFERENCES Business(business_id)
    );

    CREATE TABLE Favorite_Product (
        customer_id INT NOT NULL,
        product_id  INT NOT NULL,
        CONSTRAINT PK_Favorite_Product PRIMARY KEY (customer_id, product_id),
        CONSTRAINT FK_FavP_Customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
        CONSTRAINT FK_FavP_Product FOREIGN KEY (product_id) REFERENCES Product(product_id)
    );

    CREATE TABLE Voucher (
        voucher_id     INT IDENTITY(1,1) NOT NULL,
        promo_code     VARCHAR(30)   NOT NULL,
        is_percentage  BIT           NOT NULL,
        amount         DECIMAL(10,2) NOT NULL,
        expiry_date    DATE          NOT NULL,
        status         VARCHAR(20)   NOT NULL CONSTRAINT DF_Voucher_status DEFAULT 'Unused',
        customer_id    INT           NOT NULL,
        CONSTRAINT PK_Voucher PRIMARY KEY (voucher_id),
        CONSTRAINT UQ_Voucher_promo UNIQUE (promo_code),
        CONSTRAINT CK_Voucher_amount CHECK (amount > 0),
        CONSTRAINT FK_Voucher_Customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
    );

    CREATE TABLE Cart (
        cart_id      INT IDENTITY(1,1) NOT NULL,
        status       VARCHAR(20) NOT NULL CONSTRAINT DF_Cart_status DEFAULT 'Active',
        created_at   DATETIME    NOT NULL CONSTRAINT DF_Cart_created DEFAULT GETDATE(),
        customer_id  INT         NOT NULL,
        address_id   INT         NOT NULL,
        CONSTRAINT PK_Cart PRIMARY KEY (cart_id),
        CONSTRAINT FK_Cart_Customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
        CONSTRAINT FK_Cart_Address FOREIGN KEY (address_id) REFERENCES Address(address_id)
    );

    CREATE TABLE CartItem (
        cart_id     INT           NOT NULL,
        product_id  INT           NOT NULL,
        quantity    INT           NOT NULL,
        notes       VARCHAR(255)  NULL,
        unit_price  DECIMAL(10,2) NULL,
        CONSTRAINT PK_CartItem PRIMARY KEY (cart_id, product_id),
        CONSTRAINT FK_CartItem_Cart FOREIGN KEY (cart_id) REFERENCES Cart(cart_id),
        CONSTRAINT FK_CartItem_Product FOREIGN KEY (product_id) REFERENCES Product(product_id),
        CONSTRAINT CK_CartItem_qty CHECK (quantity BETWEEN 1 AND 10)
    );

    CREATE TABLE Orders (
        order_id         INT IDENTITY(1,1) NOT NULL,
        order_date       DATETIME      NOT NULL,
        status           VARCHAR(20)   NOT NULL CONSTRAINT DF_Orders_status DEFAULT 'Placed',
        discount_amount  DECIMAL(10,2) NOT NULL CONSTRAINT DF_Orders_discount DEFAULT 0,
        total_amount     DECIMAL(10,2) NOT NULL,
        cart_id          INT           NOT NULL,
        zone_id          INT           NOT NULL,
        voucher_id       INT           NULL,
        CONSTRAINT PK_Orders PRIMARY KEY (order_id),
        CONSTRAINT UQ_Orders_cart UNIQUE (cart_id),
        CONSTRAINT FK_Orders_Cart FOREIGN KEY (cart_id) REFERENCES Cart(cart_id),
        CONSTRAINT FK_Orders_Zone FOREIGN KEY (zone_id) REFERENCES Zone(zone_id),
        CONSTRAINT FK_Orders_Voucher FOREIGN KEY (voucher_id) REFERENCES Voucher(voucher_id)
    );

    CREATE TABLE SubOrder (
        suborder_id   INT IDENTITY(1,1) NOT NULL,
        status        VARCHAR(20)   NOT NULL CONSTRAINT DF_SubOrder_status DEFAULT 'Placed',
        total_price   DECIMAL(10,2) NOT NULL,
        delivery_fee  DECIMAL(10,2) NOT NULL,
        order_id      INT           NOT NULL,
        business_id   INT           NOT NULL,
        CONSTRAINT PK_SubOrder PRIMARY KEY (suborder_id),
        CONSTRAINT FK_SubOrder_Orders FOREIGN KEY (order_id) REFERENCES Orders(order_id),
        CONSTRAINT FK_SubOrder_Business FOREIGN KEY (business_id) REFERENCES Business(business_id),
        CONSTRAINT UQ_SubOrder_order_business UNIQUE (order_id, business_id)
    );

    CREATE TABLE Delivery (
        delivery_id    INT IDENTITY(1,1) NOT NULL,
        assigned_at    DATETIME NOT NULL,
        picked_up_at   DATETIME NULL,
        delivered_at   DATETIME NULL,
        tracking_time  INT      NULL,
        rider_rating   INT      NULL,
        suborder_id    INT      NOT NULL,
        rider_id       INT      NOT NULL,
        CONSTRAINT PK_Delivery PRIMARY KEY (delivery_id),
        CONSTRAINT UQ_Delivery_suborder UNIQUE (suborder_id),
        CONSTRAINT FK_Delivery_SubOrder FOREIGN KEY (suborder_id) REFERENCES SubOrder(suborder_id),
        CONSTRAINT FK_Delivery_Rider FOREIGN KEY (rider_id) REFERENCES Rider(rider_id),
        CONSTRAINT CK_Delivery_rating CHECK (rider_rating BETWEEN 1 AND 5)
    );

    CREATE TABLE Payment (
        payment_id        INT IDENTITY(1,1) NOT NULL,
        amount            DECIMAL(10,2) NOT NULL,
        currency          VARCHAR(3)    NOT NULL CONSTRAINT DF_Payment_currency DEFAULT 'EGP',
        method            VARCHAR(20)   NOT NULL,
        transaction_date  DATETIME      NOT NULL,
        refunded_amount   DECIMAL(10,2) NOT NULL CONSTRAINT DF_Payment_refunded DEFAULT 0,
        order_id          INT           NOT NULL,
        card_id           INT           NULL,
        CONSTRAINT PK_Payment PRIMARY KEY (payment_id),
        CONSTRAINT UQ_Payment_order UNIQUE (order_id),
        CONSTRAINT FK_Payment_Orders FOREIGN KEY (order_id) REFERENCES Orders(order_id),
        CONSTRAINT FK_Payment_Card FOREIGN KEY (card_id) REFERENCES Card(card_id),
        CONSTRAINT CK_Payment_refund CHECK (refunded_amount <= amount)
    );

    CREATE TABLE Feedback (
        feedback_id    INT IDENTITY(1,1) NOT NULL,
        headline       VARCHAR(100) NOT NULL,
        description    VARCHAR(500) NULL,
        rating         INT          NOT NULL,
        feedback_date  DATETIME     NOT NULL CONSTRAINT DF_Feedback_date DEFAULT GETDATE(),
        suborder_id    INT          NOT NULL,
        CONSTRAINT PK_Feedback PRIMARY KEY (feedback_id),
        CONSTRAINT UQ_Feedback_suborder UNIQUE (suborder_id),
        CONSTRAINT FK_Feedback_SubOrder FOREIGN KEY (suborder_id) REFERENCES SubOrder(suborder_id),
        CONSTRAINT CK_Feedback_rating CHECK (rating BETWEEN 1 AND 5)
    );
END
GO

EXEC createAllTables;
GO


-- ====================================================================================================
-- 4.1.c  dropAllTables
-- Student 4: Ahmed Hassan | ID: 65-33776
-- ====================================================================================================

-- 4.1.c  Ahmed Hassan - 65_33776
CREATE PROCEDURE dropAllTables
AS
BEGIN
    DROP TABLE IF EXISTS Feedback;
    DROP TABLE IF EXISTS Payment;
    DROP TABLE IF EXISTS Delivery;
    DROP TABLE IF EXISTS SubOrder;
    DROP TABLE IF EXISTS Orders;
    DROP TABLE IF EXISTS CartItem;
    DROP TABLE IF EXISTS Cart;
    DROP TABLE IF EXISTS Voucher;
    DROP TABLE IF EXISTS Favorite_Product;
    DROP TABLE IF EXISTS Favorite_Business;
    DROP TABLE IF EXISTS Product;
    DROP TABLE IF EXISTS Blacklist;
    DROP TABLE IF EXISTS Pharmacy;
    DROP TABLE IF EXISTS Restaurant;
    DROP TABLE IF EXISTS Business_Phone;
    DROP TABLE IF EXISTS Business;
    DROP TABLE IF EXISTS Card;
    DROP TABLE IF EXISTS Address;
    DROP TABLE IF EXISTS Customer;
    DROP TABLE IF EXISTS Rider;
    DROP TABLE IF EXISTS Partner;
    DROP TABLE IF EXISTS Admin;
    DROP TABLE IF EXISTS User_Phone;
    DROP TABLE IF EXISTS Users;
    DROP TABLE IF EXISTS Zone;
END
GO


-- ====================================================================================================
-- 4.1.d  dropAllProceduresFunctionsViews
-- Student 4: Ahmed Hassan | ID: 65-33776
-- ====================================================================================================

-- 4.1.d  Ahmed Hassan - 65_33776
CREATE PROCEDURE dropAllProceduresFunctionsViews
AS
BEGIN
    DROP VIEW IF EXISTS allBusinessProfiles;
    DROP VIEW IF EXISTS BusinessesPerZone;
    DROP VIEW IF EXISTS BusinessRatingsSummary;
    DROP VIEW IF EXISTS ActiveVouchers;
    DROP VIEW IF EXISTS PendingBusinessApprovals;
    DROP VIEW IF EXISTS RiderPerformanceSummary;
    DROP VIEW IF EXISTS TopSellingProducts;
    DROP VIEW IF EXISTS ZoneDeliveryPerformance;

    DROP FUNCTION IF EXISTS dbo.CustomerLoginValidation;
    DROP FUNCTION IF EXISTS dbo.PartnerLoginValidation;
    DROP FUNCTION IF EXISTS dbo.RiderLoginValidation;
    DROP FUNCTION IF EXISTS dbo.AdminLoginValidation;
    DROP FUNCTION IF EXISTS dbo.ZoneOrderReport;
    DROP FUNCTION IF EXISTS dbo.TopRiders;
    DROP FUNCTION IF EXISTS dbo.Daily_Revenue_Report;
    DROP FUNCTION IF EXISTS dbo.BusinessSalesReport;
    DROP FUNCTION IF EXISTS dbo.BusinessFeedbackOverview;
    DROP FUNCTION IF EXISTS dbo.Calculate_Voucher_Discount;
    DROP FUNCTION IF EXISTS dbo.My_Order_History;
    DROP FUNCTION IF EXISTS dbo.My_Favorites;
    DROP FUNCTION IF EXISTS dbo.Recommended_Products;
    DROP FUNCTION IF EXISTS dbo.My_Active_Deliveries;
    DROP FUNCTION IF EXISTS dbo.My_Earnings;
    DROP FUNCTION IF EXISTS dbo.My_Rating_Summary;
    DROP FUNCTION IF EXISTS dbo.My_Delivery_History;
    DROP FUNCTION IF EXISTS dbo.Search_Platform;
    DROP FUNCTION IF EXISTS dbo.Reconcile_Order_Totals;
    DROP FUNCTION IF EXISTS dbo.Nearby_Businesses_By_Category;
    DROP FUNCTION IF EXISTS dbo.Platform_Health_Snapshot;
    DROP FUNCTION IF EXISTS dbo.SuspendRefunds;
    DROP FUNCTION IF EXISTS dbo.Expected_Total;
    DROP FUNCTION IF EXISTS dbo.GetBusinessType;
    DROP FUNCTION IF EXISTS dbo.IsBusinessOpen;
    DROP FUNCTION IF EXISTS dbo.GetBusinessStatus;

    DROP PROCEDURE IF EXISTS createAllTables;
    DROP PROCEDURE IF EXISTS dropAllTables;
    DROP PROCEDURE IF EXISTS clearAllTables;
    DROP PROCEDURE IF EXISTS Customer_Register;
    DROP PROCEDURE IF EXISTS Partner_Register;
    DROP PROCEDURE IF EXISTS Rider_Register;
    DROP PROCEDURE IF EXISTS Change_Password;
    DROP PROCEDURE IF EXISTS Create_Admin;
    DROP PROCEDURE IF EXISTS Approve_Business;
    DROP PROCEDURE IF EXISTS Reject_Business;
    DROP PROCEDURE IF EXISTS Suspend_Business;
    DROP PROCEDURE IF EXISTS Reinstate_Business;
    DROP PROCEDURE IF EXISTS Create_Zone;
    DROP PROCEDURE IF EXISTS Update_Zone_Fee;
    DROP PROCEDURE IF EXISTS Assign_Admin_Zone;
    DROP PROCEDURE IF EXISTS Issue_Voucher;
    DROP PROCEDURE IF EXISTS Blacklist_Customer;
    DROP PROCEDURE IF EXISTS Lift_Customer_Blacklist;
    DROP PROCEDURE IF EXISTS Register_Business;
    DROP PROCEDURE IF EXISTS Update_Business_Info;
    DROP PROCEDURE IF EXISTS Upsert_Product;
    DROP PROCEDURE IF EXISTS Toggle_Product_Status;
    DROP PROCEDURE IF EXISTS Set_Product_Promotion;
    DROP PROCEDURE IF EXISTS Add_Customer_Address;
    DROP PROCEDURE IF EXISTS Update_Delete_Customer_Address;
    DROP PROCEDURE IF EXISTS Change_Active_Address;
    DROP PROCEDURE IF EXISTS Add_Card;
    DROP PROCEDURE IF EXISTS Create_Cart;
    DROP PROCEDURE IF EXISTS Add_To_Cart;
    DROP PROCEDURE IF EXISTS Remove_From_Cart;
    DROP PROCEDURE IF EXISTS Checkout_Cart;
    DROP PROCEDURE IF EXISTS Cancel_Order;
    DROP PROCEDURE IF EXISTS Reorder;
    DROP PROCEDURE IF EXISTS Submit_Feedback;
    DROP PROCEDURE IF EXISTS Rate_Rider;
    DROP PROCEDURE IF EXISTS Toggle_Favorite;
    DROP PROCEDURE IF EXISTS Set_Rider_Availability;
    DROP PROCEDURE IF EXISTS Mark_Picked_Up;
    DROP PROCEDURE IF EXISTS Mark_Delivered;
END
GO


-- ====================================================================================================
-- 4.1.e  clearAllTables
-- Student 4: Ahmed Hassan | ID: 65-33776
-- ====================================================================================================

-- 4.1.e  Ahmed Hassan - 65_33776
CREATE PROCEDURE clearAllTables
AS
BEGIN
    EXEC dropAllTables;
    EXEC createAllTables;
END
GO


-- ====================================================================================================
-- Helper function GetBusinessType (used by 4.2.a allBusinessProfiles)
-- Student 2: Mostafa Ahmed Emam | ID: 64-14029 | T-16
-- ====================================================================================================
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


-- ====================================================================================================
-- Helper function IsBusinessOpen (used by 4.6.p My_Favorites)
-- Student 2: Mostafa Ahmed Emam | ID: 64-14029 | T-16
-- ====================================================================================================


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


-- ====================================================================================================
-- Helper function GetBusinessStatus (used by 4.5.c Upsert_Product and 4.5.d Toggle_Product_Status)
-- Student 2: Mostafa Ahmed Emam | ID: 64-14029 | T-16
-- ====================================================================================================


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


-- ====================================================================================================
-- 4.2.a  allBusinessProfiles
-- Student 2: Mostafa Ahmed Emam | ID: 64-14029 | T-16
-- ====================================================================================================
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


-- ====================================================================================================
-- 4.2.b  BusinessesPerZone
-- Student 4: Ahmed Hassan | ID: 65-33776
-- ====================================================================================================

-- 4.2.b  Ahmed Hassan - 65_33776
CREATE VIEW BusinessesPerZone
AS
SELECT  Z.zone_id,
        Z.zone_name,
        COUNT(B.business_id) AS business_count
FROM    Zone Z
LEFT OUTER JOIN Business B ON Z.zone_id = B.zone_id AND B.status = 'Active'
GROUP BY Z.zone_id, Z.zone_name;
GO


-- ====================================================================================================
-- 4.2.c  BusinessRatingsSummary
-- Student 5: Youssef Amr | ID: 64-23059
-- ====================================================================================================
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


-- ====================================================================================================
-- 4.2.d  ActiveVouchers
-- Student 1: Yassin Khaled Ahmed Abdelaziz Elsetohy | ID: 64-10815 | T-10
-- ====================================================================================================
-- Name: Yassin Khaled Ahmed Abdelaziz Elsetohy, ID: 64-10815
CREATE VIEW ActiveVouchers AS
SELECT voucher_id, promo_code, customer_id, is_percentage, amount, expiry_date
FROM Voucher
WHERE status = 'Unused' AND expiry_date >= CAST(GETDATE() AS DATE);
GO


-- ====================================================================================================
-- 4.2.e  PendingBusinessApprovals
-- Student 2: Mostafa Ahmed Emam | ID: 64-14029 | T-16
-- ====================================================================================================

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


-- ====================================================================================================
-- 4.2.f  RiderPerformanceSummary
-- Student 5: Youssef Amr | ID: 64-23059
-- ====================================================================================================

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
       U.first_name + ' ' + U.last_name AS rider_name, 
       Z.zone_name, 
       COUNT(D.delivered_at) AS completed_deliveries, 
       AVG(CAST(D.rider_rating AS DECIMAL(3,2))) AS avg_rating 
FROM Rider R
INNER JOIN Users U ON U.user_id = R.rider_id
INNER JOIN Zone Z ON Z.zone_id = R.zone_id
LEFT OUTER JOIN Delivery D ON R.rider_id = D.rider_id
GROUP BY R.rider_id, U.first_name, U.last_name, Z.zone_name
GO


-- ====================================================================================================
-- 4.2.g  [Hard] TopSellingProducts
-- Student 2: Mostafa Ahmed Emam | ID: 64-14029 | T-16
-- ====================================================================================================

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


-- ====================================================================================================
-- 4.2.h  ZoneDeliveryPerformance
-- Student 5: Youssef Amr | ID: 64-23059
-- ====================================================================================================
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
SELECT Z.zone_id, Z.zone_name, COUNT(D.delivery_id) AS delivery_count,
       CAST(AVG(CAST(D.tracking_time AS DECIMAL(10,2))) AS DECIMAL(10,2)) AS avg_tracking_time
FROM Zone Z
LEFT OUTER JOIN Orders O ON O.zone_id = Z.zone_id
LEFT OUTER JOIN SubOrder S ON S.order_id = O.order_id
LEFT OUTER JOIN Delivery D ON D.suborder_id = S.suborder_id AND D.delivered_at IS NOT NULL
GROUP BY Z.zone_id, Z.zone_name
GO


-- ====================================================================================================
-- 4.3.a  Customer_Register
-- Student 1: Yassin Khaled Ahmed Abdelaziz Elsetohy | ID: 64-10815 | T-10
-- ====================================================================================================

-- Name: Yassin Khaled Ahmed Abdelaziz Elsetohy, ID: 64-10815
CREATE PROCEDURE Customer_Register
    @first_name VARCHAR(30),
    @middle_name VARCHAR(30),
    @last_name VARCHAR(30),
    @username VARCHAR(30),
    @password VARCHAR(30),
    @email VARCHAR(100),
    @phone CHAR(11),
    @dob DATE
AS
BEGIN
    IF @first_name IS NULL OR @first_name = '' OR @last_name IS NULL OR @last_name = ''
       OR @username IS NULL OR @username = '' OR @password IS NULL OR @password = ''
       OR @email IS NULL OR @email NOT LIKE '%_@_%._%'
       OR @phone IS NULL OR LEN(@phone) <> 11 OR @phone LIKE '%[^0-9]%'
       OR @dob > CAST(GETDATE() AS DATE)
        RETURN -1

    IF EXISTS (SELECT * FROM Users WHERE username = @username OR email = @email)
        RETURN -2

    DECLARE @id INT

    INSERT INTO Users (first_name, middle_name, last_name, username, password, email, dob, account_status)
    VALUES (@first_name, @middle_name, @last_name, @username, @password, @email, @dob, 'Active')

    SET @id = SCOPE_IDENTITY()

    INSERT INTO Customer (customer_id, wallet_balance) VALUES (@id, 0)
    INSERT INTO User_Phone (user_id, phone) VALUES (@id, @phone)

    RETURN 0
END
GO


-- ====================================================================================================
-- 4.3.b  Partner_Register
-- Student 1: Yassin Khaled Ahmed Abdelaziz Elsetohy | ID: 64-10815 | T-10
-- ====================================================================================================

-- Name: Yassin Khaled Ahmed Abdelaziz Elsetohy, ID: 64-10815
CREATE PROCEDURE Partner_Register
    @first_name VARCHAR(30),
    @middle_name VARCHAR(30),
    @last_name VARCHAR(30),
    @username VARCHAR(30),
    @password VARCHAR(30),
    @email VARCHAR(100),
    @phone CHAR(11),
    @dob DATE
AS
BEGIN
    IF @first_name IS NULL OR @first_name = '' OR @last_name IS NULL OR @last_name = ''
       OR @username IS NULL OR @username = '' OR @password IS NULL OR @password = ''
       OR @email IS NULL OR @email NOT LIKE '%_@_%._%'
       OR @phone IS NULL OR LEN(@phone) <> 11 OR @phone LIKE '%[^0-9]%'
       OR @dob > CAST(GETDATE() AS DATE)
        RETURN -1

    IF EXISTS (SELECT * FROM Users WHERE username = @username OR email = @email)
        RETURN -2

    DECLARE @id INT

    INSERT INTO Users (first_name, middle_name, last_name, username, password, email, dob, account_status)
    VALUES (@first_name, @middle_name, @last_name, @username, @password, @email, @dob, 'Active')

    SET @id = SCOPE_IDENTITY()

    INSERT INTO Partner (partner_id) VALUES (@id)
    INSERT INTO User_Phone (user_id, phone) VALUES (@id, @phone)

    RETURN 0
END
GO


-- ====================================================================================================
-- 4.3.c  Rider_Register
-- Student 1: Yassin Khaled Ahmed Abdelaziz Elsetohy | ID: 64-10815 | T-10
-- ====================================================================================================

-- Name: Yassin Khaled Ahmed Abdelaziz Elsetohy, ID: 64-10815
CREATE PROCEDURE Rider_Register
    @first_name VARCHAR(30),
    @middle_name VARCHAR(30),
    @last_name VARCHAR(30),
    @username VARCHAR(30),
    @password VARCHAR(30),
    @email VARCHAR(100),
    @phone CHAR(11),
    @dob DATE,
    @vehicle_type VARCHAR(30),
    @plate_no VARCHAR(15),
    @license_no VARCHAR(20),
    @zone_id INT
AS
BEGIN
    IF @first_name IS NULL OR @first_name = '' OR @last_name IS NULL OR @last_name = ''
       OR @username IS NULL OR @username = '' OR @password IS NULL OR @password = ''
       OR @email IS NULL OR @email NOT LIKE '%_@_%._%'
       OR @phone IS NULL OR LEN(@phone) <> 11 OR @phone LIKE '%[^0-9]%'
       OR @dob > CAST(GETDATE() AS DATE)
       OR @vehicle_type IS NULL OR @vehicle_type = ''
       OR @plate_no IS NULL OR @plate_no = '' OR @license_no IS NULL OR @license_no = ''
        RETURN -1

    IF NOT EXISTS (SELECT * FROM Zone WHERE zone_id = @zone_id)
        RETURN -1

    IF EXISTS (SELECT * FROM Users WHERE username = @username OR email = @email)
        RETURN -2

    IF EXISTS (SELECT * FROM Rider WHERE plate_no = @plate_no OR license_no = @license_no)
        RETURN -2

    DECLARE @id INT

    INSERT INTO Users (first_name, middle_name, last_name, username, password, email, dob, account_status)
    VALUES (@first_name, @middle_name, @last_name, @username, @password, @email, @dob, 'Active')

    SET @id = SCOPE_IDENTITY()

    INSERT INTO Rider (rider_id, vehicle_type, plate_no, license_no, is_available, zone_id)
    VALUES (@id, @vehicle_type, @plate_no, @license_no, 1, @zone_id)

    INSERT INTO User_Phone (user_id, phone) VALUES (@id, @phone)

    RETURN 0
END
GO


-- ====================================================================================================
-- 4.3.d  CustomerLoginValidation
-- Student 1: Yassin Khaled Ahmed Abdelaziz Elsetohy | ID: 64-10815 | T-10
-- ====================================================================================================

-- Name: Yassin Khaled Ahmed Abdelaziz Elsetohy, ID: 64-10815
CREATE FUNCTION CustomerLoginValidation (@username VARCHAR(30), @password VARCHAR(30))
RETURNS BIT
AS
BEGIN
    DECLARE @success BIT = 0

    IF EXISTS (SELECT *
               FROM Users U INNER JOIN Customer C ON U.user_id = C.customer_id
               WHERE U.username = @username
                 AND U.password = @password COLLATE Latin1_General_CS_AS
                 AND U.account_status = 'Active')
        SET @success = 1

    RETURN @success
END
GO


-- ====================================================================================================
-- 4.3.e  PartnerLoginValidation
-- Student 1: Yassin Khaled Ahmed Abdelaziz Elsetohy | ID: 64-10815 | T-10
-- ====================================================================================================

-- Name: Yassin Khaled Ahmed Abdelaziz Elsetohy, ID: 64-10815
CREATE FUNCTION PartnerLoginValidation (@username VARCHAR(30), @password VARCHAR(30))
RETURNS BIT
AS
BEGIN
    DECLARE @success BIT = 0

    IF EXISTS (SELECT *
               FROM Users U INNER JOIN Partner P ON U.user_id = P.partner_id
               WHERE U.username = @username
                 AND U.password = @password COLLATE Latin1_General_CS_AS
                 AND U.account_status = 'Active')
        SET @success = 1

    RETURN @success
END
GO


-- ====================================================================================================
-- 4.3.f  RiderLoginValidation
-- Student 1: Yassin Khaled Ahmed Abdelaziz Elsetohy | ID: 64-10815 | T-10
-- ====================================================================================================

-- Name: Yassin Khaled Ahmed Abdelaziz Elsetohy, ID: 64-10815
CREATE FUNCTION RiderLoginValidation (@username VARCHAR(30), @password VARCHAR(30))
RETURNS BIT
AS
BEGIN
    DECLARE @success BIT = 0

    IF EXISTS (SELECT *
               FROM Users U INNER JOIN Rider R ON U.user_id = R.rider_id
               WHERE U.username = @username
                 AND U.password = @password COLLATE Latin1_General_CS_AS
                 AND U.account_status = 'Active')
        SET @success = 1

    RETURN @success
END
GO


-- ====================================================================================================
-- 4.3.g  AdminLoginValidation
-- Student 1: Yassin Khaled Ahmed Abdelaziz Elsetohy | ID: 64-10815 | T-10
-- ====================================================================================================

-- Name: Yassin Khaled Ahmed Abdelaziz Elsetohy, ID: 64-10815
CREATE FUNCTION AdminLoginValidation (@username VARCHAR(30), @password VARCHAR(30))
RETURNS BIT
AS
BEGIN
    DECLARE @success BIT = 0

    IF EXISTS (SELECT *
               FROM Users U INNER JOIN Admin A ON U.user_id = A.admin_id
               WHERE U.username = @username
                 AND U.password = @password COLLATE Latin1_General_CS_AS
                 AND U.account_status = 'Active')
        SET @success = 1

    RETURN @success
END
GO


-- ====================================================================================================
-- 4.3.h  Change_Password
-- Student 1: Yassin Khaled Ahmed Abdelaziz Elsetohy | ID: 64-10815 | T-10
-- ====================================================================================================

-- Name: Yassin Khaled Ahmed Abdelaziz Elsetohy, ID: 64-10815
CREATE PROCEDURE Change_Password
    @user_id INT,
    @old_password VARCHAR(30),
    @new_password VARCHAR(30),
    @new_password_repeat VARCHAR(30),
    @success BIT OUTPUT
AS
BEGIN
    SET @success = 0

    IF NOT EXISTS (SELECT * FROM Users
                   WHERE user_id = @user_id AND password = @old_password COLLATE Latin1_General_CS_AS)
        RETURN -1

    IF @new_password IS NULL OR @new_password = '' OR @new_password_repeat IS NULL
       OR @new_password <> @new_password_repeat COLLATE Latin1_General_CS_AS
       OR @new_password = @old_password COLLATE Latin1_General_CS_AS
        RETURN -1

    UPDATE Users SET password = @new_password WHERE user_id = @user_id

    SET @success = 1
    RETURN 0
END
GO


-- ====================================================================================================
-- 4.4.a  Create_Admin
-- Student 1: Yassin Khaled Ahmed Abdelaziz Elsetohy | ID: 64-10815 | T-10
-- ====================================================================================================

-- Name: Yassin Khaled Ahmed Abdelaziz Elsetohy, ID: 64-10815
CREATE PROCEDURE Create_Admin
    @first_name VARCHAR(30),
    @middle_name VARCHAR(30),
    @last_name VARCHAR(30),
    @username VARCHAR(30),
    @password VARCHAR(30),
    @email VARCHAR(100),
    @phone CHAR(11),
    @dob DATE,
    @role VARCHAR(20),
    @zone_id INT,
    @super_admin_id INT
AS
BEGIN
    IF NOT EXISTS (SELECT * FROM Admin WHERE admin_id = @super_admin_id AND role = 'Super Admin')
        RETURN -3

    IF @role IS NULL
        SET @role = 'Super Admin'

    IF @role NOT IN ('Super Admin', 'Zone Admin')
        RETURN -1

    IF @role = 'Super Admin' AND @zone_id IS NOT NULL
        RETURN -1

    IF @role = 'Zone Admin' AND NOT EXISTS (SELECT * FROM Zone WHERE zone_id = @zone_id)
        RETURN -1

    SET @role = CASE WHEN @role = 'Zone Admin' THEN 'Zone Admin' ELSE 'Super Admin' END

    IF @first_name IS NULL OR @first_name = '' OR @last_name IS NULL OR @last_name = ''
       OR @username IS NULL OR @username = '' OR @password IS NULL OR @password = ''
       OR @email IS NULL OR @email NOT LIKE '%_@_%._%'
       OR @phone IS NULL OR LEN(@phone) <> 11 OR @phone LIKE '%[^0-9]%'
       OR @dob > CAST(GETDATE() AS DATE)
        RETURN -1

    IF EXISTS (SELECT * FROM Users WHERE username = @username OR email = @email)
        RETURN -2

    DECLARE @id INT

    INSERT INTO Users (first_name, middle_name, last_name, username, password, email, dob, account_status)
    VALUES (@first_name, @middle_name, @last_name, @username, @password, @email, @dob, 'Active')

    SET @id = SCOPE_IDENTITY()

    INSERT INTO Admin (admin_id, role, zone_id) VALUES (@id, @role, @zone_id)
    INSERT INTO User_Phone (user_id, phone) VALUES (@id, @phone)

    RETURN 0
END
GO


-- ====================================================================================================
-- 4.4.b  Approve_Business
-- Student 1: Yassin Khaled Ahmed Abdelaziz Elsetohy | ID: 64-10815 | T-10
-- ====================================================================================================

-- Name: Yassin Khaled Ahmed Abdelaziz Elsetohy, ID: 64-10815
CREATE PROCEDURE Approve_Business
    @business_id INT,
    @admin_id INT
AS
BEGIN
    DECLARE @admin_role VARCHAR(20), @admin_zone INT, @business_zone INT, @status VARCHAR(20)

    SELECT @admin_role = role, @admin_zone = zone_id FROM Admin WHERE admin_id = @admin_id
    IF @admin_role IS NULL
        RETURN -3

    SELECT @status = status, @business_zone = zone_id FROM Business WHERE business_id = @business_id
    IF @status IS NULL
        RETURN -1

    IF @admin_role = 'Zone Admin' AND (@admin_zone IS NULL OR @admin_zone <> @business_zone)
        RETURN -3

    IF @status <> 'Pending'
        RETURN -4

    UPDATE Business SET status = 'Active' WHERE business_id = @business_id

    RETURN 0
END
GO


-- ====================================================================================================
-- 4.4.c  Reject_Business
-- Student 1: Yassin Khaled Ahmed Abdelaziz Elsetohy | ID: 64-10815 | T-10
-- ====================================================================================================

-- Name: Yassin Khaled Ahmed Abdelaziz Elsetohy, ID: 64-10815
CREATE PROCEDURE Reject_Business
    @business_id INT,
    @admin_id INT
AS
BEGIN
    DECLARE @admin_role VARCHAR(20), @admin_zone INT, @business_zone INT, @status VARCHAR(20)

    SELECT @admin_role = role, @admin_zone = zone_id FROM Admin WHERE admin_id = @admin_id
    IF @admin_role IS NULL
        RETURN -3

    SELECT @status = status, @business_zone = zone_id FROM Business WHERE business_id = @business_id
    IF @status IS NULL
        RETURN -1

    IF @admin_role = 'Zone Admin' AND (@admin_zone IS NULL OR @admin_zone <> @business_zone)
        RETURN -3

    IF @status <> 'Pending'
        RETURN -4

    UPDATE Business SET status = 'Rejected' WHERE business_id = @business_id

    RETURN 0
END
GO


-- ====================================================================================================
-- Helper function SuspendRefunds (used by 4.4.d Suspend_Business)
-- Student 4: Ahmed Hassan | ID: 65-33776
-- ====================================================================================================

-- Helper Function: SuspendRefunds  Ahmed Hassan - 65_33776
CREATE FUNCTION dbo.SuspendRefunds (@business_id INT)
RETURNS TABLE
AS
RETURN
(
    SELECT  S.order_id,
            C.customer_id,
            P.method,
            CASE
                WHEN NOT EXISTS (SELECT 1 FROM SubOrder X
                                 WHERE X.order_id = S.order_id
                                 AND   X.status <> 'Cancelled'
                                 AND   X.suborder_id <> S.suborder_id)
                     THEN P.amount - P.refunded_amount
                WHEN S.total_price + S.delivery_fee < P.amount - P.refunded_amount
                     THEN S.total_price + S.delivery_fee
                ELSE P.amount - P.refunded_amount
            END AS refund
    FROM    SubOrder S
    INNER JOIN Orders  O ON S.order_id = O.order_id
    INNER JOIN Cart    C ON O.cart_id  = C.cart_id
    INNER JOIN Payment P ON O.order_id = P.order_id
    WHERE   S.business_id = @business_id
    AND     S.status IN ('Placed', 'Assigned')
);
GO


-- ====================================================================================================
-- 4.4.d  [Hard] Suspend_Business
-- Student 4: Ahmed Hassan | ID: 65-33776
-- ====================================================================================================

-- 4.4.d  [HARD]  Ahmed Hassan - 65_33776
CREATE PROCEDURE Suspend_Business
    @business_id INT, @admin_id INT, @reason VARCHAR(255)
AS
BEGIN
    SET XACT_ABORT ON;

    IF @business_id IS NULL OR @admin_id IS NULL OR @reason IS NULL OR LEN(@reason) = 0
        RETURN -1;
    IF NOT EXISTS (SELECT 1 FROM Business B WHERE B.business_id = @business_id)
        RETURN -1;

    IF NOT EXISTS (SELECT 1
                   FROM   Admin A
                   INNER JOIN Business B ON B.business_id = @business_id
                   WHERE  A.admin_id = @admin_id
                   AND   (A.role = 'Super Admin'
                          OR (A.role = 'Zone Admin' AND A.zone_id = B.zone_id)))
        RETURN -3;

    IF NOT EXISTS (SELECT 1 FROM Business B WHERE B.business_id = @business_id AND B.status = 'Active')
        RETURN -4;

    BEGIN TRANSACTION;

    UPDATE Business
    SET    status = 'Suspended', suspension_reason = @reason
    WHERE  business_id = @business_id;

    UPDATE Product
    SET    is_available = 0
    WHERE  business_id = @business_id;

    UPDATE Customer
    SET    wallet_balance = wallet_balance
                            + (SELECT SUM(R.refund)
                               FROM   dbo.SuspendRefunds(@business_id) R
                               WHERE  R.customer_id = Customer.customer_id
                               AND    R.method <> 'Cash')
    WHERE  customer_id IN (SELECT R.customer_id
                           FROM   dbo.SuspendRefunds(@business_id) R
                           WHERE  R.method <> 'Cash');

    UPDATE Payment
    SET    refunded_amount = refunded_amount
                             + (SELECT R.refund
                                FROM   dbo.SuspendRefunds(@business_id) R
                                WHERE  R.order_id = Payment.order_id)
    WHERE  order_id IN (SELECT R.order_id FROM dbo.SuspendRefunds(@business_id) R);

    UPDATE Orders
    SET    status = CASE
                WHEN NOT EXISTS (SELECT 1 FROM SubOrder S
                                 WHERE S.order_id = Orders.order_id
                                 AND   S.business_id <> @business_id
                                 AND   S.status <> 'Cancelled')
                     THEN 'Cancelled'
                WHEN NOT EXISTS (SELECT 1 FROM SubOrder S
                                 WHERE S.order_id = Orders.order_id
                                 AND   S.business_id <> @business_id
                                 AND   S.status NOT IN ('Cancelled', 'Delivered'))
                     THEN 'Delivered'
                WHEN EXISTS     (SELECT 1 FROM SubOrder S
                                 WHERE S.order_id = Orders.order_id
                                 AND   S.business_id <> @business_id
                                 AND   S.status IN ('Picked Up', 'Delivered'))
                     THEN 'In Progress'
                ELSE 'Placed'
            END
    WHERE  order_id IN (SELECT S.order_id FROM SubOrder S
                        WHERE S.business_id = @business_id AND S.status IN ('Placed', 'Assigned'));

    UPDATE Voucher
    SET    status = 'Unused'
    WHERE  voucher_id IN (SELECT O.voucher_id
                          FROM   Orders O
                          WHERE  O.status = 'Cancelled'
                          AND    O.order_id IN (SELECT S.order_id FROM SubOrder S
                                                WHERE S.business_id = @business_id
                                                AND   S.status IN ('Placed', 'Assigned')));

    UPDATE Orders
    SET    voucher_id = NULL
    WHERE  status = 'Cancelled'
    AND    voucher_id IS NOT NULL
    AND    order_id IN (SELECT S.order_id FROM SubOrder S
                        WHERE S.business_id = @business_id AND S.status IN ('Placed', 'Assigned'));

    UPDATE SubOrder
    SET    status = 'Cancelled'
    WHERE  business_id = @business_id
    AND    status IN ('Placed', 'Assigned');

    COMMIT TRANSACTION;
    RETURN 0;
END
GO


-- ====================================================================================================
-- 4.4.e  [Hard] Reinstate_Business
-- Student 4: Ahmed Hassan | ID: 65-33776
-- ====================================================================================================

-- 4.4.e  [HARD]  Ahmed Hassan - 65_33776
CREATE PROCEDURE Reinstate_Business
    @business_id INT, @super_admin_id INT
AS
BEGIN
    IF @business_id IS NULL OR @super_admin_id IS NULL
        RETURN -1;

    IF NOT EXISTS (SELECT 1 FROM Admin A WHERE A.admin_id = @super_admin_id AND A.role = 'Super Admin')
        RETURN -3;

    IF NOT EXISTS (SELECT 1 FROM Business B WHERE B.business_id = @business_id)
        RETURN -1;

    IF NOT EXISTS (SELECT 1 FROM Business B WHERE B.business_id = @business_id AND B.status = 'Suspended')
        RETURN -4;

    UPDATE Business
    SET    status = 'Active', suspension_reason = NULL
    WHERE  business_id = @business_id;

    RETURN 0;
END
GO


-- ====================================================================================================
-- 4.4.f  Create_Zone
-- Student 4: Ahmed Hassan | ID: 65-33776
-- ====================================================================================================

-- 4.4.f  Ahmed Hassan - 65_33776
CREATE PROCEDURE Create_Zone
    @zone_name VARCHAR(50), @delivery_fee DECIMAL(10,2), @super_admin_id INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Admin A WHERE A.admin_id = @super_admin_id AND A.role = 'Super Admin')
        RETURN -3;

    IF @zone_name IS NULL OR LEN(@zone_name) = 0 OR @delivery_fee IS NULL OR @delivery_fee < 0
        RETURN -1;

    IF EXISTS (SELECT 1 FROM Zone Z WHERE Z.zone_name = @zone_name)
        RETURN -2;

    INSERT INTO Zone (zone_name, delivery_fee)
    VALUES (@zone_name, @delivery_fee);

    RETURN 0;
END
GO


-- ====================================================================================================
-- 4.4.g  Update_Zone_Fee
-- Student 4: Ahmed Hassan | ID: 65-33776
-- ====================================================================================================

-- 4.4.g  Ahmed Hassan - 65_33776
CREATE PROCEDURE Update_Zone_Fee
    @zone_id INT, @new_fee DECIMAL(10,2), @super_admin_id INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Admin A WHERE A.admin_id = @super_admin_id AND A.role = 'Super Admin')
        RETURN -3;

    IF @new_fee IS NULL OR @new_fee < 0
       OR NOT EXISTS (SELECT 1 FROM Zone Z WHERE Z.zone_id = @zone_id)
        RETURN -1;

    UPDATE Zone
    SET    delivery_fee = @new_fee
    WHERE  zone_id = @zone_id;

    RETURN 0;
END
GO


-- ====================================================================================================
-- 4.4.h  Assign_Admin_Zone
-- Student 1: Yassin Khaled Ahmed Abdelaziz Elsetohy | ID: 64-10815 | T-10
-- ====================================================================================================

-- Name: Yassin Khaled Ahmed Abdelaziz Elsetohy, ID: 64-10815
CREATE PROCEDURE Assign_Admin_Zone
    @admin_id INT,
    @zone_id INT,
    @super_admin_id INT
AS
BEGIN
    IF NOT EXISTS (SELECT * FROM Admin WHERE admin_id = @super_admin_id AND role = 'Super Admin')
        RETURN -3

    IF NOT EXISTS (SELECT * FROM Admin WHERE admin_id = @admin_id AND role = 'Zone Admin')
        RETURN -1

    IF NOT EXISTS (SELECT * FROM Zone WHERE zone_id = @zone_id)
        RETURN -1

    UPDATE Admin SET zone_id = @zone_id WHERE admin_id = @admin_id

    RETURN 0
END
GO


-- ====================================================================================================
-- 4.4.i  Issue_Voucher
-- Student 1: Yassin Khaled Ahmed Abdelaziz Elsetohy | ID: 64-10815 | T-10
-- ====================================================================================================

-- Name: Yassin Khaled Ahmed Abdelaziz Elsetohy, ID: 64-10815
CREATE PROCEDURE Issue_Voucher
    @customer_id INT,
    @promo_code VARCHAR(30),
    @is_percentage BIT,
    @amount DECIMAL(10,2),
    @expiry_date DATE,
    @admin_id INT
AS
BEGIN
    IF NOT EXISTS (SELECT * FROM Admin WHERE admin_id = @admin_id)
        RETURN -3

    IF NOT EXISTS (SELECT * FROM Customer WHERE customer_id = @customer_id)
        RETURN -3

    IF EXISTS (SELECT * FROM Users WHERE user_id = @customer_id AND account_status = 'Blacklisted')
        RETURN -3

    IF @promo_code IS NULL OR @promo_code = '' OR @is_percentage IS NULL
       OR @amount IS NULL OR @amount <= 0
       OR (@is_percentage = 1 AND (@amount < 1 OR @amount > 100))
       OR @expiry_date IS NULL OR @expiry_date < CAST(GETDATE() AS DATE)
        RETURN -1

    IF EXISTS (SELECT * FROM Voucher WHERE promo_code = @promo_code)
        RETURN -2

    INSERT INTO Voucher (promo_code, is_percentage, amount, expiry_date, status, customer_id)
    VALUES (@promo_code, @is_percentage, @amount, @expiry_date, 'Unused', @customer_id)

    RETURN 0
END
GO


-- ====================================================================================================
-- 4.4.j  [Hard] Blacklist_Customer
-- Student 1: Yassin Khaled Ahmed Abdelaziz Elsetohy | ID: 64-10815 | T-10
-- ====================================================================================================

-- Name: Yassin Khaled Ahmed Abdelaziz Elsetohy, ID: 64-10815
CREATE PROCEDURE Blacklist_Customer
    @customer_id INT,
    @admin_id INT,
    @reason VARCHAR(255)
AS
BEGIN
    DECLARE @admin_role VARCHAR(20), @admin_zone INT

    SELECT @admin_role = role, @admin_zone = zone_id FROM Admin WHERE admin_id = @admin_id
    IF @admin_role IS NULL
        RETURN -3

    IF NOT EXISTS (SELECT * FROM Customer WHERE customer_id = @customer_id)
        RETURN -3

    IF @admin_role = 'Zone Admin'
       AND NOT EXISTS (SELECT * FROM Address WHERE customer_id = @customer_id AND zone_id = @admin_zone)
        RETURN -3

    IF @reason IS NULL OR @reason = ''
        RETURN -1

    IF EXISTS (SELECT * FROM Users WHERE user_id = @customer_id AND account_status = 'Blacklisted')
       OR EXISTS (SELECT * FROM Blacklist WHERE customer_id = @customer_id)
        RETURN -4

    DECLARE @orders TABLE (order_id INT)

    INSERT INTO @orders (order_id)
    SELECT O.order_id
    FROM Orders O INNER JOIN Cart C ON O.cart_id = C.cart_id
    WHERE C.customer_id = @customer_id
      AND O.status <> 'Cancelled'
      AND NOT EXISTS (SELECT * FROM SubOrder S
                      WHERE S.order_id = O.order_id AND S.status IN ('Picked Up', 'Delivered'))

    UPDATE Users SET account_status = 'Blacklisted' WHERE user_id = @customer_id

    INSERT INTO Blacklist (customer_id, admin_id, reason) VALUES (@customer_id, @admin_id, @reason)

    UPDATE SubOrder SET status = 'Cancelled'
    WHERE order_id IN (SELECT order_id FROM @orders) AND status IN ('Placed', 'Assigned')

    UPDATE Customer
    SET wallet_balance = wallet_balance
                         + ISNULL((SELECT SUM(P.amount - P.refunded_amount)
                                   FROM Payment P
                                   WHERE P.order_id IN (SELECT order_id FROM @orders)
                                     AND P.method <> 'Cash'), 0)
    WHERE customer_id = @customer_id

    UPDATE Payment SET refunded_amount = amount
    WHERE order_id IN (SELECT order_id FROM @orders)

    UPDATE Voucher SET status = 'Unused'
    WHERE voucher_id IN (SELECT O.voucher_id FROM Orders O
                         WHERE O.order_id IN (SELECT order_id FROM @orders))

    UPDATE Orders SET status = 'Cancelled', voucher_id = NULL
    WHERE order_id IN (SELECT order_id FROM @orders)

    DELETE FROM Voucher
    WHERE customer_id = @customer_id AND status = 'Unused'
      AND NOT EXISTS (SELECT * FROM Orders O WHERE O.voucher_id = Voucher.voucher_id)

    RETURN 0
END
GO


-- ====================================================================================================
-- 4.4.k  Lift_Customer_Blacklist
-- Student 1: Yassin Khaled Ahmed Abdelaziz Elsetohy | ID: 64-10815 | T-10
-- ====================================================================================================

-- Name: Yassin Khaled Ahmed Abdelaziz Elsetohy, ID: 64-10815
CREATE PROCEDURE Lift_Customer_Blacklist
    @customer_id INT,
    @admin_id INT
AS
BEGIN
    DECLARE @blacklisted_by INT

    SELECT @blacklisted_by = admin_id FROM Blacklist WHERE customer_id = @customer_id
    IF @blacklisted_by IS NULL
        RETURN -4

    IF @admin_id IS NULL OR @admin_id <> @blacklisted_by
        RETURN -3

    DELETE FROM Blacklist WHERE customer_id = @customer_id

    UPDATE Users SET account_status = 'Active' WHERE user_id = @customer_id

    RETURN 0
END
GO


-- ====================================================================================================
-- 4.4.l  ZoneOrderReport
-- Student 4: Ahmed Hassan | ID: 65-33776
-- ====================================================================================================

-- 4.4.l  Ahmed Hassan - 65_33776
CREATE FUNCTION dbo.ZoneOrderReport (@zone_id INT, @from_date DATE, @to_date DATE)
RETURNS TABLE
AS
RETURN
(
    SELECT  Z.zone_id,
            Z.zone_name,
            COUNT(DISTINCT O.order_id) AS number_of_orders,
            (SELECT CAST(AVG(X.total_amount) AS DECIMAL(10,2))
             FROM   Orders X
             WHERE  X.zone_id = Z.zone_id
             AND    X.status <> 'Cancelled'
             AND    CAST(X.order_date AS DATE) BETWEEN @from_date AND @to_date) AS avg_order_total,
            CAST(SUM(CASE WHEN S.total_price IS NULL THEN 0 ELSE S.total_price END) * 0.10
                 AS DECIMAL(10,2)) AS platform_commission
    FROM    Zone Z
    LEFT OUTER JOIN Orders   O ON Z.zone_id  = O.zone_id
                              AND O.status <> 'Cancelled'
                              AND CAST(O.order_date AS DATE) BETWEEN @from_date AND @to_date
    LEFT OUTER JOIN SubOrder S ON O.order_id = S.order_id
                              AND S.status <> 'Cancelled'
    WHERE   Z.zone_id = @zone_id
    AND     @from_date <= @to_date
    GROUP BY Z.zone_id, Z.zone_name
);
GO


-- ====================================================================================================
-- 4.4.m  TopRiders
-- Student 5: Youssef Amr | ID: 64-23059
-- ====================================================================================================

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
           U.first_name + ' ' + U.last_name AS rider_name, 
           COUNT(*) AS completed_delivery_count
    FROM Delivery D
    INNER JOIN Rider R ON R.rider_id = D.rider_id
    INNER JOIN Users U ON U.user_id = R.rider_id
    WHERE D.delivered_at IS NOT NULL 
    AND (CAST(D.delivered_at AS DATE) BETWEEN @from_date AND @to_date) 
    AND @from_date <= @to_date 
    GROUP BY R.rider_id, U.first_name, U.last_name
    ORDER BY completed_delivery_count DESC, R.rider_id
);
GO 


-- ====================================================================================================
-- 4.4.n  Daily_Revenue_Report
-- Student 4: Ahmed Hassan | ID: 65-33776
-- ====================================================================================================

-- 4.4.n  Ahmed Hassan - 65_33776
CREATE FUNCTION dbo.Daily_Revenue_Report (@report_date DATE)
RETURNS TABLE
AS
RETURN
(
    SELECT  Z.zone_name,
            'Restaurant' AS business_type,
            COUNT(S.suborder_id) AS number_of_suborders,
            CAST(SUM(S.total_price) AS DECIMAL(10,2)) AS gross_sales,
            CAST(SUM(S.delivery_fee) AS DECIMAL(10,2)) AS delivery_fees,
            CAST(SUM(S.total_price) * 0.10 AS DECIMAL(10,2)) AS platform_commission
    FROM    SubOrder S
    INNER JOIN Orders     O ON S.order_id = O.order_id
    INNER JOIN Business   B ON S.business_id = B.business_id
    INNER JOIN Zone       Z ON B.zone_id = Z.zone_id
    INNER JOIN Restaurant R ON B.business_id = R.business_id
    WHERE   CAST(O.order_date AS DATE) = @report_date
    AND     S.status <> 'Cancelled'
    GROUP BY Z.zone_name

    UNION ALL

    SELECT  Z.zone_name,
            'Pharmacy' AS business_type,
            COUNT(S.suborder_id) AS number_of_suborders,
            CAST(SUM(S.total_price) AS DECIMAL(10,2)) AS gross_sales,
            CAST(SUM(S.delivery_fee) AS DECIMAL(10,2)) AS delivery_fees,
            CAST(SUM(S.total_price) * 0.10 AS DECIMAL(10,2)) AS platform_commission
    FROM    SubOrder S
    INNER JOIN Orders   O  ON S.order_id = O.order_id
    INNER JOIN Business B  ON S.business_id = B.business_id
    INNER JOIN Zone     Z  ON B.zone_id = Z.zone_id
    INNER JOIN Pharmacy Ph ON B.business_id = Ph.business_id
    WHERE   CAST(O.order_date AS DATE) = @report_date
    AND     S.status <> 'Cancelled'
    GROUP BY Z.zone_name
);
GO


-- ====================================================================================================
-- 4.5.a  Register_Business
-- Student 2: Mostafa Ahmed Emam | ID: 64-14029 | T-16
-- ====================================================================================================

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


-- ====================================================================================================
-- 4.5.b  Update_Business_Info
-- Student 2: Mostafa Ahmed Emam | ID: 64-14029 | T-16
-- ====================================================================================================

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

	IF NOT EXISTS (SELECT 1 FROM Business WHERE business_id = @business_id)
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


-- ====================================================================================================
-- 4.5.c  Upsert_Product
-- Student 2: Mostafa Ahmed Emam | ID: 64-14029 | T-16
-- ====================================================================================================

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
	
	IF @price <= 0 OR LTRIM(RTRIM(@name)) = '' OR @business_status IS NULL
		RETURN -1;

	IF @business_status = 'Suspended'
		RETURN -4;

	IF @product_id IS NOT NULL
		BEGIN
			IF @product_business_id IS NULL
				RETURN -1;

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


-- ====================================================================================================
-- 4.5.d  Toggle_Product_Status
-- Student 2: Mostafa Ahmed Emam | ID: 64-14029 | T-16
-- ====================================================================================================

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

	IF @is_available IS NULL OR @business_id IS NULL
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


-- ====================================================================================================
-- 4.5.e  Set_Product_Promotion
-- Student 2: Mostafa Ahmed Emam | ID: 64-14029 | T-16
-- ====================================================================================================

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

	IF @price IS NULL OR @discount_amount IS NULL OR @discount_amount < 0 OR 2 * @discount_amount > @price
		RETURN -1;

	UPDATE p
	SET p.discount_amount = @discount_amount
	FROM Product p
	WHERE p.product_id = @product_id;

	RETURN 0;
END;
GO


-- ====================================================================================================
-- 4.5.f  BusinessSalesReport
-- Student 2: Mostafa Ahmed Emam | ID: 64-14029 | T-16
-- ====================================================================================================


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


-- ====================================================================================================
-- 4.5.g  BusinessFeedbackOverview
-- Student 5: Youssef Amr | ID: 64-23059
-- ====================================================================================================

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
    AND EXISTS (SELECT 1 FROM Business WHERE business_id = @business_id)
);
-- COUNT(*) because id is unique so it must exist for feedback row to exist
GO


-- ====================================================================================================
-- 4.6.a  Add_Customer_Address
-- Student 3: Sherif Tamer Mohamed Ahmed Sherif | ID: 64-11320
-- ====================================================================================================




/*
the first requiremnt

4.6 As a Customer, I should be able to:
a) Add a new address. It becomes my active address and all the other addresses become inactive
Type: Stored Procedure
Name: Add_Customer_Address
Input: customer_id int, description varchar(150), zone_id int
Output: Nothing
*/




CREATE PROCEDURE Add_Customer_Address
    @customer_id int,
    @description varchar(150),
    @zone_id int
AS
BEGIN
    -- validate the customer and the zone before deactivating existing addresses
    IF NOT EXISTS (SELECT * FROM Customer WHERE customer_id = @customer_id)
    BEGIN
        RETURN -1;
    END

    --if it is all spaces or NULL, reject it 
    IF @description IS NULL OR LTRIM(RTRIM(@description)) = ''
    BEGIN
        RETURN -1;
    END

    IF NOT EXISTS (SELECT * FROM Zone WHERE zone_id = @zone_id)
    BEGIN
        RETURN -1;
    END

    UPDATE Address
    SET is_active = 0
    WHERE customer_id = @customer_id;

    INSERT INTO Address(description, is_active, customer_id, zone_id)
    VALUES(@description, 1, @customer_id, @zone_id);

    RETURN 0; 
END
GO


-- ====================================================================================================
-- 4.6.b  Update_Delete_Customer_Address
-- Student 3: Sherif Tamer Mohamed Ahmed Sherif | ID: 64-11320
-- ====================================================================================================




/*
the 2nd requirement

b) Update (description and zone) or delete one of my addresses. Reject it if the address is not mine or
belongs to a Placed or In Progress order. Also reject Delete if it is used by any cart.
Type: Stored Procedure
Name: Update_Delete_Customer_Address
Input: customer_id int, address_id int, description varchar(150), zone_id int, action varchar(20)
Output: Nothing



*/
create Procedure Update_Delete_Customer_Address
    @customer_id int,
    @address_id int,
    @description varchar(150),
    @zone_id int,
    @action varchar(20)
As
Begin
    -- reject if the address is not mine or does not exist
    if not exists (
        select *
        from Address
        where customer_id = @customer_id and address_id = @address_id)
    begin
        return -3;
    end

    -- reject if the address belongs to a Placed or In Progress order
    if exists (
        select *
        from Orders o inner join Cart c on o.cart_id = c.cart_id
        where c.address_id = @address_id
          and o.status in ('Placed', 'In Progress'))
    begin
        return -4;
    end



    -- reject if the action is neither Update nor Delete
    if @action is null or @action not in ('Update', 'Delete') -- [MODIFIED] NULL action made "not in" evaluate to unknown and slipped through
    begin
        return -1;
    end


    if @action = 'Update'
    begin
        -- the new zone must exist
        if @zone_id is null or not exists (select * from Zone where zone_id = @zone_id)
        begin
            return -1;
        end

        -- [ADDED] the new description must not be NULL or all spaces (same rule as Add_Customer_Address)
        if @description is null or ltrim(rtrim(@description)) = ''
        begin
            return -1;
        end

        update Address
        set description = @description, zone_id = @zone_id
        where customer_id = @customer_id and address_id = @address_id;

        return 0;
    end
    else if @action = 'Delete'  -- Delete
    begin
        -- reject if the address is used by any cart (any status)
        if exists (select * from Cart where address_id = @address_id)
        begin
            return -4;
        end

        delete from Address
        where customer_id = @customer_id and address_id = @address_id;

        return 0;
    end
END
GO


-- ====================================================================================================
-- 4.6.c  Change_Active_Address
-- Student 3: Sherif Tamer Mohamed Ahmed Sherif | ID: 64-11320
-- ====================================================================================================

/*
and for the 7th requirement
c) Set the selected address as the customer’s active address, ensuring only one address is active at a
time. Reject the request if the address does not belong to the customer. New carts and orders will use
the active address, while carts linked to other addresses remain saved but unavailable until their address
becomes active again.
Type: Stored Procedure
Name: Change_Active_Address
Input: customer_id int, new_address_id int
Output: Nothing
*/
create Procedure Change_Active_Address
    @customer_id int,
    @new_address_id int
As
begin 

    -- reject if the new address does not belong to the customer
    if not exists (select * from Address where customer_id = @customer_id and address_id = @new_address_id)
    begin
        return -3;
    end

    -- set all addresses of the customer to inactive
    update Address
    set is_active = 0
    where customer_id = @customer_id;

    -- set the new address as active
    update Address
    set is_active = 1
    where address_id = @new_address_id and customer_id = @customer_id;

    return 0;


end
GO


-- ====================================================================================================
-- 4.6.d  Add_Card
-- Student 3: Sherif Tamer Mohamed Ahmed Sherif | ID: 64-11320
-- ====================================================================================================


/*

and for the 3rd requirement 

d) Save a card.
Type: Stored Procedure
Name: Add_Card
Input: customer_id int, card_no char(16), card_holder_name varchar(100), expiration_date date
Output: Nothing
*/


create Procedure Add_Card
    @customer_id int,
    @card_no char(16),
    @card_holder_name varchar(100),
    @expiration_date date
As
begin 
    --  reject if the customer does not exist
    if not exists (select * from Customer where customer_id = @customer_id)
    begin
        return -1;
    end

    -- reject if the card number is NULL or is not exactly 16 digits (a shorter value is space-padded by char(16))
    if @card_no is null or @card_no like '%[^0-9]%'
    begin
        return -1;
    end

    -- reject if the card holder name is NULL or all spaces
    if @card_holder_name is null or ltrim(rtrim(@card_holder_name)) = ''
    begin
        return -1;
    end

    -- reject if the expiration date is NULL or already passed
    if @expiration_date is null or @expiration_date < cast(getdate() as date)
    begin
        return -1;
    end

    -- reject if the customer already saved this card 
    if exists (select * from Card where customer_id = @customer_id and card_no = @card_no)
    begin
        return -2;
    end

    insert into Card(card_no, card_holder_name, expiration_date, customer_id)
    values(@card_no, @card_holder_name, @expiration_date, @customer_id);

    return 0; -- [ADDED]
end
GO


-- ====================================================================================================
-- 4.6.e  Create_Cart
-- Student 3: Sherif Tamer Mohamed Ahmed Sherif | ID: 64-11320
-- ====================================================================================================



/*

and for the 4th requirement 
e) Create an empty cart for my active address, which is picked automatically (I am not asked for an
address). Reject it if I am Blacklisted, I have no active address, or my active address already has an Active
cart (only one Active cart per active address).
Type: Stored Procedure
Name: Create_Cart
Input: customer_id int
Output: Nothing
*/

create Procedure Create_Cart
    @customer_id int
AS
begin 

    -- reject if the user is not a customer
    if not exists (select * from Customer where customer_id = @customer_id)
    begin
        return -3;
    end

    -- reject if the user is Blacklisted
    if exists (select * from Users where user_id = @customer_id and account_status = 'Blacklisted')
    begin
        return -3;
    end
    -- reject if the user has no active address
    if not exists (select * from Address where customer_id = @customer_id and is_active = 1)
    begin
        return -1;-- a missing active address breaks a business rule (BR-8) so it is -1 ------------------- not sure of this error code  ------------------------------------------------------
    end
    --if my active address already has an Active cart, reject it
    if exists (select * from Cart c inner join Address a on c.address_id = a.address_id
               where a.customer_id = @customer_id and a.is_active = 1 and c.status = 'Active')
    begin
        return -2; -- the record already exists so it is Duplicate (-2)
    end
    --now create the cart for the active address
    insert into Cart(status,created_at,customer_id,address_id)
    select 'Active', getdate(), @customer_id, address_id
    from Address
    where customer_id = @customer_id and is_active = 1;
    return 0;
end
GO


-- ====================================================================================================
-- 4.6.f  Add_To_Cart
-- Student 3: Sherif Tamer Mohamed Ahmed Sherif | ID: 64-11320
-- ====================================================================================================







/*
and for the 5th requirement 

f) Add a product with a quantity and optional note to my Active cart (the cart of my active address). If it is
already there, add to its quantity and replace the note if a new one is given. . Reject it with an error
message if the cart's address is not my active address or the product's business (e.g. a restaurant) is not
in the zone of my active address. Reject it if the resulting quantity would exceed 10.
Type: Stored Procedure
Name: Add_To_Cart
Input: cart_id int, product_id int, quantity int, notes varchar(255)
Output: Nothing

*/

create Procedure Add_To_Cart
    @cart_id int,
    @product_id int,
    @quantity int,
    @notes varchar(255)
as
Begin
    -- reject if the quantity is invalid (NULL, zero or negative)
    if @quantity is null or @quantity < 1
    begin
        return -1;
    end

    -- reject if the cart does not exist 
    if not exists (select * from Cart where cart_id = @cart_id)
    begin
        return -1;
    end

    -- reject if the cart is not Active
    if not exists (select * from Cart where cart_id = @cart_id and status = 'Active') -- [MODIFIED] existence is now checked above, so this one is only the status check (-4)
    begin
        return -4;
    end

    -- reject if the product does not exist
    if not exists (select * from Product where product_id = @product_id)
    begin
        return -1;
    end


    -- reject if the product is unavailable or its business is not Active 
    if not exists (
        select *
        from Product p inner join Business b on p.business_id = b.business_id
        where p.product_id = @product_id and p.is_available = 1 and b.status = 'Active')
    begin
        return -4;
    end


    -- reject if the cart's address is not my active address
    if not exists (
        select *
        from Cart c inner join Address a on c.address_id = a.address_id
        where c.cart_id = @cart_id and a.is_active = 1)
    begin
        return -4;
    end

    -- reject if the product's business is not in the zone of my active address
    if not exists (
        select *
        from Product p inner join Business b on p.business_id = b.business_id
        inner join Address a on b.zone_id = a.zone_id
        inner join Cart c on a.address_id = c.address_id
        where p.product_id = @product_id and c.cart_id = @cart_id and a.is_active = 1)
    begin
        return -5;
    end

    -- check if the product is already in the cart
    if exists (select * from CartItem where cart_id = @cart_id and product_id = @product_id)
    begin
        -- update the quantity and notes, ensuring the total quantity does not exceed 10
        declare @current_quantity int;
        select @current_quantity = quantity from CartItem where cart_id = @cart_id and product_id = @product_id;

        if (@current_quantity + @quantity) > 10
        begin
            return -6; 
        end
        if(@notes is null)
        begin
            update CartItem
            set quantity = @current_quantity + @quantity,
                notes = notes -- keep existing notes if no new notes are provided
            where cart_id = @cart_id and product_id = @product_id;
        end
        else
        begin    
            update CartItem
            set quantity = @current_quantity + @quantity,
            notes = @notes
            where cart_id = @cart_id and product_id = @product_id;
        end        
    end
    else
    begin
        -- insert new item into the cart, ensuring quantity does not exceed 10
        if @quantity > 10
        begin
            return -6; -- reject if initial quantity exceeds 10
        end

        insert into CartItem(cart_id, product_id, quantity, notes)
        values(@cart_id, @product_id, @quantity, @notes);
    end
    return 0;
end
GO


-- ====================================================================================================
-- 4.6.g  Remove_From_Cart
-- Student 3: Sherif Tamer Mohamed Ahmed Sherif | ID: 64-11320
-- ====================================================================================================







/* 

and for the 6th requirement

g) Remove a product from one of my Active carts.
Type: Stored Procedure
Name: Remove_From_Cart
Input: cart_id int, product_id int
Output: Nothing

*/


create Procedure Remove_From_Cart
    @cart_id int,
    @product_id int
As
begin
    --reject if the cart does not exist
    if not exists (select * from Cart where cart_id = @cart_id)
    begin
        return -1;
    end
    --reject if the product does not exist
    if not exists (select * from Product where product_id = @product_id)
    begin
        return -1;
    end

    -- reject if the cart is not Active (only Active carts can be edited, BR-8)
    if not exists (select * from Cart where cart_id = @cart_id and status = 'Active')
    begin
        return -4;
    end

    -- reject if the product is not in the cart
    if not exists (select * from CartItem where cart_id = @cart_id and product_id = @product_id)
    begin
        return -1;
    end


    --if both the cart and the product exist, delete the product from the cart
    delete from CartItem
    where cart_id = @cart_id and product_id = @product_id;
    return 0;
end
GO


-- ====================================================================================================
-- 4.6.h  Calculate_Voucher_Discount
-- Student 3: Sherif Tamer Mohamed Ahmed Sherif | ID: 64-11320
-- ====================================================================================================

/*
and for the 8th requirement
h) Return the discount of a voucher on a subtotal (BR-13), or 0 if the voucher is NULL, missing, not
Unused or expired. It does not change the voucher.
Type: Function (scalar)
Name: Calculate_Voucher_Discount
Input: voucher_id int, order_subtotal decimal(10,2)
Output: discount decimal(10,2)h) Return the discount of a voucher on a subtotal (BR-13), or 0 if the voucher is NULL, missing, not
Unused or expired. It does not change the voucher.
Type: Function (scalar)
Name: Calculate_Voucher_Discount
Input: voucher_id int, order_subtotal decimal(10,2)
Output: discount decimal(10,2)
*/

Create Function dbo.Calculate_Voucher_Discount
(
    @voucher_id int,
    @order_subtotal decimal(10,2)
)

returns decimal(10,2)
as
begin
    declare @discount decimal(10,2) = 0;

    -- invalid subtotal
    if @order_subtotal is null or @order_subtotal < 0
    begin
        return -1;
    end

    if @voucher_id is not null -- case that the voucher is null
    begin
        --calculate the discount based on the voucher's type and amount, only if the voucher is valid
        select @discount = case when v.is_percentage = 1
                                then @order_subtotal * v.amount / 100
                                else v.amount end
        from Voucher v
        where v.voucher_id = @voucher_id -- case that the voucher is missing
        and v.status = 'Unused' -- case that the voucher is not Unused
        and v.expiry_date >= cast(getdate() as date); -- case that the voucher is expired
    end

    -- the discount never exceeds the subtotal
    if @discount > @order_subtotal
    begin
        set @discount = @order_subtotal;
    end

    return @discount;
end
GO


-- ====================================================================================================
-- 4.6.i  [Hardest] Checkout_Cart
-- Student 3: Sherif Tamer Mohamed Ahmed Sherif | ID: 64-11320
-- ====================================================================================================




/*
and now for the first hardest requirement
i) [Hardest!] Checkout a cart into an order as one atomic unit.
o Reject the whole checkout if: the cart is not Active or is empty; the customer is Blacklisted;
the cart address is not the active address of the customer (the order always goes to the
active address and no address is given as input); any product is unavailable, from a business
that is not Active, outside the zone of the active address (return the zone mismatch error
code) or closed now (BR-6) ; the voucher is not valid ; the payment cannot be made (next
point);
o Payment (BR-10): the whole order is paid with one method. Card needs a valid card_id of the
customer; Wallet needs enough balance; Cash needs nothing.
o Copy each effective unit price into CartItem.unit_price, create the order (zone of the
address), and create one SubOrder per business (not per business type) with its total_price
and delivery_fee. The new order starts as Placed (BR-11).
o Compute and store discount_amount (Calculate_Voucher_Discount) and total_amount .
Mark the voucher Used.
o Create one Delivery per SubOrder and set each SubOrder to Assigned.
o Create the Payment, deduct total_amount from the wallet if the method is Wallet, and set
the cart to Checked Out.
Type: Stored Procedure
Name: Checkout_Cart
Input: cart_id int, voucher_id int (nullable), payment_method varchar(20), card_id int (nullable)
Output: Nothing
*/
-- Implemented by: <Your Name> (<Your ID>) -- ADDED
create Procedure Checkout_Cart
    @cart_id int,
    @voucher_id int = null,
    @payment_method varchar(20),
    @card_id int = null
As
begin
    -- the first reject bullet point 
    -- Reject if the cart does not exist (invalid input)
    if not exists (select * from Cart where cart_id = @cart_id)
    begin
        return -1;
    end

    -- Reject if the cart is not Active
    if not exists (select * from Cart where cart_id = @cart_id and status = 'Active')
    begin
        return -4; -- CHANGED: wrong status (was -1)
    end

    -- Reject if the cart is empty
    if not exists (select * from CartItem where cart_id = @cart_id)
    begin
        return -9; 
    end

    -- Reject if the customer is Blacklisted
    declare @customer_id int;
    select @customer_id = customer_id from Cart where cart_id = @cart_id;

    if exists (select * from Blacklist where customer_id = @customer_id)
       or exists (select * from Users where user_id = @customer_id and account_status = 'Blacklisted')
    begin
        return -3; -- Customer is Blacklisted
    end
    -- Reject if the cart address is not the active address of the customer
    if not exists (
        select * from Cart c inner join Address a on c.address_id = a.address_id
        where c.cart_id = @cart_id and a.customer_id = @customer_id and a.is_active = 1)
    begin
        return -4; -- Cart address is not the active address of the customer
    end

    -- Reject if any product is unavailable
    if exists (
        select * from CartItem ci
        inner join Product p on ci.product_id = p.product_id
        where ci.cart_id = @cart_id and p.is_available = 0)
    begin
    
        return -4;
    end
    --reject if the product is from a business that is not Active
    if exists (
        select * from CartItem ci
        inner join Product p on ci.product_id = p.product_id
        inner join Business b on p.business_id = b.business_id
        where ci.cart_id = @cart_id and b.status != 'Active')
    begin
        return -4;
    end
    -- reject outside the zone of the active address
    declare @zone_id int;
    select @zone_id = zone_id from Address where customer_id = @customer_id and is_active = 1;

    if exists (
        select * from CartItem ci
        inner join Product p on ci.product_id = p.product_id
        inner join Business b on p.business_id = b.business_id
        where ci.cart_id = @cart_id and b.zone_id != @zone_id)
    begin
        return -5;
    end
    -- reject if the buisness is closed now
    if exists (
        select * from CartItem ci
        inner join Product p on ci.product_id = p.product_id
        inner join Business b on p.business_id = b.business_id
        where ci.cart_id = @cart_id
          and not (
                 b.opening_hour = b.closing_hour
              or (b.opening_hour < b.closing_hour and cast(getdate() as time) >= b.opening_hour and cast(getdate() as time) < b.closing_hour)
              or (b.opening_hour > b.closing_hour and (cast(getdate() as time) >= b.opening_hour or cast(getdate() as time) < b.closing_hour))))
    begin
        return -1; -- violates buisness rule
    end

    -- reject if the voucher is not valid
    if @voucher_id is not null
    begin
        if not exists (
            select * from Voucher v
            where v.voucher_id = @voucher_id and v.customer_id = @customer_id and v.status = 'Unused' and v.expiry_date >= cast(getdate() as date))
        begin
            return -1; 
        end
    end

    --claculating everything here
    declare @order_total_before_discount decimal(10,2);
    declare @discount_amount decimal(10,2);
    declare @order_total decimal(10,2);
    declare @delivery_fee decimal(10,2);
    declare @business_count int;

    select @order_total_before_discount = sum(ci.quantity * (p.price - p.discount_amount)) -- thios is the price of the product after the discount on the product not the voucher
    from CartItem ci inner join Product p on ci.product_id = p.product_id
    where ci.cart_id = @cart_id;

    select @delivery_fee = delivery_fee from Zone where zone_id = @zone_id;

    select @business_count = count(distinct p.business_id)
    from CartItem ci inner join Product p on ci.product_id = p.product_id
    where ci.cart_id = @cart_id;

    set @discount_amount = dbo.Calculate_Voucher_Discount(@voucher_id, @order_total_before_discount);
    set @order_total = @order_total_before_discount + (@delivery_fee * @business_count) - @discount_amount; -- CHANGED: BR-9 includes the delivery fees-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    --reject if the payment cannot be made
    --must be one of these
    if @payment_method is null or @payment_method not in ('Cash', 'Card', 'Wallet')
    begin
        return -1;
    end
    -- now other verificstions
    if @payment_method = 'Card'
    begin
        if not exists (select * from Card where card_id = @card_id and customer_id = @customer_id and expiration_date >= cast(getdate() as date))
        begin
            return -7; 
        end
    end
    else if @payment_method = 'Wallet'
    begin
        declare @wallet_balance decimal(10,2);
        select @wallet_balance = wallet_balance from Customer where customer_id = @customer_id; 
        if @wallet_balance < @order_total
        begin
            return -7; 
        end
    end

    -- reject if there is no available rider with an Active account in the zone -------------------------------------------------------------------------------------------------------------- check this part again ------------------------------------------------------------------------------------------------------------------------------
    if not exists (
        select * from Rider r inner join Users u on u.user_id = r.rider_id
        where r.zone_id = @zone_id and r.is_available = 1 and u.account_status = 'Active')
    begin
        return -8;
    end


    set xact_abort on;
    begin try
    begin transaction;

    -- copying each effective unit price into CartItem.unit_price since there may be updates in the price
    update ci
    set ci.unit_price = p.price - p.discount_amount -- CHANGED: effective price (BR-7)
    from CartItem ci
    inner join Product p on ci.product_id = p.product_id
    where ci.cart_id = @cart_id;

    -- create the order

    insert into Orders(order_date, status, discount_amount,
                         total_amount, cart_id, zone_id,voucher_id)
    values(getdate(), 'Placed', @discount_amount,
           @order_total, @cart_id, @zone_id, @voucher_id);


    -- now store the order id to use later 
    Declare @order_id int;
    select @order_id = order_id
    from Orders
    where cart_id=@cart_id and zone_id= @zone_id;


    -- create one SubOrder per business (not per business type) with its total_price and delivery_fee. The new order starts as Placed (BR-11).
    insert into SubOrder (status,total_price,delivery_fee,order_id,business_id)
    select 'Placed',
           sum(ci.quantity * ci.unit_price),
           @delivery_fee,
           @order_id,
           p.business_id
    from CartItem ci inner join Product p on ci.product_id = p.product_id
    where ci.cart_id = @cart_id
    group by p.business_id;

    -- mark the voucher as Used
    if @voucher_id is not null
    begin
        update Voucher set status = 'Used' where voucher_id = @voucher_id;
    end

    -- Create one Delivery per SubOrder, assigned to the least-busy rider (ties: smallest rider_id)
    declare @suborder_id int;
    declare @rider_id int;
    select @suborder_id = min(suborder_id) from SubOrder where order_id = @order_id;

    while @suborder_id is not null
    begin
        select top 1 @rider_id = r.rider_id
        from Rider r inner join Users u on u.user_id = r.rider_id
        where r.zone_id = @zone_id and r.is_available = 1 and u.account_status = 'Active'
        order by (select count(*)
                  from Delivery d inner join SubOrder s on s.suborder_id = d.suborder_id
                  where d.rider_id = r.rider_id and s.status in ('Assigned', 'Picked Up')),
                 r.rider_id;

        insert into Delivery(assigned_at, suborder_id, rider_id)
        values(getdate(), @suborder_id, @rider_id);

        update SubOrder set status = 'Assigned' where suborder_id = @suborder_id;

        select @suborder_id = min(suborder_id)
        from SubOrder
        where order_id = @order_id and suborder_id > @suborder_id;
    end

    -- now we should pay 
    
    insert into Payment(amount,currency,method,transaction_date,refunded_amount,order_id,card_id) ---------------------------------- currency is EGP per BR-10, so this is correct ------------------------------------
    values(@order_total, 'EGP', @payment_method, getdate(), 0, @order_id,
           case when @payment_method = 'Card' then @card_id else null end);

    -- deduct the wallet if paying by Wallet
    if @payment_method = 'Wallet'
    begin
        update Customer
        set wallet_balance = wallet_balance - @order_total
        where customer_id = @customer_id;
    end

    -- Chang ethe cart to checked out
    update Cart set status = 'Checked Out' where cart_id = @cart_id;

    commit transaction;
    return 0;
    end try
    begin catch
        if @@trancount > 0 rollback transaction;
        return -1;
    end catch
end
GO


-- ====================================================================================================
-- 4.6.j  [Hard] Cancel_Order
-- Student 3: Sherif Tamer Mohamed Ahmed Sherif | ID: 64-11320
-- ====================================================================================================









/*
and for the second hardest requirement
j) [Hard] Cancel an order before anything is picked up.
o Reject it if the order is Cancelled or any SubOrder is Picked Up or Delivered.
o Cancel all remaining SubOrders (and so their Deliveries) and the order, and refund the
remaining amount (BR-14).
o If a voucher was used, set it back to Unused and set the order's voucher_id to NULL.
Type: Stored Procedure
Name: Cancel_Order
Input: order_id int

*/


Create Procedure Cancel_Order
    @order_id int
As
Begin
    
    --reject if the order does not exist
    if not exists (select * from Orders where order_id = @order_id)
    begin
        return -1; -- Order does not exist ------------------------------------------------------------------------------------------------------------------------------------------------ -1 (invalid input) is fine here
    end

    -- reject if the order is Cancelled or Delivered, or any SubOrder is Picked Up or Delivered
    if exists (select * from Orders where order_id = @order_id and status in ('Cancelled', 'Delivered'))
       or exists (select * from SubOrder where order_id = @order_id and status in ('Picked Up', 'Delivered'))
    begin
        return -4; 
    end

    -- get the remaining refund amount and payment method
    declare @refund_amount decimal(10,2);
    declare @payment_method varchar(20);
    declare @customer_id int;

    select 
        @refund_amount = p.amount - p.refunded_amount,
        @payment_method = p.method
    from Payment p
    where p.order_id = @order_id;

    -- reject if no payment record exists - -----------------------------------------------------------------------------------------
    if @refund_amount is null
    begin
        return -7; -- Payment cannot be made
    end

    -- cancel all remaining SubOrders order and their Deliveries
    update SubOrder
    set status = 'Cancelled'
    where order_id = @order_id and status in ('Placed', 'Assigned');

    -- cancel the order
    update Orders
    set status = 'Cancelled'
    where order_id = @order_id;

    -- get the customer who placed the order to use when getting teh wallet balance and refunding the amount
    select @customer_id = c.customer_id
    from Orders o
    inner join Cart c on o.cart_id = c.cart_id
    where o.order_id = @order_id;

    -- refund the remaining amount (BR-14)
    update Payment
    set refunded_amount = refunded_amount + @refund_amount
    where order_id = @order_id;

    -- Only credit the customer's wallet if the payment method is not Cash
    if @payment_method != 'Cash'
    begin
        update Customer
        set wallet_balance = wallet_balance + @refund_amount
        where customer_id = @customer_id;
    end

    -- if a voucher was used, set it back to Unused and set the order's voucher_id to NULL
    declare @voucher_id int;
    select @voucher_id = voucher_id from Orders where order_id = @order_id;
    if @voucher_id is not null
    begin
        update Voucher
        set status = 'Unused'
        where voucher_id = @voucher_id;

        update Orders
        set voucher_id = null
        where order_id = @order_id;
    end

    return 0;
end
GO


-- ====================================================================================================
-- 4.6.k  Reorder
-- Student 3: Sherif Tamer Mohamed Ahmed Sherif | ID: 64-11320
-- ====================================================================================================



/*
and for the 9th requirement
k) Create a new Active cart with the same products, quantities and notes as a past order, skipping
products that can no longer be ordered, for an address I choose. The chosen address must be mine and
in the same zone as the original order; if it is not my active address, it becomes my active address. Reject
it if I am Blacklisted, the chosen address is not mine or is in a different zone from the order, the chosen
address already has an Active cart (BR-8) or nothing can be copied.
Type: Stored Procedure
Name: Reorder
Input: order_id int, address_id int
Output: Nothing
*/


create Procedure Reorder
    @order_id int,
    @address_id int
As
begin

    -- reject if the order does not exist
    if not exists (select * from Orders where order_id = @order_id)
    begin
        return -1;
    end

    -- reject if the address does not belong to the customer
    declare @customer_id int;
    select @customer_id = c.customer_id
    from Orders o inner join Cart c on o.cart_id = c.cart_id
    where o.order_id = @order_id;

    if exists (select * from Blacklist where customer_id = @customer_id)
       or exists (select * from Users where user_id = @customer_id and account_status = 'Blacklisted')
    begin
        return -3;
    end

    if not exists (select * from Address where address_id = @address_id and customer_id = @customer_id)
    begin
        return -3;
    end

    -- reject if the address is in a different zone from the original order
    declare @original_zone_id int;
    select @original_zone_id = z.zone_id
    from Orders o inner join Zone z on o.zone_id = z.zone_id
    where o.order_id = @order_id;

    declare @new_zone_id int;
    select @new_zone_id = z.zone_id
    from Address a inner join Zone z on a.zone_id = z.zone_id
    where a.address_id = @address_id;

    if @original_zone_id != @new_zone_id
    begin
        return -5; -- zone mismatch error code
    end

    -- reject if the customer is Blacklisted
    if exists (select * from Blacklist b where b.customer_id = @customer_id )
    begin
        return -3; -- Blacklisted error code
    end

    -- reject if the chosen address already has an Active cart
    if exists (select * from Cart c where c.address_id = @address_id and c.status = 'Active')
    begin
        return -2; -- Duplicate error code
    end

    --nothing can be copied or the products are out of stock or the buisnness is not active
    if not exists (
        select *
        from Orders o inner join CartItem ci on ci.cart_id = o.cart_id
        where o.order_id = @order_id
          and ci.product_id in (select p.product_id
                                from Product p inner join Business b on p.business_id = b.business_id
                                where p.is_available = 1 and b.status = 'Active'))
    begin
        return -9; --  "Nothing to process" is -9 (-6 is limit exceeded)
    end

    --if the chosen address is not my active address, set it as my active address
    if not exists (select * from Address where address_id = @address_id and is_active = 1)
    begin
        Update Address
        set is_active = 0
        where customer_id = @customer_id;

        update Address
        set is_active = 1
        where address_id = @address_id and customer_id = @customer_id;
    end

    -- create a new Active cart for the chosen address
    insert into Cart(status, created_at, customer_id, address_id)
    values('Active', getdate(), @customer_id, @address_id);

    -- copy products, quantities, and notes from the past order to the new cart, skipping unavailable products
  
    insert into CartItem(cart_id, product_id, quantity, notes)
    select c.cart_id, ci.product_id, ci.quantity, ci.notes
    from Orders o inner join CartItem ci on ci.cart_id = o.cart_id
    inner join Cart c on c.cart_id = (select top 1 cart_id from Cart where address_id = @address_id and status = 'Active')
    where o.order_id = @order_id
      and ci.product_id in (select p.product_id
                            from Product p inner join Business b on p.business_id = b.business_id
                            where p.is_available = 1 and b.status = 'Active');
    return 0;
end
GO


-- ====================================================================================================
-- 4.6.l  Submit_Feedback
-- Student 5: Youssef Amr | ID: 64-23059
-- ====================================================================================================

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


-- ====================================================================================================
-- 4.6.m  Rate_Rider
-- Student 5: Youssef Amr | ID: 64-23059
-- ====================================================================================================

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


-- ====================================================================================================
-- 4.6.n  My_Order_History
-- Student 3: Sherif Tamer Mohamed Ahmed Sherif | ID: 64-11320
-- ====================================================================================================




/*
and for the 10th requirement
n) My order history.
Type: Table-Valued Function
Name: My_Order_History
Input: customer_id int
Output: Table (order_id, order_date, zone_name, status, number_of_suborders, discount_amount,
total_amount, payment_method, refunded_amount)
*/
-- Implemented by: <Your Name> (<Your ID>)
create Function dbo.My_Order_History
(
    @customer_id int
)
returns @result table
(
    order_id int,
    order_date datetime, 
    zone_name varchar(50),
    status varchar(20),
    number_of_suborders int,
    discount_amount decimal(10,2),
    total_amount decimal(10,2),
    payment_method varchar(20),
    refunded_amount decimal(10,2)
)
as
begin

    insert into @result
    select o.order_id, o.order_date, z.zone_name, o.status,
           (select count(*) from SubOrder so where so.order_id = o.order_id),
           o.discount_amount, o.total_amount,
           p.method,
           p.refunded_amount 
    from Orders o 
    inner join Cart c on o.cart_id = c.cart_id 
    inner join Zone z on o.zone_id = z.zone_id
    left join Payment p on o.order_id = p.order_id
    where c.customer_id = @customer_id 

    return;
end
GO


-- ====================================================================================================
-- 4.6.o  Toggle_Favorite
-- Student 2: Mostafa Ahmed Emam | ID: 64-14029 | T-16
-- ====================================================================================================

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
	IF @item_type IS NULL OR @item_type NOT IN ('Business', 'Product') OR @item_id IS NULL
		RETURN -1;

	IF @customer_id IS NULL OR NOT EXISTS (SELECT 1 FROM Customer WHERE customer_id = @customer_id)
		RETURN -3;

	IF @item_type = 'Business' AND NOT EXISTS (SELECT 1 FROM Business WHERE business_id = @item_id)
		RETURN -1;

	IF @item_type = 'Product' AND NOT EXISTS (SELECT 1 FROM Product WHERE product_id = @item_id)
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


-- ====================================================================================================
-- 4.6.p  My_Favorites
-- Student 2: Mostafa Ahmed Emam | ID: 64-14029 | T-16
-- ====================================================================================================

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


-- ====================================================================================================
-- 4.6.q  [Hard] Recommended_Products
-- Student 5: Youssef Amr | ID: 64-23059
-- ====================================================================================================

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
    SELECT TOP 10 P.product_id, P.name AS product_name, B.name AS business_name, P.category, P.price - P.discount_amount AS final_price
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


-- ====================================================================================================
-- 4.7.a  Set_Rider_Availability
-- Student 5: Youssef Amr | ID: 64-23059
-- ====================================================================================================
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


-- ====================================================================================================
-- 4.7.b  My_Active_Deliveries
-- Student 5: Youssef Amr | ID: 64-23059
-- ====================================================================================================

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
           U.first_name + ' ' + U.last_name AS customer_name, 
           A.description AS address_description, Z.zone_name, S.status, D.assigned_at
    FROM Delivery D 
    INNER JOIN SubOrder S ON S.suborder_id = D.suborder_id
    INNER JOIN Orders O ON O.order_id = S.order_id
    INNER JOIN Business B ON B.business_id = S.business_id
    INNER JOIN Cart C ON C.cart_id = O.cart_id
    INNER JOIN Users U ON U.user_id = C.customer_id
    INNER JOIN Address A ON A.address_id = C.address_id
    INNER JOIN Zone Z ON A.zone_id = Z.zone_id
    WHERE D.rider_id = @rider_id
    AND S.status IN ('Assigned', 'Picked Up')
);
GO


-- ====================================================================================================
-- 4.7.c  Mark_Picked_Up
-- Student 5: Youssef Amr | ID: 64-23059
-- ====================================================================================================

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


-- ====================================================================================================
-- 4.7.d  Mark_Delivered
-- Student 5: Youssef Amr | ID: 64-23059
-- ====================================================================================================

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


-- ====================================================================================================
-- 4.7.e  My_Earnings
-- Student 5: Youssef Amr | ID: 64-23059
-- ====================================================================================================

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
        CAST(ISNULL(SUM(S.delivery_fee), 0) * 0.8 AS DECIMAL(10,2)) AS total_earnings
    FROM Delivery D
    INNER JOIN SubOrder S ON D.suborder_id = S.suborder_id
    WHERE CAST(D.delivered_at AS DATE) BETWEEN @from_date AND @to_date
      AND D.rider_id = @rider_id
      AND D.delivered_at IS NOT NULL
      AND @from_date <= @to_date --invalid or NULL dates give an empty table
      AND EXISTS (SELECT 1 FROM Rider WHERE rider_id = @rider_id) --unknown rider gives an empty table
);
GO


-- ====================================================================================================
-- 4.7.f  My_Rating_Summary
-- Student 5: Youssef Amr | ID: 64-23059
-- ====================================================================================================

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


-- ====================================================================================================
-- 4.7.g  My_Delivery_History
-- Student 5: Youssef Amr | ID: 64-23059
-- ====================================================================================================

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


-- ====================================================================================================
-- 4.8.a  [Hard] Search_Platform
-- Student 2: Mostafa Ahmed Emam | ID: 64-14029 | T-16
-- ====================================================================================================

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


-- ====================================================================================================
-- Helper function Expected_Total (used by 4.8.b Reconcile_Order_Totals)
-- Student 5: Youssef Amr | ID: 64-23059
-- ====================================================================================================

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


-- ====================================================================================================
-- 4.8.b  [Hard] Reconcile_Order_Totals
-- Student 5: Youssef Amr | ID: 64-23059
-- ====================================================================================================

CREATE FUNCTION dbo.Reconcile_Order_Totals
()
RETURNS TABLE
AS
RETURN
(   
    SELECT X.order_id, X.expected_total, X.order_total, X.payment_amount
    FROM (
        SELECT O.order_id,
               CAST(ISNULL((SELECT SUM(S.total_price + S.delivery_fee) FROM SubOrder S WHERE S.order_id = O.order_id), 0)
                    - O.discount_amount AS DECIMAL(10,2)) AS expected_total,
               O.total_amount AS order_total,
               P.amount AS payment_amount
        FROM Orders O
        LEFT OUTER JOIN Payment P ON P.order_id = O.order_id
    ) X
    WHERE X.expected_total <> X.order_total OR X.payment_amount <> X.order_total OR X.payment_amount IS NULL
);
GO


-- ====================================================================================================
-- 4.8.c  Nearby_Businesses_By_Category
-- Student 2: Mostafa Ahmed Emam | ID: 64-14029 | T-16
-- ====================================================================================================

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


-- ====================================================================================================
-- 4.8.d  Platform_Health_Snapshot
-- Student 5: Youssef Amr | ID: 64-23059
-- ====================================================================================================

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

            (SELECT CAST(AVG(CAST(tracking_time AS DECIMAL(10,2))) AS DECIMAL(10,2))
            FROM Delivery
            WHERE CAST(assigned_at AS DATE) = CAST(GETDATE() AS DATE)) 
            AS avg_delivery_time_today, 

            (SELECT COUNT(*) 
            FROM Feedback 
            WHERE rating<=2 
            AND CAST(feedback_date AS DATE) = CAST(GETDATE() AS DATE)) AS low_ratings_today
)
GO

