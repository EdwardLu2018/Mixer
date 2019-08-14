import os
from flask import Flask, render_template, flash, request, send_file, redirect, jsonify, url_for
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, UserMixin, login_user
from io import BytesIO
import threading

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = os.environ["DATABASE_URL"]
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["SECRET_KEY"] = "1234567890"
db = SQLAlchemy(app)
login_manager = LoginManager()
login_manager.init_app(app)

class FileContents(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(500), unique=True)
    data = db.Column(db.LargeBinary)

class Users(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100))
    password = db.Column(db.String(100))

    def __init__(self, name, password):
        self.name = name
        self.password = password

    def get_id(self):
        return self.id

    def is_active(self):
        return self.active

    def is_anonymous(self):
        return self.is_anonymous

@login_manager.user_loader
def load_user(id):
    return Users.query.get(int(id))

@login_manager.unauthorized_handler
def unauthorized():
    return redirect(url_for("index"))

@app.route("/", methods=["GET", "POST"])
def index():
    if request.method == "POST":
        name = request.form["name"]
        password = request.form["password"]
        confirmation = request.form["confirmation"]
        if not name or not password or not confirmation:
            flash("Please enter all fields!", "error")
            render_template("index.html")
        elif password == confirmation:
            for user in Users.query.all():
                if user.password == password and user.name == name:
                    flash("Successfully logged in! Welcome, " + user.name, "login")
                    login_user(user)
                    return render_template("main.html")
    return render_template("index.html")

@app.route("/upload", methods=["POST"])
def upload():
    if request.method == "POST":
        uploaded_files = request.files.getlist("inputFile")
        successes = []
        for file in uploaded_files:
            if file.filename.rsplit(".", 1)[0] == "" or file.filename.rsplit(".", 1)[1].lower() != "mp3":
                flash("\"" + file.filename + "\" is not an .mp3 file!", "error")
                continue
            if FileContents.query.filter_by(name=file.filename).scalar():
                flash(file.filename + " already exists!", "error")
                continue
            newFile = FileContents(name=file.filename, data=file.read())
            threading.Thread(target=save_to_db, args=(newFile,successes,)).start()
            successes += [file.filename]
    for file in successes:
        flash("Successfully uploaded " + file, "success")
    return render_template("main.html")

def save_to_db(newFile, successes):
    db.session.add(newFile)
    db.session.commit()

@app.route("/download", methods=["POST"])
def download():
    if request.method == "POST":
        file_name = request.values.get("fileName")
        file_data = FileContents.query.filter_by(name=file_name+".mp3").first()
        if file_data != None:
            flash("Successfully downloaded " + file_data.name, "success")
            return send_file(BytesIO(file_data.data), attachment_filename=file_data.name, as_attachment=True)
        else:
            flash("\"" + file_name + "\" is not in the database!", "error")
    return render_template("main.html")

@app.route("/download/<song>")
def download_song(song):
    file_name = song + ".mp3"
    file_data = FileContents.query.filter_by(name=file_name).first()
    if file_data != None:
        flash("Successfully downloaded " + file_data.name, "success")
        return send_file(BytesIO(file_data.data), attachment_filename=file_data.name, as_attachment=True)
    else:
        flash("\"" + song + "\" is not in the database!", "error")
    return render_template("main.html")

@app.route("/delete", methods=["POST"])
def delete():
    if request.method == "POST":
        filename = request.values.get("fileName")
        if filename:
            db.session.query(FileContents).filter(FileContents.name==filename+".mp3").delete()
            db.session.commit()
            flash("Successfully deleted \"" + filename + ".mp3\" from the database", "success")
        else:
            flash("Please enter all fields!", "error")
    return render_template("main.html")

@app.route("/dbcontents")
def contents():
    data = []
    for filename in db.session.query(FileContents.name).all():
        data += filename
    return jsonify(data)

if __name__ == "__main__":
    app.run(debug=True)
