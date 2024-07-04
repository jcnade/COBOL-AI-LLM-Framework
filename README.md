# COBOL-AI-LLM-Framework 🚀

Welcome to the COBOL-AI-LLM-Framework! This project aims to bring the power of Large Language Models (LLM) to the COBOL programming language. Leveraging decades of COBOL reliability and the cutting-edge advancements in AI, this framework is designed for robust, enterprise-grade AI solutions.

## Features

- **Blazing Fast Performance**: Experience the unmatched speed of COBOL for AI tasks.
- **Legacy System Integration**: Seamlessly integrates with existing COBOL-based systems.
- **Highly Scalable**: Designed to handle extensive AI workloads efficiently.
- **Enterprise-Grade Security**: Built with security best practices for mission-critical applications.

## Installation

Clone the repository and follow these steps to install and set up the framework:

```bash
git clone https://github.com/jcnade/COBOL-AI-LLM-Framework.git
cd COBOL-AI-LLM-Framework
cobc -x llm_framework.cbl -o llm_framework
./llm_framework
```

## Compile the Framework and Utility Programs

Navigate to the src directory and compile the necessary COBOL files:

```bash
cd src
cobc -x llm_framework.cbl -o llm_framework
cobc -x config.cbl -o config
cobc -x utils.cbl -o utils
```

## Run the Framework

Run the compiled framework executable to ensure everything is set up correctly:

```bash
./llm_framework

```

## Configuration

The framework uses a configuration file (config.dat) to set parameters such as maximum tokens, model path, log level, and threshold values. Ensure this file is present in the working directory. An example content for config.dat:

```bash
00100models/default.llm                              INFO      075.00

```

## Configuration Parameters

* MAX-TOKENS (5 digits): Specifies the maximum number of tokens the framework can process. Example: 00200
* MODEL-PATH (50 characters): The path to the LLM model file. Ensure the path is correctly specified and the model file exists. Example: models/advanced.llm
* LOG-LEVEL (10 characters): The level of logging detail. Valid values are INFO, DEBUG, and ERROR. Example: DEBUG
* THRESHOLD (5 digits, including 2 decimal places): The confidence threshold for AI decisions. This value should be between 0 and 1. Example: 085.00




## Usage

Example COBOL program using the framework:

```bash
IDENTIFICATION DIVISION.
PROGRAM-ID. HELLO-AI.
PROCEDURE DIVISION.
    DISPLAY 'Welcome to AI with COBOL and LLM!'.
    STOP RUN.
```

## Contributing

We welcome contributions from the COBOL and AI community! Feel free to open issues, submit PRs, and join the discussion to make this framework even better.

## License

This project is licensed under the MIT License.

