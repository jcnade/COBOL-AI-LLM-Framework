#!/bin/bash

echo "Starting installation of COBOL-AI-LLM-Framework..."

# Check if COBOL compiler is installed
if ! command -v cobc &> /dev/null
then
    echo "cobc could not be found. Please install OpenCOBOL or GnuCOBOL and try again."
    exit
fi

# Clone the repository
echo "Cloning the repository..."
git clone https://github.com/jcnade/COBOL-AI-LLM-Framework.git
cd COBOL-AI-LLM-Framework || { echo "Failed to enter the repository directory"; exit 1; }

# Compile the framework
echo "Compiling the framework..."
cd src || { echo "Failed to enter the src directory"; exit 1; }
cobc -x llm_framework.cbl -o llm_framework
if [ $? -ne 0 ]; then
    echo "Compilation failed. Please check the source code for errors."
    exit 1
fi

# Run a basic test
echo "Running a basic test to ensure the framework is set up correctly..."
./llm_framework
if [ $? -ne 0 ]; then
    echo "The framework did not run correctly. Please check for errors."
    exit 1
fi

echo "Installation of COBOL-AI-LLM-Framework completed successfully."
