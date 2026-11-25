"""Admin component (requirements 3.2 and 3.3)."""
from datetime import date, timedelta
from flask import Blueprint, render_template, request, redirect, url_for, session, flash
import db
from common import Val, notify, me, role_required, super_required, date_range

bp = Blueprint("admin", __name__, url_prefix="/admin")


def is_super():
    return session.get("admin_role") == "Super Admin"


def can_manage(zone_name):
    return is_super() or zone_name == session.get("admin_zone")


def zones():
    return db.query("SELECT * FROM h_ZoneList ORDER BY zone_name")


# ----------------------------------------------------------- home + dashboard
@bp.route("/")
@role_required("admin")
def home():
    profile = db.one("SELECT * FROM dbo.h_AdminProfile(?)", (me(),))
    health = db.one("SELECT * FROM dbo.Platform_Health_Snapshot()")
    mismatches = db.query("SELECT * FROM dbo.Reconcile_Order_Totals()")
    pending = db.scalar("SELECT COUNT(*) FROM PendingBusinessApprovals")
    return render_template("admin/home.html", profile=profile, health=health,
                           mismatches=mismatches, pending=pending)


# --------------------------------------------------------- 3.2.b approvals
@bp.route("/pending", methods=["GET", "POST"])
@role_required("admin")
def pending():
    if request.method == "POST":
        v = Val()
        bid = v.integer("business_id", "Business")
        action = v.choice("action", "Action", ("approve", "reject"))
        if v.ok():
            name = request.form.get("business_name", "The business")
            if action == "approve":
                notify(db.call("Approve_Business", bid, me()), f"{name} was approved and is now Active.",
                       {-3: "This business is outside your zone, so you cannot approve it.",
                        -4: "This business is no longer Pending. Refresh the list."})
            else:
                notify(db.call("Reject_Business", bid, me()), f"{name} was rejected. The partner can register it again.",
                       {-3: "This business is outside your zone, so you cannot reject it.",
                        -4: "This business is no longer Pending. Refresh the list."})
        return redirect(url_for("admin.pending"))
    rows = db.query("SELECT * FROM PendingBusinessApprovals ORDER BY business_name")
    for r in rows:
        r["manageable"] = can_manage(r["zone_name"])
    return render_template("admin/pending.html", rows=rows)


# ----------------------------------------------- 3.2.c suspend / reinstate
@bp.route("/businesses", methods=["GET", "POST"])
@role_required("admin")
def businesses():
    if request.method == "POST":
        v = Val()
        bid = v.integer("business_id", "Business")
        action = v.choice("action", "Action", ("suspend", "reinstate"))
        reason = v.text("reason", "Suspension reason", required=(action == "suspend"), maxlen=255)
        if v.ok():
            name = request.form.get("business_name", "The business")
            if action == "suspend":
                notify(db.call("Suspend_Business", bid, me(), reason),
                       f"{name} is suspended. Its products are off, and orders not yet picked up were cancelled and refunded.",
                       {-3: "This business is outside your zone, so you cannot suspend it.",
                        -4: "Only an Active business can be suspended. Refresh the page and check its status.",
                        -1: "Write a reason for the suspension. The business owner will see it."})
            else:
                notify(db.call("Reinstate_Business", bid, me()), f"{name} is Active again. Its owner can turn its products back on.",
                       {-3: "Only a Super Admin can reinstate a business.",
                        -4: "Only a Suspended business can be reinstated. Refresh the page."})
        return redirect(url_for("admin.businesses", status=request.args.get("status", ""), type=request.args.get("type", "")))
    status = request.args.get("status") or None
    btype = request.args.get("type") or None
    rows = db.query("""SELECT p.*, s.suspension_reason FROM allBusinessProfiles p
                       LEFT JOIN h_SuspendedBusinesses s ON s.business_id = p.business_id
                       WHERE (? IS NULL OR p.status = ?) AND (? IS NULL OR p.business_type = ?)
                       ORDER BY p.business_name""", (status, status, btype, btype))
    for r in rows:
        r["manageable"] = can_manage(r["zone_name"])
    return render_template("admin/businesses.html", rows=rows, status=status or "", btype=btype or "")


