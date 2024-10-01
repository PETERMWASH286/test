from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
from flask_cors import CORS
from flask_migrate import Migrate
import json

# Initialize the Flask application
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Database configuration
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///users.db'  # Use a SQLite database
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)
migrate = Migrate(app, db)

with app.app_context():
    db.create_all()

# User model for the database
class User(db.Model):
    __tablename__ = 'user'  # Explicitly set the table name
    id = db.Column(db.Integer, primary_key=True)
    full_name = db.Column(db.String(150), nullable=False)
    email = db.Column(db.String(150), unique=True, nullable=False)
    password = db.Column(db.String(150), nullable=False)
    fingerprint_data = db.Column(db.String(500), nullable=True)  # Store fingerprint data
    pin = db.Column(db.String(6), nullable=True)  # Store the user PIN
# Payment model for the database
class Payment(db.Model):
    __tablename__ = 'payment'  # Explicitly set the table name
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(150), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    subscription_type = db.Column(db.String(50), nullable=False)
    phone_number = db.Column(db.String(15), nullable=False)

import re

@app.route('/api/payment', methods=['POST'])
def submit_payment():
    data = request.get_json()
    
    # Extracting the email, amount, subscription_type, and phone_number
    email = data.get('email')
    raw_amount = data.get('amount')  # 'Ksh 2000 / Year'
    subscription_type = data.get('subscription_type')
    phone_number = data.get('phone_number')

    # Extract numeric value from the raw_amount string
    amount_match = re.search(r'(\d+)', raw_amount)
    if amount_match:
        amount = float(amount_match.group(0))  # Convert to float
    else:
        return jsonify({"error": "Invalid amount format"}), 400  # Handle invalid format

    # Now proceed to save in the database
    new_payment = Payment(email=email, amount=amount, subscription_type=subscription_type, phone_number=phone_number)

    try:
        db.session.add(new_payment)
        db.session.commit()
        return jsonify({"message": "Payment submitted successfully"}), 201
    except Exception as e:
        db.session.rollback()  # Roll back in case of an error
        return jsonify({"error": str(e)}), 500

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
    
    user = User.query.filter_by(email=email).first()
    if user:
        user.fingerprint_data = fingerprint_data
        db.session.commit()
        return jsonify({"message": "Fingerprint set up successfully!"}), 200
    return jsonify({"message": "User not found."}), 404

# New endpoint to save the PIN after confirmation
@app.route('/save_pin', methods=['POST'])
def save_pin():
    data = request.get_json()
    email = data.get('email')
    pin = data.get('pin')
    
    user = User.query.filter_by(email=email).first()
    if user:
        user.pin = generate_password_hash(pin, method='pbkdf2:sha256')
        db.session.commit()
        return jsonify({"message": "PIN saved successfully!"}), 200
    return jsonify({"message": "User not found."}), 404

# Endpoint for validating PIN login
@app.route('/validate_pin', methods=['POST'])
def validate_pin():
    data = request.get_json()
    email = data.get('email')
    pin = data.get('pin')

    # Print email and PIN for debugging purposes
    print(f"Received email: {email}")
    print(f"Received PIN: {pin}")

    user = User.query.filter_by(email=email).first()

    # Check if user exists and if the provided PIN matches the hashed PIN
    if user and check_password_hash(user.pin, pin):  # Use check_password_hash to verify
        return jsonify({"message": "PIN validation successful!"}), 200
    else:
        return jsonify({"message": "Invalid PIN!"}), 401


# Endpoint for validating fingerprint login
@app.route('/validate_fingerprint', methods=['POST'])
def validate_fingerprint():
    data = request.get_json()
    email = data.get('email')

    user = User.query.filter_by(email=email).first()

    if user:
        # Here you can add logic to validate the fingerprint
        # For demonstration, assume fingerprint validation always succeeds
        return jsonify({"message": "Fingerprint validation successful!"}), 200
    else:
        return jsonify({"message": "User not found!"}), 404

@app.route('/get_full_name', methods=['GET'])
def get_full_name():
    email = request.args.get('email')
    
    # Query the database to find the user by email
    user = User.query.filter_by(email=email).first()
    
    if user:
        return jsonify({'full_name': user.full_name}), 200
    return jsonify({'message': 'User not found'}), 404



if __name__ == '__main__':
    with app.app_context():  # Create an application context
        db.create_all()  # Create the database tables
    app.run(host='0.0.0.0', port=5000, debug=True)