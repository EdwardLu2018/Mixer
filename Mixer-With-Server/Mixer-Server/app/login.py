from flask_login import LoginManager
from app import login_manager
from app.models import Users

@login_manager.user_loader
def load_user(id):
    return Users.query.get(int(id))

@login_manager.unauthorized_handler
def unauthorized():
    return redirect(url_for("index"))
