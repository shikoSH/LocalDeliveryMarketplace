"""Thin database layer. The website never contains business logic: it only
calls the Milestone 2 procedures / functions / views and reads their results."""
import pyodbc
from config import connection_string


def _connect():
    return pyodbc.connect(connection_string(), autocommit=False)


def _rows(cur):
    cols = [c[0] for c in cur.description]
    return [dict(zip(cols, r)) for r in cur.fetchall()]


def query(sql, params=()):
    """Run a SELECT and return a list of dicts."""
    con = _connect()
    try:
        cur = con.cursor()
        cur.execute(sql, params)
        return _rows(cur)
    finally:
        con.close()


def one(sql, params=()):
    rows = query(sql, params)
    return rows[0] if rows else None


def scalar(sql, params=()):
    con = _connect()
    try:
        cur = con.cursor()
        cur.execute(sql, params)
        row = cur.fetchone()
        return row[0] if row else None
    finally:
        con.close()


def call(proc, *params):
    """Execute a stored procedure and return its integer return code."""
    marks = ", ".join("?" for _ in params)
    sql = f"SET NOCOUNT ON; DECLARE @rc INT; EXEC @rc = dbo.{proc} {marks}; SELECT @rc;"
    con = _connect()
    try:
        cur = con.cursor()
        cur.execute(sql, params)
        rc = None
        while True:
            try:
                row = cur.fetchone()
                if row is not None:
                    rc = row[0]
                    break
            except pyodbc.ProgrammingError:
                pass                      # statement produced no result set
            if not cur.nextset():
                break
        con.commit()
        return rc
    except Exception:
        con.rollback()
        raise
    finally:
        con.close()
