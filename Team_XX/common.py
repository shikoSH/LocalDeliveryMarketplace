"""Shared helpers: sessions, role guards, input validation, return-code messages."""
import re
from datetime import date, time, datetime
from decimal import Decimal, InvalidOperation
from functools import wraps
from flask import session, redirect, url_for, flash, request

# ---------------------------------------------------------------- messages
# Table 3.1: what each return code means for the person using the website.
DEFAULT_MESSAGES = {
    -1: "Some of the information is missing or not valid. Check every field and try again.",
    -2: "This already exists. Use a different value and try again.",
    -3: "You are not allowed to do this. Your account or the item is outside your permissions.",
    -4: "This cannot be done in its current status. Refresh the page, check the status, then try again.",
    -5: "The business and the delivery address are in different zones. Change your active address or choose another business.",
    -6: "You can order at most 10 of one product. Lower the quantity.",
    -7: "The payment cannot be made. Check your wallet balance or choose another payment method.",
    -8: "No rider is available in your zone right now. Try again in a few minutes.",
    -9: "There is nothing to process. Add products first and try again.",
}


def notify(rc, success, fail=None):
    """Flash the right message for a return code. `fail` overrides the defaults
    for one action so the text names the real problem and the fix.
    Returns True when the action succeeded."""
    if rc == 0:
        flash(success, "ok")
        return True
    msg = (fail or {}).get(rc) or DEFAULT_MESSAGES.get(rc) \
        or "Something unexpected happened. Please try again, or contact support if it continues."
    flash(msg, "err")
    return False


# ---------------------------------------------------------------- sessions
def me():
    return session.get("uid")


def role_required(role):
    def deco(fn):
        @wraps(fn)
        def wrapper(*a, **k):
            if session.get("role") != role:
                flash("Please log in as a %s to open that page." % role, "warn")
                return redirect(url_for("index"))
            return fn(*a, **k)
        return wrapper
    return deco


def super_required(fn):
    """Admin pages that only a Super Admin may use."""
    @wraps(fn)
    def wrapper(*a, **k):
        if session.get("admin_role") != "Super Admin":
            flash("Only a Super Admin can do this.", "warn")
            return redirect(url_for("admin.home"))
        return fn(*a, **k)
    return wrapper


# ------------------------------------------------------------- validation
class Val:
    """Checks form input before the database is called (required fields,
    numbers, dates, 11-digit phone, 16-digit card). Collects every problem."""

    def __init__(self, src=None):
        self.src = src if src is not None else request.form
        self.errors = []

    def _raw(self, name):
        v = (self.src.get(name) or "").strip()
        return v or None

    def _need(self, v, label, required):
        if v is None and required:
            self.errors.append(f"{label} is required.")
        return v

    def text(self, name, label, required=True, maxlen=None):
        v = self._need(self._raw(name), label, required)
        if v and maxlen and len(v) > maxlen:
            self.errors.append(f"{label} must be at most {maxlen} characters.")
        return v

    def password(self, name, label="Password"):
        v = self.src.get(name) or ""
        if not v:
            self.errors.append(f"{label} is required.")
        elif len(v) > 30:
            self.errors.append(f"{label} must be at most 30 characters.")
        return v or None

    def email(self, name, label="Email"):
        v = self.text(name, label, maxlen=100)
        if v and not re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", v):
            self.errors.append(f"{label} must look like name@example.com.")
        return v

    def digits(self, name, label, n, required=True):
        v = self._need(self._raw(name), label, required)
        if v and not (len(v) == n and v.isdigit()):
            self.errors.append(f"{label} must be exactly {n} digits.")
        return v

    def number(self, name, label, required=True, minv=None, maxv=None, integer=False):
        v = self._need(self._raw(name), label, required)
        if v is None:
            return None
        try:
            n = int(v) if integer else Decimal(v)
        except (ValueError, InvalidOperation):
            self.errors.append(f"{label} must be a number.")
            return None
        if minv is not None and n < minv:
            self.errors.append(f"{label} must be at least {minv}.")
        if maxv is not None and n > maxv:
            self.errors.append(f"{label} must be at most {maxv}.")
        return n

    def integer(self, name, label, required=True, minv=None, maxv=None):
        return self.number(name, label, required, minv, maxv, integer=True)

    def date(self, name, label, required=True):
        v = self._need(self._raw(name), label, required)
        if v is None:
            return None
        try:
            return datetime.strptime(v, "%Y-%m-%d").date()
        except ValueError:
            self.errors.append(f"{label} must be a valid date.")

    def time(self, name, label, required=True):
        v = self._need(self._raw(name), label, required)
        if v is None:
            return None
        for fmt in ("%H:%M", "%H:%M:%S"):
            try:
                return datetime.strptime(v, fmt).time()
            except ValueError:
                pass
        self.errors.append(f"{label} must be a valid time.")

    def choice(self, name, label, allowed, required=True):
        v = self._need(self._raw(name), label, required)
        if v is not None and v not in allowed:
            self.errors.append(f"Choose a valid option for {label}.")
            return None
        return v

    def ok(self):
        for e in self.errors:
            flash(e, "err")
        return not self.errors


def date_range(default_days=365):
    """Reads ?from=&to= (defaults to the last year); returns (from, to) or flashes."""
    from datetime import timedelta
    v = Val(request.args)
    today = date.today()
    f = v.date("from", "From date", required=False) or today - timedelta(days=default_days)
    t = v.date("to", "To date", required=False) or today
    v.ok()
    if f > t:
        flash("The From date must not be after the To date. Swap them and try again.", "err")
        f, t = t, f
    return f, t
