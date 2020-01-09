from flask import render_template, flash, request, send_file, redirect, jsonify, url_for, Response
from flask_login import login_user
from app import app, db
from app.models import Users, FileContents
from io import BytesIO
import threading

@app.route("/", methods=["GET", "POST"])
@app.route('/index', methods=['GET', 'POST'])
def index():
    if request.method == "POST":
        name = request.form["name"]
        password = request.form["password"]
        confirmation = request.form["confirmation"]
        if not name or not password or not confirmation:
            flash("Please enter all fields!", "error")
        elif password == confirmation:
            for user in Users.query.all():
                if user.password == password and user.name == name:
                    flash(f"Successfully logged in! Welcome, {user.name}!", "login")
                    login_user(user)
                    return render_template("main.html")
        else:
            flash(f"Sign in failed!", "error")
    return render_template("index.html")

@app.route("/upload", methods=["POST"])
def upload():
    if request.method == "POST":
        uploaded_files = request.files.getlist("inputFile")
        successes = []
        if uploaded_files:
            for file in uploaded_files:
                if file.filename.rsplit(".", 1)[0] == "" or file.filename.rsplit(".", 1)[1].lower() != "mp3":
                    flash(f"\"{file.filename}\" is not a valid .mp3 file!", "error")
                    continue
                if FileContents.query.filter_by(name=file.filename).scalar():
                    flash(f"{file.filename} already exists!", "error")
                    continue
                newFile = FileContents(name=file.filename.strip(), data=file.read())
                threading.Thread(target=save_to_db, args=(newFile,successes,)).start()
                successes += [file.filename]
        else:
            flash("Please enter all fields!", "error")
    for file in successes:
        flash(f"Successfully uploaded {file}", "success")
    return render_template("main.html")

def save_to_db(newFile, successes):
    db.session.add(newFile)
    db.session.commit()

@app.route("/download", methods=["POST"])
def download():
    if request.method == "POST":
        filename = request.values.get("fileName")
        if filename:
            filename = filename+".mp3" if not ".mp3" in filename else filename
            file_data = FileContents.query.filter_by(name=filename).first()
            if file_data is not None:
                flash(f"Successfully downloaded {file_data.name}", "success")
                return send_file(BytesIO(file_data.data), mimetype="audio/mpeg", attachment_filename=file_data.name, as_attachment=True)
            else:
                flash(f"\"{filename}\" is not in the database!", "error")
        else:
            flash("Please enter all fields!", "error")
    return render_template("main.html")

@app.route("/download/<song>")
def download_song(song):
    filename = song + ".mp3" if not ".mp3" in song else song
    file_data = FileContents.query.filter_by(name=filename).first()
    if file_data is not None:
        flash(f"Successfully downloaded {file_data.name}", "success")
        return send_file(BytesIO(file_data.data), mimetype="audio/mpeg", attachment_filename=file_data.name, as_attachment=True)
    else:
        flash(f"\"{filename}\" is not in the database!", "error")
    return render_template("main.html")

@app.route("/stream/<song>")
def stream_song(song):
    filename = song + ".mp3" if not ".mp3" in song else song
    file_data = FileContents.query.filter_by(name=filename).first()
    if file_data is not None:
        flash(f"Successfully downloaded {file_data.name}", "success")
        def generate():
            data = file_data.data
            while data:
                yield data
                data = file_data.data
        return Response(generate(), mimetype="audio/mpeg")
    else:
        flash(f"\"{filename}\" is not in the database!", "error")
    return render_template("main.html")

@app.route("/delete", methods=["POST"])
def delete():
    if request.method == "POST":
        filename = request.values.get("fileName")
        if filename:
            filename = filename+".mp3" if not ".mp3" in filename else filename
            if filename in list(map(lambda x : x[0], db.session.query(FileContents.name).all())):
                db.session.query(FileContents).filter(FileContents.name==filename).delete()
                db.session.commit()
                flash(f"Successfully deleted \"{filename}\" from the database", "success")
            else:
                flash(f"\"{filename}\" is not in the database!", "error")
        else:
            flash("Please enter all fields!", "error")
    return render_template("main.html")

@app.route("/dbcontents")
def contents():
    data = list(map(lambda x : x[0], db.session.query(FileContents.name).all()))
    return jsonify(data)
