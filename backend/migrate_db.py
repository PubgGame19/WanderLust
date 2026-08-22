import sqlite3
import glob

def migrate():
    db_files = glob.glob("*.db")
    print(f"Found database files: {db_files}")

    for db_path in db_files:
        print(f"\n--- Migrating {db_path} ---")
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()

        # Check existing tables
        cur.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = [r[0] for r in cur.fetchall()]

        if "reviews" in tables:
            cur.execute("PRAGMA table_info(reviews);")
            cols = [c[1] for c in cur.fetchall()]
            if "trip_id" not in cols:
                print(f"Adding 'trip_id' to reviews in {db_path}...")
                cur.execute("ALTER TABLE reviews ADD COLUMN trip_id VARCHAR;")
                conn.commit()

        if "review_photos" in tables:
            cur.execute("PRAGMA table_info(review_photos);")
            cols = [c[1] for c in cur.fetchall()]
            if "trip_id" not in cols:
                print(f"Adding 'trip_id' to review_photos in {db_path}...")
                cur.execute("ALTER TABLE review_photos ADD COLUMN trip_id VARCHAR;")
                conn.commit()
            if "user_id" not in cols:
                print(f"Adding 'user_id' to review_photos in {db_path}...")
                cur.execute("ALTER TABLE review_photos ADD COLUMN user_id VARCHAR;")
                conn.commit()
            if "display_order" not in cols:
                print(f"Adding 'display_order' to review_photos in {db_path}...")
                cur.execute("ALTER TABLE review_photos ADD COLUMN display_order INTEGER DEFAULT 0;")
                conn.commit()

        conn.close()

if __name__ == "__main__":
    migrate()
