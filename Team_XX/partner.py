"""Partner component (requirements 3.4 a-d)."""
from flask import Blueprint, render_template, request, redirect, url_for, flash
import db
from common import Val, notify, me, role_required, date_range

bp = Blueprint("partner", __name__, url_prefix="/partner")


def my_business():
    return db.one("SELECT * FROM dbo.h_MyBusiness(?)", (me(),))


def account_args(v):
    return (v.text("first_name", "First name", maxlen=30), v.text("middle_name", "Middle name", False, 30),
            v.text("last_name", "Last name", maxlen=30), v.text("username", "Username", maxlen=30),
            v.password("password"), v.email("email"), v.digits("phone", "Phone number", 11, False),
            v.date("dob", "Date of birth", False))


@bp.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        v = Val()
        args = account_args(v)
        if v.ok() and notify(db.call("Partner_Register", *args),
                             "Your partner account was created. Log in to register your business.",
                             {-2: "This username or email is already used. Choose another one.",
                              -1: "Check the details: names, username, password and email are required, and the date of birth cannot be in the future."}):
            return redirect(url_for("login", role="partner"))
    return render_template("register_account.html", kind="partner")


@bp.route("/")
@role_required("partner")
def home():
    b = my_business()
    phones = db.query("SELECT * FROM dbo.h_BusinessPhones(?)", (b["business_id"],)) if b else []
    return render_template("partner/home.html", b=b, phones=phones)


# ------------------------------------------------ 3.4.b business + phones
@bp.route("/business", methods=["GET", "POST"])
@role_required("partner")
def business():
    b = my_business()
    if request.method == "POST":
        v = Val()
        form = request.form.get("form")
        if form == "register":
            if b and b["status"] != "Rejected":
                flash("You already have a business. You can only register again if it was rejected.", "err")
                return redirect(url_for("partner.business"))
            btype = v.choice("business_type", "Business type", ("Restaurant", "Pharmacy"))
            args = (v.text("name", "Business name", maxlen=100), v.text("description", "Description", False, 255),
                    v.text("link_website", "Website", False, 255), v.integer("zone_id", "Zone"),
                    v.time("opening_hour", "Opening hour"), v.time("closing_hour", "Closing hour"),
                    v.integer("expected_delivery_time", "Expected delivery time (minutes)", minv=1),
                    v.digits("phone", "Business phone", 11, False), btype,
                    v.text("cuisine_type", "Cuisine type", btype == "Restaurant", 50),
                    v.text("food_category", "Food category", btype == "Restaurant", 50),
                    v.text("pharmacy_type", "Pharmacy type", btype == "Pharmacy", 50))
            if v.ok():
                notify(db.call("Register_Business", me(), *args),
                       "Your business was sent for approval. Its status is Pending until an admin approves it.",
                       {-2: "You already have a business that is not Rejected, so it cannot be registered again.",
                        -1: "Check the form: name, zone, hours, delivery time and the type details are required, and the phone must be 11 digits."})
        elif b:
            opening = v.time("opening_hour", "Opening hour", False)
            closing = v.time("closing_hour", "Closing hour", False)
            phone = v.digits("phone", "New phone number", 11, False)
            link = v.text("link_website", "Website", False, 255)
            if v.ok():
                if not (opening or closing or phone or link):
                    flash("Fill at least one field to update: hours, website or a new phone number.", "warn")
                else:
                    notify(db.call("Update_Business_Info", b["business_id"], opening, closing, phone, link),
                           "Your business information was updated.",
                           {-2: "This phone number is already saved for your business.",
                            -1: "The phone number must be exactly 11 digits."})
        return redirect(url_for("partner.business"))
    phones = db.query("SELECT * FROM dbo.h_BusinessPhones(?)", (b["business_id"],)) if b else []
    zones = db.query("SELECT * FROM h_ZoneList ORDER BY zone_name")
    return render_template("partner/business.html", b=b, phones=phones, zones=zones)


# ------------------------------------------------------------ 3.4.c products
def my_products():
    return db.query("SELECT * FROM dbo.h_MyProducts(?) ORDER BY product_name", (me(),))


@bp.route("/products", methods=["GET", "POST"])
@role_required("partner")
def products():
    b = my_business()
    if not b:
        flash("Register your business first. Then you can add products.", "warn")
        return redirect(url_for("partner.business"))
    if request.method == "POST":
        v = Val()
        form = request.form.get("form")
        if form == "save":
            pid = v.integer("product_id", "Product", required=False)
            if pid and not db.scalar("SELECT dbo.h_PartnerOwnsProduct(?, ?)", (me(), pid)):
                flash("That product does not belong to your business.", "err")
                return redirect(url_for("partner.products"))
            args = (v.text("name", "Product name", maxlen=100), v.text("description", "Description", False, 255),
                    v.text("category", "Category", maxlen=50), v.number("price", "Price", minv=0.01))
            if v.ok():
                avail = 1 if request.form.get("is_available") else 0
                notify(db.call("Upsert_Product", b["business_id"], pid, args[0], args[1], args[2], args[3], avail),
                       f"The product {args[0]} was saved.",
                       {-4: "Your business is suspended, so products cannot be changed. Contact support.",
                        -1: "Check the product: name, category and a price above 0 are required, and the current discount cannot be more than half of the new price."})
        else:
            pid = v.integer("product_id", "Product")
            if pid and not db.scalar("SELECT dbo.h_PartnerOwnsProduct(?, ?)", (me(), pid)):
                flash("That product does not belong to your business.", "err")
                return redirect(url_for("partner.products"))
            if form == "toggle":
                on = 1 if request.form.get("to") == "1" else 0
                if v.ok():
                    notify(db.call("Toggle_Product_Status", pid, on),
                           "The product is now available to customers." if on else "The product is hidden from customers.",
                           {-4: "Your business is suspended, so products cannot be turned on."})
            elif form == "promo":
                amount = v.number("discount_amount", "Discount amount", minv=0)
                if v.ok():
                    notify(db.call("Set_Product_Promotion", pid, amount),
                           "The discount was removed." if amount == 0 else "The discount was set.",
                           {-1: "The discount must be between 0 and 50% of the price. Enter a smaller amount."})
        return redirect(url_for("partner.products"))
    edit = None
    eid = request.args.get("edit", type=int)
    rows = my_products()
    if eid:
        edit = next((p for p in rows if p["product_id"] == eid), None)
    return render_template("partner/products.html", b=b, rows=rows, edit=edit)


# -------------------------------------------------------- 3.4.d performance
@bp.route("/performance")
@role_required("partner")
def performance():
    b = my_business()
    if not b:
        flash("Register your business first.", "warn")
        return redirect(url_for("partner.business"))
    f, t = date_range()
    sales = db.query("SELECT * FROM dbo.BusinessSalesReport(?, ?, ?) ORDER BY revenue_per_product DESC",
                     (b["business_id"], f, t))
    fb = db.one("SELECT * FROM dbo.BusinessFeedbackOverview(?)", (b["business_id"],))
    return render_template("partner/performance.html", b=b, sales=sales, fb=fb, f=f, t=t,
                           total=sum(s["revenue_per_product"] for s in sales))
