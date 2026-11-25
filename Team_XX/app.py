"""Local Business Delivery and Fulfillment Management System - Milestone 3.
Run:  pip install -r requirements.txt   then   python app.py   -> http://localhost:5000"""
import logging
from datetime import date, time, datetime
from decimal import Decimal

import pyodbc
from flask import Flask, render_template, request, redirect, url_for, session, flash

import config
import db
from common import Val, notify

app = Flask(__name__)
app.secret_key = config.SECRET_KEY

# ------------------------------------------------------------ jinja filters
@app.template_filter("money")
def money(v):
    return "EGP {:,.2f}".format(Decimal(v or 0))

@app.template_filter("dt")
def fmt_dt(v):
    return v.strftime("%d %b %Y, %H:%M") if isinstance(v, datetime) else ("-" if v in (None, "") else str(v))

@app.template_filter("d")
def fmt_d(v):
    return v.strftime("%d %b %Y") if isinstance(v, (date, datetime)) else ("-" if v in (None, "") else str(v))

@app.template_filter("hm")
def fmt_hm(v):
    return v.strftime("%H:%M") if isinstance(v, (time, datetime)) else ("-" if v in (None, "") else str(v)[:5])

@app.template_filter("num")
def fmt_num(v, nd=2):
    return "-" if v is None else ("{:,.%df}" % nd).format(float(v))

@app.template_filter("iso")
def fmt_iso(v):
    return v.strftime("%Y-%m-%d") if isinstance(v, (date, datetime)) else ""

@app.template_filter("isotime")
def fmt_isotime(v):
    return v.strftime("%H:%M") if isinstance(v, (time, datetime)) else ""

@app.template_filter("stars")
def stars(v):
    if v is None:
        return "No ratings yet"
    return "{:.1f} / 5".format(float(v))


@app.context_processor
def inject():
    return dict(role=session.get("role"), user_name=session.get("name"),
                admin_role=session.get("admin_role"), today=date.today().isoformat())


# ------------------------------------------------------------------- pages
@app.route("/")
def index():
    return render_template("index.html")


ROLE_LOGIN = {
    "admin":    ("AdminLoginValidation",    "admin.home"),
    "partner":  ("PartnerLoginValidation",  "partner.home"),
    "rider":    ("RiderLoginValidation",    "rider.home"),
    "customer": ("CustomerLoginValidation", "customer.home"),
}


@app.route("/login/<role>", methods=["GET", "POST"])
def login(role):
    if role not in ROLE_LOGIN:
        return redirect(url_for("index"))
    if request.method == "POST":
        v = Val()
        username = v.text("username", "Username", maxlen=30)
        password = v.password("password")
        if v.ok():
            func, home = ROLE_LOGIN[role]
            if db.scalar(f"SELECT dbo.{func}(?, ?)", (username, password)):
                uid = db.scalar("SELECT dbo.h_GetUserId(?)", (username,))
                session.clear()
                session.update(uid=uid, role=role)
                if role == "admin":
                    p = db.one("SELECT * FROM dbo.h_AdminProfile(?)", (uid,))
                    session.update(name=p["admin_name"], admin_role=p["role"], admin_zone=p["zone_name"])
                elif role in ("customer", "rider"):
                    prof = "h_CustomerProfile" if role == "customer" else "h_RiderProfile"
                    p = db.one(f"SELECT * FROM dbo.{prof}(?)", (uid,))
                    session["name"] = p.get("customer_name") or p.get("rider_name")
                else:
                    session["name"] = username
                return redirect(url_for(home))
            flash("Wrong username or password.", "err")
    return render_template("login.html", target=role)


@app.route("/logout")
def logout():
    session.clear()
    flash("You are logged out.", "ok")
    return redirect(url_for("index"))


# ------------------------------------------------------------- blueprints
from admin import bp as admin_bp
from partner import bp as partner_bp
from rider import bp as rider_bp
from customer import bp as customer_bp
for b in (admin_bp, partner_bp, rider_bp, customer_bp):
    app.register_blueprint(b)


@app.errorhandler(pyodbc.Error)
def db_error(e):
    logging.exception("database error")          # details go to the console only
    return render_template("error.html",
        title="The database could not complete this action",
        text="Check that SQL Server is running and the connection settings in config.py are right, "
             "then go back and try again."), 500


@app.errorhandler(404)
def not_found(e):
    return render_template("error.html", title="Page not found",
        text="Use the menu to find what you need."), 404


if __name__ == "__main__":
    app.run(debug=True)
