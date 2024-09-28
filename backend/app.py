from flask import Flask, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

@app.route('/mechanics', methods=['GET'])
def get_mechanics():
    # Sample mechanics data
    mechanics = [
        {"name": "John Doe", "location": "Downtown", "specialty": "Engine Repairs"},
        {"name": "Jane Smith", "location": "City Center", "specialty": "Transmission Repairs"}
    ]
    return jsonify(mechanics)

if __name__ == '__main__':
    # Run the app on all available IPs on port 5000
    app.run(host='0.0.0.0', port=5000, debug=True)
