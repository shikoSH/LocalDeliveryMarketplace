"""Customer component (requirements 3.5 and 3.6)."""
from datetime import datetime, timedelta
from decimal import Decimal
from flask import Blueprint, render_template, request, redirect, url_for, flash
import db
from common import Val, notify, me, role_required

bp = Blueprint("customer", __name__, url_prefix="/customer")


def profile():
    return db.one("SELECT * FROM dbo.h_CustomerProfile(?)", (me(),))


def my_cart_id():
    return db.scalar("SELECT dbo.h_MyActiveCart(?)", (me(),))


def back(default):
    """Only ever redirect inside the customer area."""
    nxt = request.form.get("next") or ""
    return nxt if nxt.startswith("/customer") else url_for(default)


# ---------------------------------------------------------- 3.5.a account
@bp.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        v = Val()
        args = (v.text("first_name", "First name", maxlen=30), v.text("middle_name", "Middle name", False, 30),
                v.text("last_name", "Last name", maxlen=30), v.text("username", "Username", maxlen=30),
                v.password("password"), v.email("email"), v.digits("phone", "Phone number", 11, False),
                v.date("dob", "Date of birth", False))
        if v.ok() and notify(db.call("Customer_Register", *args), "Your account was created. Log in to start ordering.",
                             {-2: "This username or email is already used. Choose another one.",
                              -1: "Check the details: names, username, password and email are required, and the date of birth cannot be in the future."}):
            return redirect(url_for("login", role="customer"))
    return render_template("register_account.html", kind="customer")


@bp.route("/")
@role_required("customer")
def home():
    p = profile()
    cid = my_cart_id()
    n = db.scalar("SELECT COUNT(*) FROM dbo.h_CartItems(?)", (cid,)) if cid else 0
    cats = [c["category"] for c in db.query("SELECT category FROM h_ProductCategories ORDER BY category")]
    return render_template("customer/home.html", p=p, cart_items=n, cats=cats,
                           orders=db.query("SELECT TOP 3 * FROM dbo.My_Order_History(?) ORDER BY order_date DESC", (me(),)))


# ---------------------------------------------------------- 3.5.b addresses
@bp.route("/addresses", methods=["GET", "POST"])
@role_required("customer")
def addresses():
    if request.method == "POST":
        v = Val()
        form = request.form.get("form")
        if form == "add":
            desc = v.text("description", "Address", maxlen=150)
            zone = v.integer("zone_id", "Zone")
            if v.ok():
                notify(db.call("Add_Customer_Address", me(), desc, zone),
                       "The address was added and is now your active address.",
                       {-1: "Write the address and choose its zone."})
        else:
            aid = v.integer("address_id", "Address")
            if form == "update":
                desc = v.text("description", "Address", maxlen=150)
                zone = v.integer("zone_id", "Zone")
                if v.ok():
                    notify(db.call("Update_Delete_Customer_Address", me(), aid, desc, zone, "Update"),
                           "The address was updated.",
                           {-4: "This address has an order in progress, so it cannot be changed yet. Wait until the order is delivered.",
                            -3: "That address is not yours."})
            elif form == "delete":
                if v.ok():
                    notify(db.call("Update_Delete_Customer_Address", me(), aid, None, None, "Delete"),
                           "The address was deleted.",
                           {-4: "This address is used by a cart or an order, so it cannot be deleted. You can edit it instead.",
                            -3: "That address is not yours."})
            elif form == "activate":
                if v.ok():
                    notify(db.call("Change_Active_Address", me(), aid), "This is now your active address.",
                           {-3: "That address is not yours."})
        return redirect(url_for("customer.addresses"))
    return render_template("customer/addresses.html",
                           rows=db.query("SELECT * FROM dbo.h_MyAddresses(?) ORDER BY address_id", (me(),)),
                           zones=db.query("SELECT * FROM h_ZoneList ORDER BY zone_name"))


