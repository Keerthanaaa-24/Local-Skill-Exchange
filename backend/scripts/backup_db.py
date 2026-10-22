"""
Automated Database Backup Utility for Local Skill Exchange.
Supports local and production MySQL databases.
Generates timestamped SQL dump archives in backend/backups/.
"""

import os
import sys
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlparse

# Add backend directory to sys.path
backend_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend_dir))

from app.core.config import settings

def run_backup():
    db_url = settings.DATABASE_URL
    backup_dir = backend_dir / "backups"
    backup_dir.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    backup_file = backup_dir / f"lse_backup_{timestamp}.sql"

    print("=" * 60)
    print(" Local Skill Exchange Database Backup")
    print(f" Timestamp: {timestamp}")
    print(f" Target File: {backup_file}")
    print("=" * 60)

    if db_url.startswith("sqlite"):
        import shutil
        sqlite_path = db_url.replace("sqlite:///", "").replace("sqlite://", "")
        abs_sqlite = (backend_dir / sqlite_path).resolve() if not os.path.isabs(sqlite_path) else Path(sqlite_path)
        if abs_sqlite.exists():
            shutil.copy2(abs_sqlite, backup_file)
            print(f"[Success] SQLite database copied to {backup_file}")
            return True
        else:
            print(f"[Error] SQLite file {abs_sqlite} does not exist.")
            return False

    # MySQL / MariaDB backup
    # Normalize URL: mysql+pymysql://user:pass@host:port/dbname
    clean_url = db_url.replace("mysql+pymysql://", "mysql://")
    parsed = urlparse(clean_url)

    user = parsed.username or "root"
    password = parsed.password or ""
    host = parsed.hostname or "localhost"
    port = str(parsed.port or 3306)
    database = parsed.path.lstrip("/").split("?")[0]

    # Attempt 1: mysqldump command-line utility
    try:
        cmd = [
            "mysqldump",
            f"--host={host}",
            f"--port={port}",
            f"--user={user}",
            "--single-transaction",
            "--quick",
            "--routines",
            "--triggers",
            database
        ]
        if password:
            cmd.insert(4, f"--password={password}")

        print(f"[Backup] Executing mysqldump for database '{database}' on {host}:{port}...")
        with open(backup_file, "w", encoding="utf-8") as out_f:
            process = subprocess.run(cmd, stdout=out_f, stderr=subprocess.PIPE, text=True, check=True)
        
        file_size = backup_file.stat().st_size
        print(f"[Success] Backup completed! Size: {file_size:,} bytes")
        return True
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"[Notice] Standard mysqldump utility not in PATH ({e}). Falling back to pure Python table exporter...")

    # Attempt 2: Pure Python SQL exporter using pymysql / sqlalchemy
    try:
        import pymysql
        conn = pymysql.connect(
            host=host,
            port=int(port),
            user=user,
            password=password,
            database=database,
            charset="utf8mb4"
        )
        with conn.cursor() as cursor, open(backup_file, "w", encoding="utf-8") as f:
            f.write(f"-- Local Skill Exchange Pure Python Database Backup\n")
            f.write(f"-- Generated At: {timestamp} UTC\n")
            f.write(f"-- Database: {database}\n\n")
            f.write("SET FOREIGN_KEY_CHECKS=0;\n\n")

            cursor.execute("SHOW TABLES")
            tables = [row[0] for row in cursor.fetchall()]

            for tbl in tables:
                # Dump CREATE TABLE
                cursor.execute(f"SHOW CREATE TABLE `{tbl}`")
                create_sql = cursor.fetchone()[1]
                f.write(f"DROP TABLE IF EXISTS `{tbl}`;\n")
                f.write(f"{create_sql};\n\n")

                # Dump Rows
                cursor.execute(f"SELECT * FROM `{tbl}`")
                rows = cursor.fetchall()
                if rows:
                    cursor.execute(f"DESCRIBE `{tbl}`")
                    cols = [f"`{col[0]}`" for col in cursor.fetchall()]
                    cols_str = ", ".join(cols)

                    for r in rows:
                        vals = []
                        for v in r:
                            if v is None:
                                vals.append("NULL")
                            elif isinstance(v, (int, float)):
                                vals.append(str(v))
                            elif isinstance(v, datetime):
                                vals.append(f"'{v.strftime('%Y-%m-%d %H:%M:%S')}'")
                            else:
                                escaped = str(v).replace("\\", "\\\\").replace("'", "\\'")
                                vals.append(f"'{escaped}'")
                        f.write(f"INSERT INTO `{tbl}` ({cols_str}) VALUES ({', '.join(vals)});\n")
                    f.write("\n")

            f.write("SET FOREIGN_KEY_CHECKS=1;\n")

        conn.close()
        file_size = backup_file.stat().st_size
        print(f"[Success] Pure Python backup successfully written! Size: {file_size:,} bytes")
        return True
    except Exception as ex:
        print(f"[Error] Failed to create database backup: {ex}")
        return False

if __name__ == "__main__":
    success = run_backup()
    sys.exit(0 if success else 1)
