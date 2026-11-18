
-- 4.1.a  Ahmed Hassan - 65_33776
CREATE DATABASE LocalDeliveryMarketplace_Team_143;
GO
USE LocalDeliveryMarketplace_Team_143;
GO

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

-- 4.1.e  Ahmed Hassan - 65_33776
CREATE PROCEDURE clearAllTables
AS
BEGIN
    EXEC dropAllTables;
    EXEC createAllTables;
END
GO

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
