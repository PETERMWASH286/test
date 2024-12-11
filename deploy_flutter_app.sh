#!/bin/bash

# Define your paths
FLUTTER_PROJECT_PATH="$HOME/test"  # Path to your Flutter project (adjusted to match your setup)
APK_OUTPUT_PATH="$FLUTTER_PROJECT_PATH/build/app/outputs/flutter-apk/app-release.apk"  # APK location after build
FLASK_API_UPLOAD_ENDPOINT="https://expertstrials.xyz/Garifix_app/api/upload-apk"  # Flask API endpoint to handle APK uploads
FLASK_API_NOTIFY_ENDPOINT="https://expertstrials.xyz/Garifix_app/api/update-app"  # Flask API endpoint to notify about the new APK

# Step 1: Navigate to the Flutter project directory
echo "Navigating to the Flutter project directory..."
cd $FLUTTER_PROJECT_PATH || { echo "Flutter project directory not found"; exit 1; }

# Step 2: Build the Flutter app in release mode
echo "Building the Flutter app..."
flutter build apk --release

if [ $? -ne 0 ]; then
    echo "Flutter build failed!"
    exit 1
fi

echo "Flutter build completed successfully."

# Step 3: Upload the APK directly to the Flask backend
if [ -f "$APK_OUTPUT_PATH" ]; then
    echo "Uploading APK to the Flask backend..."
    curl -X POST "$FLASK_API_UPLOAD_ENDPOINT" \
        -H "Content-Type: multipart/form-data" \
        -F "file=@$APK_OUTPUT_PATH"

    if [ $? -ne 0 ]; then
        echo "Failed to upload APK to the Flask backend!"
        exit 1
    fi

    echo "APK uploaded successfully to the Flask backend."
else
    echo "APK file not found at $APK_OUTPUT_PATH!"
    exit 1
fi

# Step 4: Notify Flask backend about the new APK
echo "Notifying Flask backend about the new APK..."
curl -X POST "$FLASK_API_NOTIFY_ENDPOINT" \
    -H "Content-Type: application/json" \
    -d '{"apk_path": "/uploads/app-release.apk"}'

if [ $? -ne 0 ]; then
    echo "Failed to notify Flask backend!"
    exit 1
fi

echo "Flask backend notified successfully."

echo "Automation completed successfully."
