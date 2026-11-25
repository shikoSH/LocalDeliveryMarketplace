"""Rider component (requirements 3.4 e-g)."""
from flask import Blueprint, render_template, request, redirect, url_for, flash
import db
from common import Val, notify, me, role_required, date_range

bp = Blueprint("rider", __name__, url_prefix="/rider")


@bp.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        v = Val()
        args = (v.text("first_name", "First name", maxlen=30), v.text("middle_name", "Middle name", False, 30),
                v.text("last_name", "Last name", maxlen=30), v.text("username", "Username", maxlen=30),
                v.password("password"), v.email("email"), v.digits("phone", "Phone number", 11, False),
                v.date("dob", "Date of birth", False), v.text("vehicle_type", "Vehicle type", maxlen=30),
                v.text("plate_no", "Plate number", maxlen=15), v.text("license_no", "License number", maxlen=20),
                v.integer("zone_id", "Zone"))
        if v.ok() and notify(db.call("Rider_Register", *args), "Your rider account was created. Log in to start.",
                             {-2: "This username, email, plate number or license number is already registered. Check them and try again.",
                              -1: "Check the details: all fields except middle name, phone and date of birth are required."}):
            return redirect(url_for("login", role="rider"))
    return render_template("register_account.html", kind="rider",
                           zones=db.query("SELECT * FROM h_ZoneList ORDER BY zone_name"))


@bp.route("/", methods=["GET", "POST"])
@role_required("rider")
def home():
    if request.method == "POST":
        on = 1 if request.form.get("available") == "1" else 0
        notify(db.call("Set_Rider_Availability", me(), on),
               "You are available. New deliveries in your zone can be assigned to you." if on
               else "You are unavailable. No new deliveries will be assigned to you.")
        return redirect(url_for("rider.home"))
    prof = db.one("SELECT * FROM dbo.h_RiderProfile(?)", (me(),))
    n = db.scalar("SELECT COUNT(*) FROM dbo.My_Active_Deliveries(?)", (me(),))
    return render_template("rider/home.html", p=prof, active=n)


@bp.route("/deliveries", methods=["GET", "POST"])
@role_required("rider")
def deliveries():
    if request.method == "POST":
        v = Val()
        did = v.integer("delivery_id", "Delivery")
        if v.ok():
            if not db.scalar("SELECT dbo.h_RiderOwnsDelivery(?, ?)", (me(), did)):
                flash("That delivery is not assigned to you.", "err")
            elif request.form.get("action") == "pickup":
                notify(db.call("Mark_Picked_Up", did), "Marked as picked up. Deliver it to the customer next.",
                       {-4: "This delivery is not waiting for pick-up any more. Refresh the page."})
            else:
                notify(db.call("Mark_Delivered", did), "Marked as delivered. Well done!",
                       {-4: "Mark the delivery as picked up first, then as delivered."})
        return redirect(url_for("rider.deliveries"))
    rows = db.query("SELECT * FROM dbo.My_Active_Deliveries(?) ORDER BY assigned_at", (me(),))
    return render_template("rider/deliveries.html", rows=rows)


@bp.route("/performance")
@role_required("rider")
def performance():
    f, t = date_range(30)
    earn = db.one("SELECT * FROM dbo.My_Earnings(?, ?, ?)", (me(), f, t))
    rating = db.one("SELECT * FROM dbo.My_Rating_Summary(?)", (me(),))
    hist = db.query("SELECT * FROM dbo.My_Delivery_History(?, ?, ?) ORDER BY assigned_at DESC", (me(), f, t))
    times = [h["tracking_time"] for h in hist if h["status"] == "Delivered" and h["tracking_time"] is not None]
    avg_time = sum(times) / len(times) if times else None
    return render_template("rider/performance.html", earn=earn, rating=rating, hist=hist, f=f, t=t, avg_time=avg_time)