# ------------------------------------------------------------- 3.5.c cards
@bp.route("/cards", methods=["GET", "POST"])
@role_required("customer")
def cards():
    if request.method == "POST":
        v = Val()
        no = v.digits("card_no", "Card number", 16)
        holder = v.text("holder", "Card holder name", maxlen=100)
        exp = v.date("expiration_date", "Expiration date")
        if v.ok():
            notify(db.call("Add_Card", me(), no, holder, exp), f"The card ending in {no[-4:]} was saved.",
                   {-2: "This card is already saved.",
                    -1: "Check the card: 16 digits, a holder name and an expiration date that is not in the past."})
        return redirect(url_for("customer.cards"))
    return render_template("customer/cards.html", rows=db.query("SELECT * FROM dbo.h_MyCards(?)", (me(),)))


# ------------------------------------------------------------- 3.5.d cart
@bp.route("/cart", methods=["GET", "POST"])
@role_required("customer")
def cart():
    if request.method == "POST":
        v = Val()
        form = request.form.get("form")
        if form == "create":
            notify(db.call("Create_Cart", me()), "Your cart is ready. Browse businesses and add products.",
                   {-1: "Add an address first. A cart belongs to your active address.",
                    -2: "You already have an active cart for this address.",
                    -3: "Your account is blacklisted, so you cannot create a cart. Contact support."})
        elif form == "remove":
            pid = v.integer("product_id", "Product")
            cid = my_cart_id()
            if v.ok():
                if cid is None:
                    flash("You have no active cart.", "err")
                else:
                    notify(db.call("Remove_From_Cart", cid, pid), "The product was removed from your cart.",
                           {-1: "That product is not in your cart.",
                            -4: "This cart is not your active cart any more. Open your cart again."})
        return redirect(url_for("customer.cart"))
    cid = my_cart_id()
    items = db.query("SELECT * FROM dbo.h_CartItems(?) ORDER BY business_name, product_name", (cid,)) if cid else []
    return render_template("customer/cart.html", cid=cid, items=items, p=profile(),
                           total=sum(i["line_total"] for i in items))


@bp.route("/cart/add", methods=["POST"])
@role_required("customer")
def cart_add():
    v = Val()
    pid = v.integer("product_id", "Product")
    qty = v.integer("quantity", "Quantity", minv=1, maxv=10)
    notes = v.text("notes", "Note", False, 255)
    if v.ok():
        cid = my_cart_id()
        if cid is None:                                   # first product: open the cart for the active address
            rc = db.call("Create_Cart", me())
            if rc not in (0, -2):
                notify(rc, "", {-1: "Add an address first. A cart belongs to your active address.",
                                -3: "Your account is blacklisted, so you cannot order. Contact support."})
                return redirect(back("customer.addresses"))
            cid = my_cart_id()
        notify(db.call("Add_To_Cart", cid, pid, qty, notes), "The product was added to your cart.",
               {-1: "That product could not be found.",
                -4: "This product is not available right now, or your cart does not match your active address.",
                -5: "This business does not deliver to your active address. Change your active address or choose another business.",
                -6: "You can order at most 10 of one product, counting what is already in your cart. Lower the quantity."})
    return redirect(back("customer.cart"))



