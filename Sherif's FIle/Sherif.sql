



/*
the first requiremnt

4.6 As a Customer, I should be able to:
a) Add a new address. It becomes my active address and all the other addresses become inactive
Type: Stored Procedure
Name: Add_Customer_Address
Input: customer_id int, description varchar(150), zone_id int
Output: Nothing
*/



Create Procedure Add_Customer_Address
    @customer_id int,
    @description varchar(150),
    @zone_id int
AS
BEGIN
    update Address
    set is_active = 0
    where customer_id = @customer_id;

    insert into Address(description, is_active, customer_id, zone_id) 
        values(@description, 1, @customer_id, @zone_id);

END




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
    if @action not in ('Update', 'Delete')
    begin
        return -1;
    end


    if @action = 'Update'
    begin
        -- the new zone must exist
        if not exists (select * from Zone where zone_id = @zone_id)
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
            return -1;
        end

        delete from Address
        where customer_id = @customer_id and address_id = @address_id;

        return 0;
    end
END


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
    insert into Card(card_no, card_holder_name, expiration_date, customer_id)
    values(@card_no, @card_holder_name, @expiration_date, @customer_id);
end




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

    -- reject if the user is Blacklisted
    if exists (select * from Users where user_id = @customer_id and account_status = 'Blacklisted')
    begin
        return -3;
    end
    -- reject if the user has no active address
    if not exists (select * from Address where customer_id = @customer_id and is_active = 1)
    begin
        return -4;------------------- not sure of this error code  ------------------------------------------------------
    end
    --if my active address already has an Active cart, reject it
    if exists (select * from Cart c inner join Address a on c.address_id = a.address_id
               where a.customer_id = @customer_id and a.is_active = 1 and c.status = 'Active')
    begin
        return -1;
    end
    --now create the cart for the active address
    insert into Cart(status,created_at,customer_id,address_id)
    select 'Active', getdate(), @customer_id, address_id
    from Address
    where customer_id = @customer_id and is_active = 1;
    return 0;
end







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

    -- reject if the cart does not exist or is not Active
    if not exists (select * from Cart where cart_id = @cart_id and status = 'Active')
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
            return -6; -- reject if resulting quantity exceeds 10 ---------------------------------------------- not sure about this one could be out of scope so it would be -3
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



    --if both the cart and the product exist, delete the product from the cart
    delete from CartItem
    where cart_id = @cart_id and product_id = @product_id;
    return 0;
end

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

Create Function Calculate_Voucher_Discount
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
        -- CHANGED: percentage gives subtotal * amount / 100, otherwise the fixed amount
        select @discount = case when v.is_percentage = 1
                                then @order_subtotal * v.amount / 100
                                else v.amount end
        from Voucher v
        where v.voucher_id = @voucher_id -- case that the voucher is missing
        and v.status = 'Unused' -- CHANGED: case that the voucher is not Unused
        and v.expiry_date >= cast(getdate() as date); -- CHANGED: case that the voucher is expired
    end

    -- the discount never exceeds the subtotal
    if @discount > @order_subtotal
    begin
        set @discount = @order_subtotal;
    end

    return @discount;
end



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
        return -2; -- The record already exists, so it is -2 (duplicate)
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
create Function My_Order_History
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
    inner join Payment p on o.order_id = p.order_id
    where c.customer_id = @customer_id 

    return;
end




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
        if not exists (select * from Card where card_id = @card_id and customer_id = @customer_id)
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

    -- ADDED: reject if there is no available rider with an Active account in the zone -------------------------------------------------------------------------------------------------------------- check this part again ------------------------------------------------------------------------------------------------------------------------------
    if not exists (
        select * from Rider r inner join Users u on u.user_id = r.rider_id
        where r.zone_id = @zone_id and r.is_available = 1 and u.account_status = 'Active')
    begin
        return -8;
    end


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
    
    insert into Payment(amount,currency,method,transaction_date,refunded_amount,order_id,card_id) ---------------------------------- shoudl teh currency be EGP ?------------------------------------
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

    return 0; 
end









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
Output: Nothing

*/


Create Procedure Cancel_Order
    @order_id int
As
Begin
    
    --reject if the order does not exist
    if not exists (select * from Orders where order_id = @order_id)
    begin
        return -1; -- Order does not exist ------------------------------------------------------------------------------------------------------------------------------------------------ not sure of this it may be -9
    end

    -- reject if the order is Cancelled or any SubOrder is Picked Up or Delivered
    if exists (
        select * from Orders o
        inner join SubOrder so on o.order_id = so.order_id
        where o.order_id = @order_id 
        and (o.status = 'Cancelled' or so.status in ('Picked Up', 'Delivered')))
    begin
        return -4; 
    end

    -- cancel all remaining SubOrders order and their Deliveries
    update SubOrder
    set status = 'Cancelled'
    where order_id = @order_id and status in ('Placed', 'Assigned');

    -- cancel the order
    update Orders
    set status = 'Cancelled'
    where order_id = @order_id;

    -- get the remaining refund amount and payment method
    declare @refund_amount decimal(10,2);
    declare @payment_method varchar(20);
    declare @customer_id int;

    select 
        @refund_amount = p.amount - p.refunded_amount,
        @payment_method = p.method
    from Payment p
    where p.order_id = @order_id;

    -- reject if no payment record exists - -----------------------------------------------------------------------------------------not sure of this one 
    if @refund_amount is null
    begin
        return -7; -- Payment cannot be made
    end

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