# ------------------------------------------------- 3.2.d admins (Super only)
@bp.route("/admins", methods=["GET", "POST"])
@role_required("admin")
@super_required
def admins():
    if request.method == "POST":
        v = Val()
        form = request.form.get("form")
        if form == "create":
            role = v.choice("role", "Role", ("Super Admin", "Zone Admin"))
            zone = v.integer("zone_id", "Zone", required=(role == "Zone Admin"))
            args = (v.text("first_name", "First name", maxlen=30), v.text("middle_name", "Middle name", False, 30),
                    v.text("last_name", "Last name", maxlen=30), v.text("username", "Username", maxlen=30),
                    v.password("password"), v.email("email"), v.digits("phone", "Phone", 11, False),
                    v.date("dob", "Date of birth", False))
            if v.ok():
                zone = zone if role == "Zone Admin" else None
                notify(db.call("Create_Admin", *args, role, zone, me()),
                       f"The {role} account {args[3]} was created.",
                       {-2: "This username or email is already used. Choose another one.",
                        -1: "Check the details: a Zone Admin needs a zone, a Super Admin must not have one, and the date of birth cannot be in the future."})
        else:
            admin_id = v.integer("admin_id", "Admin")
            zone = v.integer("zone_id", "Zone")
            if v.ok():
                notify(db.call("Assign_Admin_Zone", admin_id, zone, me()), "The Zone Admin now manages the chosen zone.",
                       {-1: "Only a Zone Admin can be assigned to a zone. Pick a Zone Admin from the list."})
        return redirect(url_for("admin.admins"))
    return render_template("admin/admins.html", zones=zones(),
                           admins=db.query("SELECT * FROM h_AdminList ORDER BY admin_name"))


# ------------------------------------------------------- 3.2.e vouchers
@bp.route("/vouchers", methods=["GET", "POST"])
@role_required("admin")
def vouchers():
    if request.method == "POST":
        v = Val()
        cid = v.integer("customer_id", "Customer")
        code = v.text("promo_code", "Promo code", maxlen=30)
        kind = v.choice("kind", "Discount type", ("percent", "fixed"))
        amount = v.number("amount", "Amount", minv=0.01)
        if kind == "percent" and amount is not None and not (1 <= amount <= 100):
            v.errors.append("A percentage discount must be between 1 and 100.")
        expiry = v.date("expiry_date", "Expiry date")
        if expiry and expiry < date.today():
            v.errors.append("The expiry date cannot be in the past.")
        if v.ok():
            cust = db.one("SELECT customer_name FROM h_CustomerList WHERE customer_id = ?", (cid,))
            notify(db.call("Issue_Voucher", cid, code, 1 if kind == "percent" else 0, amount, expiry, me()),
                   f"The voucher {code} was issued to {cust['customer_name'] if cust else 'the customer'}.",
                   {-2: "This promo code already exists. Choose another code.",
                    -3: "Vouchers cannot be issued to a blacklisted customer.",
                    -1: "Check the voucher: the amount must be positive (1-100 for a percentage) and the expiry date cannot be in the past."})
        return redirect(url_for("admin.vouchers"))
    customers = db.query("SELECT * FROM h_CustomerList WHERE account_status = 'Active' ORDER BY customer_name")
    active = db.query("""SELECT v.*, c.customer_name FROM ActiveVouchers v
                         JOIN h_CustomerList c ON c.customer_id = v.customer_id ORDER BY v.expiry_date""")
    return render_template("admin/vouchers.html", customers=customers, active=active)


# ------------------------------------------------------- 3.2.f blacklist
@bp.route("/blacklist", methods=["GET", "POST"])
@role_required("admin")
def blacklist():
    if request.method == "POST":
        v = Val()
        cid = v.integer("customer_id", "Customer")
        action = v.choice("action", "Action", ("add", "lift"))
        reason = v.text("reason", "Reason", required=(action == "add"), maxlen=255)
        if v.ok():
            name = request.form.get("customer_name") or "The customer"
            if action == "add":
                notify(db.call("Blacklist_Customer", cid, me(), reason),
                       f"{name} is blacklisted. Their unstarted orders were cancelled and refunded, and their unused vouchers removed.",
                       {-3: "This customer is outside your zone, so you cannot blacklist them.",
                        -4: "This customer is already blacklisted."})
            else:
                notify(db.call("Lift_Customer_Blacklist", cid, me()), f"The blacklist on {name} was lifted.",
                       {-3: "Only the admin who blacklisted a customer can lift it.",
                        -4: "This customer is not blacklisted any more. Refresh the page."})
        return redirect(url_for("admin.blacklist"))
    customers = db.query("SELECT * FROM h_CustomerList WHERE account_status = 'Active' ORDER BY customer_name")
    banned = db.query("SELECT * FROM h_BlacklistedCustomers ORDER BY customer_name")
    for b in banned:
        b["mine"] = (b["admin_id"] == me())
    return render_template("admin/blacklist.html", customers=customers, banned=banned)


