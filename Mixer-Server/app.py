import os
from flask import Flask, render_template, flash, request, send_file, redirect, jsonify
from flask_sqlalchemy import SQLAlchemy
from io import BytesIO

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = os.environ["DATABASE_URL"]
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["SECRET_KEY"] = "1234567890" # put your own secret key
db = SQLAlchemy(app)

class FileContents(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(500), unique=True)
    data = db.Column(db.LargeBinary)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/upload", methods=["POST"])
def upload():
    if request.method == 'POST':
        uploaded_files = request.files.getlist("inputFile")
        successes = []
        for file in uploaded_files:
            if file.filename.rsplit(".", 1)[0] == "" or file.filename.rsplit(".", 1)[1].lower() != "mp3":
                flash("\"" + file.filename + "\" is not an .mp3 file!")
                continue
            newFile = FileContents(name=file.filename, data=file.read())
            try:
                db.session.add(newFile)
                db.session.commit()
                successes += [file.filename]
            except:
                flash(file.filename + " already exists!")
    for file in successes:
        flash("Successfully uploaded " + file)
    return redirect("/")

@app.route("/download", methods=["POST"])
def download():
    file_name = request.values.get("fileName")
    file_data = FileContents.query.filter_by(name=file_name+".mp3").first()
    if file_data != None:
        flash("Successfully downloaded " + file_data.name)
        return send_file(BytesIO(file_data.data), attachment_filename=file_data.name, as_attachment=True)
    else:
        flash("\"" + file_name + "\" is not in the database!")
        return redirect("/")

@app.route("/query")
def query():
    for filename in db.session.query(FileContents.name).all():
        flash(filename[0])
    return render_template("query.html")

@app.route("/dbcontents")
def contents():
    data = []
    for filename in db.session.query(FileContents.name).all():
        data += filename
    return jsonify(data)

if __name__ == "__main__":
    app.run(debug=True)
