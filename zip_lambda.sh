#!/bin/bash

# Remove old build
rm -rf lambda_build lambda_build.zip

# Copy all files and folders from lambda/ to new build dir
cp -r lambda lambda_build

# Install requirements
pip install -r requirements.txt --target lambda_build

# Zip contents
cd lambda_build
zip -r ../lambda_build.zip .
cd ..

# Remove build folder after zipping
rm -rf lambda_build

echo "✅ Lambda package created: lambda_build.zip"