# ------------------------------------------------------------ 3.5.e checkout
def _checkout_state(cid, selected_voucher):
    p = profile()
    items = db.query("SELECT * FROM dbo.h_CartItems(?) ORDER BY business_name, product_name", (cid,))
    fee = db.scalar("SELECT delivery_fee FROM h_ZoneList WHERE zone_id = ?", (p["active_zone_id"],)) or Decimal(0)
    groups = {}
    for i in items:
        g = groups.setdefault(i["business_id"], dict(name=i["business_name"], lines=[], subtotal=Decimal(0)))
        g["lines"].append(i)
        g["subtotal"] += i["line_total"]
    subtotal = sum((g["subtotal"] for g in groups.values()), Decimal(0))
    fees = fee * len(groups)
    vouchers = db.query("SELECT * FROM dbo.h_MyVouchers(?)", (me(),))
    if selected_voucher not in [x["voucher_id"] for x in vouchers]:
        selected_voucher = None
    discount = db.scalar("SELECT dbo.Calculate_Voucher_Discount(?, ?)", (selected_voucher, subtotal)) if items else Decimal(0)
    discount = Decimal(discount or 0)
    state = db.query("SELECT * FROM dbo.h_CartBusinessState(?)", (cid,))
    problems = [f"{s['business_name']} is {s['status'].lower()}." for s in state if s["status"] != "Active"]
    problems += [f"{s['business_name']} is closed right now." for s in state if s["status"] == "Active" and not s["is_open_now"]]
    problems += [f"{i['product_name']} is no longer available." for i in items if not i["is_available"]]
    return dict(p=p, groups=list(groups.values()), fee=fee, fees=fees, subtotal=subtotal, discount=discount,
                total=subtotal + fees - discount, vouchers=vouchers, voucher_id=selected_voucher,
                cards=db.query("SELECT * FROM dbo.h_MyCards(?)", (me(),)), problems=problems, count=len(items))


@bp.route("/checkout", methods=["GET", "POST"])
@role_required("customer")
def checkout():
    cid = my_cart_id()
    if cid is None:
        flash("You have no active cart. Create one and add products first.", "warn")
        return redirect(url_for("customer.cart"))
    if request.method == "POST":
        v = Val()
        method = v.choice("payment_method", "Payment method", ("Cash", "Card", "Wallet"))
        vid = v.integer("voucher_id", "Voucher", required=False)
        card = v.integer("card_id", "Card", required=(method == "Card"))
        if v.ok():
            st = _checkout_state(cid, vid)
            if vid and st["voucher_id"] != vid:
                flash("That voucher cannot be used any more. Choose another voucher or none.", "err")
                return redirect(url_for("customer.checkout"))
            if method == "Card" and card not in [c["card_id"] for c in st["cards"]]:
                flash("Choose one of your saved cards.", "err")
                return redirect(url_for("customer.checkout", voucher_id=vid or ""))
            if notify(db.call("Checkout_Cart", cid, vid, method, card if method == "Card" else None),
                      "Your order was placed and a rider was assigned to each part of it. Follow it under My orders.",
                      {-1: "The voucher is not valid or has expired. Choose another voucher or none.",
                       -3: "Your account is blacklisted, or the voucher belongs to someone else. Contact support.",
                       -4: "Something in your cart changed: a product is off, a business is closed or suspended, or the voucher was already used. Remove those items or choose another voucher.",
                       -5: "A business in your cart does not deliver to your active address. Remove it or change your active address.",
                       -7: "The payment cannot be made. Your wallet balance is not enough, or the card is missing or expired. Choose Cash or another card.",
                       -8: "No rider is available in your zone right now. Try again in a few minutes.",
                       -9: "Your cart is empty. Add products before checking out."}):
                return redirect(url_for("customer.orders"))
        return redirect(url_for("customer.checkout", voucher_id=request.form.get("voucher_id") or ""))
    return render_template("customer/checkout.html", cid=cid,
                           **_checkout_state(cid, request.args.get("voucher_id", type=int)))


