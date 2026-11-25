# Talabat Sanaa El-Awady · Team 143
### Milestone 3 - Local Business Delivery and Fulfillment Management System

Sanaa El-Awady is an Egyptian mother from our imagination who always knew the best koshary shop
and the pharmacy that stays open late. Her "talabat" (orders) app brings the restaurants and
pharmacies of your zone to your door. The logo is a copper *qidra* (foul pot) whose steam rises
into a heart, on a brass tray inside a gold eight-point star (*khatam*).

Flask website on top of the Milestone 2 SQL Server database. Every action calls the matching
Milestone 2 procedure, function or view; no business logic is repeated in Python.

## Run it
1. In SQL Server run, in this order: the given database script, `seed_data.sql`, then `Team_143.sql` (our helpers).
   If your database is not called `LocalDeliveryMarketplace_Team_00`, edit the `USE` line of `Team_143.sql` and `DB_NAME` in `config.py`.
2. Install the "ODBC Driver 17 for SQL Server" (or 18) and Python 3.10+.
3. `pip install -r requirements.txt`
4. Edit `config.py` (server name; set `DB_USER`/`DB_PASS` for SQL login, leave empty for Windows login).
5. `python app.py` and open http://localhost:5000. Super Admin: `mona.hassan` / `Pass@001`.

## Look and feel
- Traditional Egyptian style: lapis blue, brass gold and copper, a khayamiya-style tent-fabric band,
  and a star-lattice pattern. Each user type has its own colour: Admin lapis, Partner copper,
  Rider Nile green, Customer pomegranate.
- Fonts (Reem Kufi, Cairo) and icons are bundled in `static/`, so the site needs no internet connection.
- Works on phones (the side menu becomes a top bar) and follows the system light/dark setting.
- `static/logo.svg` / `logo.png` is the full logo, `static/logo-mark.svg` the emblem (also the favicon).

## Files
- `app.py` start page, login/logout, filters, error pages.   `common.py` guards, validation, return-code messages.
- `admin.py`, `partner.py`, `rider.py`, `customer.py` one module per component.   `db.py` the only place that talks to SQL Server.
- `Team_143.sql` our helpers: categories, favorites list, ownership checks, cart business state, last order day.

## Notes
- Return codes (Table 3.1) are turned into messages in `common.py` and in each route; raw SQL errors are never shown.
- Users never type an ID: the signed-in id is kept in the session, and ids sent by forms are checked with the ownership helpers.
- Estimated arrival (3.6.c): business expected delivery time + the zone's real average delivery time (`ZoneDeliveryPerformance`);
  once picked up, pick-up time + that average.
- Zone Admins see all businesses but only get action buttons for their own zone; Super-Admin-only pages are hidden and blocked.
