from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash
from flask_cors import CORS
from flask_migrate import Migrate


# Initialize the Flask application
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Database configuration
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///users.db'  # Use a SQLite database
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)
migrate = Migrate(app, db)

# User model for the database
class User(db.Model):
    __tablename__ = 'user'  # Explicitly set the table name
    id = db.Column(db.Integer, primary_key=True)
    full_name = db.Column(db.String(150), nullable=False)
    email = db.Column(db.String(150), unique=True, nullable=False)
    password = db.Column(db.String(150), nullable=False)
    fingerprint_data = db.Column(db.String(500), nullable=True)  # Store fingerprint data
    pin = db.Column(db.String(6), nullable=True)  # Store the user PIN

# Endpoint for user signup
@app.route('/signup', methods=['POST'])
def signup():
    data = request.get_json()
    full_name = data.get('full_name')
    email = data.get('email')
    password = data.get('password')
    
    # Validate input
    if not full_name or not email or not password:
        return jsonify({"message": "Please fill out all fields."}), 400
    
    # Check if the user already exists
    existing_user = User.query.filter_by(email=email).first()
    if existing_user:
        return jsonify({"message": "User with this email already exists."}), 400

    # Hash the password
    hashed_password = generate_password_hash(password, method='pbkdf2:sha256')

    # Create new user
    new_user = User(full_name=full_name, email=email, password=hashed_password)
    db.session.add(new_user)
    db.session.commit()

    return jsonify({"message": "User created successfully!"}), 201

# Endpoint to save fingerprint and PIN
@app.route('/setup_fingerprint', methods=['POST'])
def setup_fingerprint():
    data = request.get_json()
    email = data.get('email')
    fingerprint_data = data.get('fingerprint_data')
    pin = data.get('pin')
    
    user = User.query.filter_by(email=email).first()
    if user:
        user.fingerprint_data = fingerprint_data
        user.pin = generate_password_hash(pin, method='pbkdf2:sha256')
        db.session.commit()
        return jsonify({"message": "Fingerprint and PIN set up successfully!"}), 200
    return jsonify({"message": "User not found."}), 404

if __name__ == '__main__':
    with app.app_context():  # Create an application context
        db.create_all()  # Create the database tables
    app.run(host='0.0.0.0', port=5000, debug=True)