# ----------------------------------------------------------- 3.6.a browse
@bp.route("/browse")
@role_required("customer")
def browse():
    p = profile()
    q = (request.args.get("q") or "").strip()
    category = (request.args.get("category") or "").strip()
    rows, mode = [], None
    if q:
        mode = "search"
        rows = db.query("""SELECT s.business_id, d.business_name, d.zone_name, d.is_open_now, d.avg_rating,
                                  d.number_of_ratings, d.expected_delivery_time
                           FROM dbo.Search_Platform(?, ?) s
                           CROSS APPLY dbo.h_BusinessDetails(s.business_id) d
                           ORDER BY s.priority, s.business_id""", (me(), q))
    elif category:
        mode = "category"
        if p["active_address_id"] is None:
            flash("Add an address first. Businesses are shown for your active address.", "warn")
        else:
            rows = db.query("""SELECT n.business_id, n.business_name, n.zone_name, n.same_zone, n.zone_avg_delivery_time,
                                      d.is_open_now, d.avg_rating, d.number_of_ratings, d.expected_delivery_time
                               FROM dbo.Nearby_Businesses_By_Category(?, ?) n
                               CROSS APPLY dbo.h_BusinessDetails(n.business_id) d
                               ORDER BY n.same_zone DESC, n.zone_avg_delivery_time, n.business_id""",
                            (p["active_address_id"], category))
    cats = [c["category"] for c in db.query("SELECT category FROM h_ProductCategories ORDER BY category")]
    return render_template("customer/browse.html", p=p, q=q, category=category, cats=cats, rows=rows, mode=mode)


@bp.route("/business/<int:bid>")
@role_required("customer")
def business(bid):
    d = db.one("SELECT * FROM dbo.h_BusinessDetails(?)", (bid,))
    if not d or d["status"] != "Active":
        flash("This business is not available right now. Search for another one.", "warn")
        return redirect(url_for("customer.browse"))
    p = profile()
    rating = db.one("SELECT * FROM BusinessRatingsSummary WHERE business_id = ?", (bid,))
    products = db.query("SELECT * FROM dbo.h_BusinessProducts(?) ORDER BY category, product_name", (bid,))
    favs = db.query("SELECT * FROM dbo.h_MyFavoriteItems(?)", (me(),))
    return render_template("customer/business.html", d=d, p=p, rating=rating, products=products,
                           fav_business=any(f["item_type"] == "Business" and f["item_id"] == bid for f in favs),
                           fav_products={f["item_id"] for f in favs if f["item_type"] == "Product"},
                           can_order=(d["zone_name"] == p["active_zone"]))


# --------------------------------------------------------- 3.6.b favorites
@bp.route("/favorite", methods=["POST"])
@role_required("customer")
def favorite():
    v = Val()
    item = v.integer("item_id", "Item")
    kind = v.choice("item_type", "Item type", ("Business", "Product"))
    if v.ok():
        notify(db.call("Toggle_Favorite", me(), item, kind), "Your favorites were updated.",
               {-1: "That item could not be found."})
    return redirect(back("customer.favorites"))


@bp.route("/favorites")
@role_required("customer")
def favorites():
    return render_template("customer/favorites.html",
                           products=db.query("SELECT * FROM dbo.My_Favorites(?)", (me(),)),
                           businesses=db.query("SELECT * FROM dbo.h_MyFavoriteItems(?) WHERE item_type = 'Business'", (me(),)),
                           recs=db.query("SELECT * FROM dbo.Recommended_Products(?)", (me(),)))


# ------------------------------------------------------------- 3.6.c orders
def _eta(subs, order_date, transit):
    now = datetime.now()
    best = None
    for s in subs:
        s["eta"] = None
        if s["status"] in ("Delivered", "Cancelled"):
            continue
        if s["picked_up_at"]:
            s["eta"] = s["picked_up_at"] + timedelta(minutes=transit)
        else:
            s["eta"] = (s["assigned_at"] or order_date) + timedelta(minutes=(s["expected_delivery_time"] or 0) + transit)
        best = s["eta"] if best is None else max(best, s["eta"])
    return best


