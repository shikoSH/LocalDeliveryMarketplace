"""Connection settings. Override with environment variables if needed."""
import os

DB_DRIVER = os.getenv("DB_DRIVER", "ODBC Driver 17 for SQL Server")   # or "ODBC Driver 18 for SQL Server"
DB_SERVER = os.getenv("DB_SERVER", "localhost")                       # e.g. localhost\\SQLEXPRESS
DB_NAME   = os.getenv("DB_NAME",   "LocalDeliveryMarketplace_Team_00")
DB_USER   = os.getenv("DB_USER",   "")   # leave empty to use Windows authentication
DB_PASS   = os.getenv("DB_PASS",   "")
SECRET_KEY = os.getenv("SECRET_KEY", "change-me-for-your-team")

def connection_string():
    base = f"DRIVER={{{DB_DRIVER}}};SERVER={DB_SERVER};DATABASE={DB_NAME};TrustServerCertificate=yes;"
    if DB_USER:
        return base + f"UID={DB_USER};PWD={DB_PASS};"
    return base + "Trusted_Connection=yes;"
