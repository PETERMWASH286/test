from flask import Flask, request, jsonify, session
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
from flask_cors import CORS
from flask_migrate import Migrate
import json
from sqlalchemy import Column, Integer, String, Float, Text, DateTime, func
import os
import secrets
from werkzeug.utils import secure_filename

# Initialize the Flask application
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes
app.config['UPLOAD_FOLDER'] = 'uploads'

# Database configuration
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///users.db'  # Use a SQLite database
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)
migrate = Migrate(app, db)
app.secret_key = secrets.token_hex(16)  # Generates a secure random secret key

from datetime import timedelta


# Set session lifetime
app.permanent_session_lifetime = timedelta(minutes=60)  # Change to your desired duration


# Define models first
class User(db.Model):
    __tablename__ = 'user'  # Explicitly set the table name
    id = db.Column(db.Integer, primary_key=True)
    full_name = db.Column(db.String(150), nullable=False)
    email = db.Column(db.String(150), unique=True, nullable=False)
    password = db.Column(db.String(150), nullable=False)
    fingerprint_data = db.Column(db.String(500), nullable=True)  # Store fingerprint data
    pin = db.Column(db.String(6), nullable=True)  # Store the user PIN

class Payment(db.Model):
    __tablename__ = 'payment'  # Explicitly set the table name
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(150), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    subscription_type = db.Column(db.String(50), nullable=False)
    phone_number = db.Column(db.String(15), nullable=False)
    role = db.Column(db.String(50), nullable=False)  # New role column

class Report(db.Model):
    __tablename__ = 'report'
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(150), db.ForeignKey('user.email'), nullable=False)
    problem_type = db.Column(db.String(150), nullable=False)
    urgency_level = db.Column(db.Float, nullable=False)
    details = db.Column(db.Text, nullable=False)
    images = db.Column(db.String(500), nullable=True)  # Path to uploaded images
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())
    cost = db.Column(db.Float, default=0)  # New cost column with default value 0


# Create all tables after defining all models
with app.app_context():  # Create an application context
    db.create_all()  # Create the database tables

    # Print the created tables
    created_tables = db.metadata.tables.keys()  # Get table names from metadata
    print("Created tables:", list(created_tables))

    # Print the database location
    print("Database file location:", os.path.abspath('users.db'))

import re

import logging

# Configure logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

@app.route('/api/payment', methods=['POST'])
def submit_payment():
    data = request.get_json()
    
    # Validate input data
    required_fields = ['email', 'amount', 'subscriptionType', 'phoneNumber', 'role']
    for field in required_fields:
        if field not in data:
            return jsonify({"success": False, "error": f"Missing field: {field}"}), 400
    
    email = data['email']
    raw_amount = data['amount']  # 'Ksh 2000 / Year'
    subscription_type = data['subscriptionType']
    phone_number = data['phoneNumber']
    role = data['role']

    # Extract numeric value from the raw_amount string
    amount_match = re.search(r'(\d+)', raw_amount)
    if amount_match:
        amount = float(amount_match.group(0))  # Convert to float
    else:
        return jsonify({"success": False, "error": "Invalid amount format"}), 400

    # Now proceed to save in the database
    new_payment = Payment(
        email=email,
        amount=amount,
        subscription_type=subscription_type,
        phone_number=phone_number,
        role=role
    )

    try:
        db.session.add(new_payment)
        db.session.commit()
        return jsonify({"success": True, "message": "Payment submitted successfully"}), 201
    except Exception as e:
        db.session.rollback()  # Roll back in case of an error
        logging.error("Error occurred while submitting payment: %s", e)
        return jsonify({"success": False, "error": str(e)}), 500



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
        session['email'] = email  # Store email in session
        session.permanent = True  # Make session permanent
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
        session['email'] = email  # Store email in session
        session.permanent = True  # Make session permanent
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

# Ensure the upload folder exists
if not os.path.exists(app.config['UPLOAD_FOLDER']):
    os.makedirs(app.config['UPLOAD_FOLDER'])

# Define allowed file types
ALLOWED_EXTENSIONS = {'pdf', 'doc', 'docx'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS
@app.route('/submit_report', methods=['POST'])
def submit_report():
    # Retrieve the email directly from the form data
    email = request.form.get('email')  # Get email from the form data
    problem_type = request.form.get('problemType')
    urgency_level = request.form.get('urgencyLevel')  # Get as string first
    details = request.form.get('details')
    saved_images = request.files.getlist('images')  # Adjust this based on your upload logic

    # Print out the received values for debugging
    print(f"Received Email: {email}")
    print(f"Received Problem Type: {problem_type}")
    print(f"Received Urgency Level: {urgency_level}")
    print(f"Received Details: {details}")
    print(f"Number of Images: {len(saved_images)}")

    # Convert urgency level to float safely
    try:
        urgency_level = float(urgency_level)
    except (ValueError, TypeError):
        print("Invalid urgency level. Setting to 0.")
        urgency_level = 0.0

    # Handle image uploads
    saved_image_paths = []
    for file in saved_images:
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            file.save(file_path)
            saved_image_paths.append(file_path)

    images_string = ','.join(saved_image_paths)  # Convert list to a comma-separated string

    # Create a new report entry
    new_report = Report(
        email=email,
        problem_type=problem_type,
        urgency_level=urgency_level,
        details=details,
        images=images_string,  # Store the comma-separated string
        created_at=db.func.current_timestamp()
    )

    db.session.add(new_report)
    db.session.commit()

    print("New report saved successfully.")  # Confirmation message

    return jsonify({"success": True}), 201
    
@app.route('/api/repairs/<email>', methods=['GET'])
def get_repairs(email):
    reports = Report.query.filter_by(email=email).all()
    repairs_history = [
        {
            'date': report.created_at.strftime('%d %B, %Y'),
            'description': report.problem_type,
            'cost': report.cost
        }
        for report in reports
    ]
    return jsonify(repairs_history)

if __name__ == '__main__':
    with app.app_context():  # Create an application context
        db.create_all()  # Create the database tables
    app.run(host='0.0.0.0', port=5000, debug=True)