@bp.route("/orders")
@role_required("customer")
def orders():
    rows = db.query("SELECT * FROM dbo.My_Order_History(?) ORDER BY order_date DESC", (me(),))
    zone = {z["zone_name"]: z["avg_tracking_time"] for z in db.query("SELECT * FROM ZoneDeliveryPerformance")}
    addresses = db.query("SELECT * FROM dbo.h_MyAddresses(?) ORDER BY address_id", (me(),))
    for o in rows:
        o["subs"] = db.query("SELECT * FROM dbo.h_OrderSubOrders(?) ORDER BY suborder_id", (o["order_id"],))
        transit = float(zone.get(o["zone_name"]) or 15)       # real minutes from pick-up to delivery in this zone
        o["eta"] = _eta(o["subs"], o["order_date"], transit)
        o["can_cancel"] = o["status"] != "Cancelled" and not any(s["status"] in ("Picked Up", "Delivered") for s in o["subs"])
        paid = (o["total_amount"] or 0) - (o["refunded_amount"] or 0)
        o["refund"] = paid if (o["payment_method"] and o["payment_method"] != "Cash") else Decimal(0)
        o["now"] = datetime.now()
    return render_template("customer/orders.html", rows=rows, addresses=addresses)


@bp.route("/orders/action", methods=["POST"])
@role_required("customer")
def order_action():
    v = Val()
    form = request.form.get("form")
    if form in ("cancel", "reorder"):
        oid = v.integer("order_id", "Order")
        if v.ok():
            if not db.scalar("SELECT dbo.h_CustomerOwnsOrder(?, ?)", (me(), oid)):
                flash("That order is not yours.", "err")
            elif form == "cancel":
                o = next((x for x in db.query("SELECT * FROM dbo.My_Order_History(?)", (me(),)) if x["order_id"] == oid), None)
                refund = ((o["total_amount"] or 0) - (o["refunded_amount"] or 0)) if o and o["payment_method"] != "Cash" else 0
                text = (f"Order #{oid} was cancelled. {Decimal(refund):,.2f} EGP was refunded to your wallet."
                        if refund else f"Order #{oid} was cancelled. You chose cash, so nothing was charged and nothing is refunded.")
                notify(db.call("Cancel_Order", oid), text,
                       {-4: "This order cannot be cancelled because a part of it was already picked up or it is already cancelled."})
            else:
                aid = v.integer("address_id", "Address")
                if v.ok():
                    if aid not in [a["address_id"] for a in db.query("SELECT * FROM dbo.h_MyAddresses(?)", (me(),))]:
                        flash("Choose one of your own addresses.", "err")
                    elif notify(db.call("Reorder", oid, aid),
                                "The products of that order are in a new cart, and the chosen address is now your active address. Review it and check out.",
                                {-2: "You already have an active cart for that address. Check it out or empty it first.",
                                 -3: "Your account is blacklisted, so you cannot reorder. Contact support.",
                                 -5: "That address is in a different zone from the order. Choose an address in the same zone.",
                                 -9: "None of the products of that order can be ordered right now."}):
                        return redirect(url_for("customer.cart"))
    else:
        sid = v.integer("suborder_id", "Order part")
        if v.ok():
            if not db.scalar("SELECT dbo.h_CustomerOwnsSubOrder(?, ?)", (me(), sid)):
                flash("That order is not yours.", "err")
            elif form == "feedback":
                head = v.text("headline", "Headline", maxlen=100)
                desc = v.text("description", "Comment", False, 500)
                rating = v.integer("rating", "Rating", minv=1, maxv=5)
                if v.ok():
                    notify(db.call("Submit_Feedback", sid, head, desc, rating), "Thank you! Your feedback was saved.",
                           {-2: "You already left feedback for this part of the order.",
                            -4: "You can leave feedback only after this part of the order is delivered."})
            elif form == "rider":
                rating = v.integer("rider_rating", "Rider rating", minv=1, maxv=5)
                if v.ok():
                    notify(db.call("Rate_Rider", sid, rating), "Thank you! Your rider rating was saved.",
                           {-2: "You already rated the rider of this delivery.",
                            -4: "You can rate the rider only after this part of the order is delivered."})
    return redirect(url_for("customer.orders"))