# ------------------------------------------------------------ 3.3.b zones
@bp.route("/zones", methods=["GET", "POST"])
@role_required("admin")
def zones_page():
    if request.method == "POST":
        if not is_super():
            flash("Only a Super Admin can change zones.", "warn")
            return redirect(url_for("admin.zones_page"))
        v = Val()
        if request.form.get("form") == "create":
            name = v.text("zone_name", "Zone name", maxlen=50)
            fee = v.number("delivery_fee", "Delivery fee", minv=0)
            if v.ok():
                notify(db.call("Create_Zone", name, fee, me()), f"The zone {name} was created.",
                       {-2: "A zone with this name already exists. Choose another name."})
        else:
            zid = v.integer("zone_id", "Zone")
            fee = v.number("delivery_fee", "New fee", minv=0)
            if v.ok():
                notify(db.call("Update_Zone_Fee", zid, fee, me()), "The delivery fee was updated. New orders use it.")
        return redirect(url_for("admin.zones_page"))
    return render_template("admin/zones.html", zones=zones())


# ------------------------------------------------- 3.3.c zone comparison
@bp.route("/compare")
@role_required("admin")
def compare():
    f, t = date_range()
    rows = db.query("""SELECT z.zone_id, z.zone_name, z.delivery_fee, bz.business_count,
                              zp.delivery_count, zp.avg_tracking_time,
                              r.number_of_orders, r.avg_order_total, r.platform_commission
                       FROM h_ZoneList z
                       JOIN BusinessesPerZone bz ON bz.zone_id = z.zone_id
                       JOIN ZoneDeliveryPerformance zp ON zp.zone_id = z.zone_id
                       CROSS APPLY dbo.ZoneOrderReport(z.zone_id, ?, ?) r
                       ORDER BY z.zone_name""", (f, t))
    best = worst = slowest = None
    if rows:
        best = max(rows, key=lambda r: (r["platform_commission"] or 0, r["number_of_orders"] or 0))
        worst = min(rows, key=lambda r: (r["number_of_orders"] or 0, r["platform_commission"] or 0))
        timed = [r for r in rows if r["avg_tracking_time"] is not None]
        slowest = max(timed, key=lambda r: r["avg_tracking_time"]) if timed else None
        top = max([float(r["platform_commission"] or 0) for r in rows]) or 1
        for r in rows:
            r["bar"] = round(float(r["platform_commission"] or 0) / top * 100)
    return render_template("admin/compare.html", rows=rows, f=f, t=t, best=best, worst=worst, slowest=slowest)


# ------------------------------------------------------ 3.3.d daily revenue
@bp.route("/revenue")
@role_required("admin")
def revenue():
    v = Val(request.args)
    day = v.date("day", "Day", required=False)
    v.ok()
    if day is None:
        day = db.scalar("SELECT last_day FROM h_LastOrderDay") or date.today()
    rows = db.query("SELECT * FROM dbo.Daily_Revenue_Report(?) ORDER BY zone_name, business_type", (day,))
    tot = dict(subs=sum(r["number_of_suborders"] for r in rows),
               gross=sum(r["gross_sales"] for r in rows),
               fees=sum(r["delivery_fees"] for r in rows),
               commission=sum(r["platform_commission"] for r in rows))
    return render_template("admin/revenue.html", rows=rows, tot=tot, day=day)


# ------------------------------------------------------------ 3.3.e riders
@bp.route("/riders")
@role_required("admin")
def riders():
    f, t = date_range(30)
    top = db.query("SELECT * FROM dbo.TopRiders(?, ?) ORDER BY rider_rank", (f, t))
    perf = db.query("SELECT * FROM RiderPerformanceSummary ORDER BY completed_deliveries, rider_name")
    if perf:
        avg = sum(p["completed_deliveries"] for p in perf) / len(perf)
        for p in perf:
            p["behind"] = p["completed_deliveries"] < avg or (p["avg_rating"] is not None and p["avg_rating"] < 3)
    return render_template("admin/riders.html", top=top, perf=perf, f=f, t=t)


# ------------------------------------------------------------ 3.3.f market
@bp.route("/market")
@role_required("admin")
def market():
    products = db.query("SELECT * FROM TopSellingProducts")
    rated = db.query("SELECT * FROM BusinessRatingsSummary WHERE ratings_count > 0")
    loved = sorted(rated, key=lambda r: (-r["avg_rating"], -r["ratings_count"]))[:5]
    avoided = sorted(rated, key=lambda r: (r["avg_rating"], -r["ratings_count"]))[:5]
    unrated = db.query("SELECT * FROM BusinessRatingsSummary WHERE ratings_count = 0 ORDER BY business_name")
    return render_template("admin/market.html", products=products, loved=loved, avoided=avoided, unrated=unrated)
