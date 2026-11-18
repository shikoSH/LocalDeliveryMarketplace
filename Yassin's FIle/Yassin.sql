-- Name: Yassin Khaled Ahmed Abdelaziz Elsetohy, ID: 64-10815
CREATE VIEW ActiveVouchers AS
SELECT voucher_id, promo_code, customer_id, is_percentage, amount, expiry_date
FROM Voucher
WHERE status = 'Unused' AND expiry_date >= CAST(GETDATE() AS DATE);
GO

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