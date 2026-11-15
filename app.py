from flask import Flask, render_template, request, redirect, url_for, session, flash, abort
from flask_wtf.csrf import CSRFProtect
from dotenv import load_dotenv
import os
import re
import psycopg2
from psycopg2.extras import RealDictCursor
from werkzeug.security import generate_password_hash, check_password_hash

load_dotenv()

app = Flask(__name__, template_folder="app/templates", static_folder="app/static")
app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "dev-only-change-this-secret-key")
app.config["SESSION_COOKIE_HTTPONLY"] = True
app.config["SESSION_COOKIE_SAMESITE"] = "Lax"
# Для локальной учебной работы HTTP допустим; на HTTPS-сервере включить True.
app.config["SESSION_COOKIE_SECURE"] = os.getenv("COOKIE_SECURE", "0") == "1"
CSRFProtect(app)

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError(
        "Не задан DATABASE_URL. Создайте файл .env по примеру .env.example "
        "и укажите параметры подключения к PostgreSQL."
    )

def get_db():
    return psycopg2.connect(DATABASE_URL)

def query(sql, params=(), fetch=True):
    conn = get_db()
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(sql, params)
            if fetch:
                rows = cur.fetchall()
            else:
                rows = None
            conn.commit()
            return rows
    finally:
        conn.close()

@app.context_processor
def inject_user():
    return {"current_user": session.get("username")}

@app.route("/")
def index():
    mods = query("""
        SELECT id, title, slug, short_description, version, rating, downloads,
               image_url, verified
        FROM mods
        ORDER BY downloads DESC, id DESC
        LIMIT 6
    """)
    return render_template("index.html", mods=mods)

@app.route("/mods")
def mods():
    search = request.args.get("search", "").strip()
    version = request.args.get("version", "").strip()
    category = request.args.get("category", "").strip()

    conditions = []
    params = []

    if search:
        conditions.append("(m.title ILIKE %s OR m.short_description ILIKE %s)")
        params += [f"%{search}%", f"%{search}%"]

    if version:
        conditions.append("m.version = %s")
        params.append(version)

    if category:
        conditions.append("""
            EXISTS (
                SELECT 1 FROM mod_categories mc
                JOIN categories c ON c.id = mc.category_id
                WHERE mc.mod_id = m.id AND c.name = %s
            )
        """)
        params.append(category)

    where = ("WHERE " + " AND ".join(conditions)) if conditions else ""

    mods = query(f"""
        SELECT m.id, m.title, m.slug, m.short_description, m.version,
               m.rating, m.downloads, m.image_url, m.verified
        FROM mods m
        {where}
        ORDER BY m.downloads DESC, m.id DESC
    """, params)

    categories = query("SELECT name FROM categories ORDER BY name")
    versions = query("SELECT DISTINCT version FROM mods ORDER BY version DESC")

    return render_template(
        "mods.html",
        mods=mods,
        categories=categories,
        versions=versions,
        search=search,
        selected_version=version,
        selected_category=category
    )

@app.route("/mods/<slug>")
def mod_detail(slug):
    rows = query("""
        SELECT m.*, u.username AS author
        FROM mods m
        LEFT JOIN users u ON u.id = m.author_id
        WHERE m.slug = %s
    """, (slug,))
    if not rows:
        abort(404)

    mod = rows[0]
    categories = query("""
        SELECT c.name
        FROM categories c
        JOIN mod_categories mc ON mc.category_id = c.id
        WHERE mc.mod_id = %s
        ORDER BY c.name
    """, (mod["id"],))
    return render_template("mod_detail.html", mod=mod, categories=categories)

@app.post("/mods/<int:mod_id>/download")
def download_mod(mod_id):
    query("UPDATE mods SET downloads = downloads + 1 WHERE id = %s", (mod_id,), fetch=False)
    row = query("SELECT slug FROM mods WHERE id = %s", (mod_id,))
    if not row:
        abort(404)
    return redirect(url_for("mod_detail", slug=row[0]["slug"]))

@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        username = request.form.get("username", "").strip()
        email = request.form.get("email", "").strip().lower()
        password = request.form.get("password", "")

        if len(username) < 3 or len(username) > 50 or len(email) > 120 or len(password) < 8 or len(password) > 200:
            flash("Имя пользователя — от 3 до 50 символов; пароль — от 8 до 200 символов.", "error")
            return redirect(url_for("register"))

        exists = query(
            "SELECT id FROM users WHERE username = %s OR email = %s",
            (username, email)
        )
        if exists:
            flash("Пользователь с таким именем или email уже существует.", "error")
            return redirect(url_for("register"))

        query("""
            INSERT INTO users (username, email, password_hash)
            VALUES (%s, %s, %s)
        """, (username, email, generate_password_hash(password)), fetch=False)

        flash("Регистрация завершена. Теперь войдите.", "success")
        return redirect(url_for("login"))

    return render_template("register.html")

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "")

        rows = query(
            "SELECT id, username, password_hash FROM users WHERE username = %s",
            (username,)
        )
        if not rows or not check_password_hash(rows[0]["password_hash"], password):
            flash("Неверное имя пользователя или пароль.", "error")
            return redirect(url_for("login"))

        session["user_id"] = rows[0]["id"]
        session["username"] = rows[0]["username"]
        return redirect(url_for("index"))

    return render_template("login.html")

@app.post("/logout")
def logout():
    session.clear()
    return redirect(url_for("index"))

@app.route("/add-mod", methods=["GET", "POST"])
def add_mod():
    if "user_id" not in session:
        flash("Для добавления мода необходимо войти.", "error")
        return redirect(url_for("login"))

    categories = query("SELECT id, name FROM categories ORDER BY name")

    if request.method == "POST":
        title = request.form.get("title", "").strip()
        slug = re.sub(r"[^a-z0-9-]+", "-", title.lower()).strip("-")
        description = request.form.get("description", "").strip()
        short_description = request.form.get("short_description", "").strip()
        version = request.form.get("version", "").strip()
        image_url = request.form.get("image_url", "").strip() or None
        selected_categories = request.form.getlist("categories")

        if not title or not description or not version or len(title) > 120 or len(short_description) > 255 or len(version) > 20 or len(description) > 10000:
            flash("Заполните название, описание и версию.", "error")
            return redirect(url_for("add_mod"))

        try:
            rows = query("""
                INSERT INTO mods
                    (title, slug, description, short_description, version, image_url, author_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """, (
                title, slug, description, short_description,
                version, image_url, session["user_id"]
            ))
            mod_id = rows[0]["id"]

            for category_id in selected_categories:
                query("""
                    INSERT INTO mod_categories (mod_id, category_id)
                    VALUES (%s, %s)
                    ON CONFLICT DO NOTHING
                """, (mod_id, int(category_id)), fetch=False)

        except psycopg2.errors.UniqueViolation:
            flash("Мод с таким названием уже существует.", "error")
            return redirect(url_for("add_mod"))

        flash("Мод добавлен.", "success")
        return redirect(url_for("mod_detail", slug=slug))

    return render_template("add_mod.html", categories=categories)

@app.route("/forum")
def forum():
    topics = query("""
        SELECT f.*, u.username
        FROM forum_topics f
        JOIN users u ON u.id = f.author_id
        ORDER BY f.created_at DESC
    """)
    return render_template("forum.html", topics=topics)

@app.route("/news")
def news():
    return render_template("news.html")

@app.errorhandler(404)
def not_found(_):
    return render_template("404.html"), 404

if __name__ == "__main__":
    app.run(debug=False)
