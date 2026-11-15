



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


    --if address belongs to a Placed or In Progress order
    if exists (
        select * 
        from orders o inner join cart c on o.cart_id = c.cart_id
        where c.customer_id = @customer_id and c.address_id = @address_id and o.status in ('Placed', 'In Progress'))
    begin
        return -4;
    end

    

    -- if address is used by any cart
    if exists (
        select * 
        from cart 
        where customer_id = @customer_id and address_id = @address_id and status = 'Active') ---- check the status = active part 
    begin
        return -1; -- Not sure of this part Need to be checked-----------------------------------------------
    end


    if @action = 'Update'
    begin
        update Address
        set description = @description, zone_id = @zone_id
        where customer_id = @customer_id and address_id = @address_id;
        return 0;
    end
    else if @action = 'Delete'
    begin
        delete from Address
        where customer_id = @customer_id and address_id = @address_id;
        return 0;
    end



END














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
    else  -- Delete
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















*/