# COBOL-AI-LLM-Framework 🚀


Welcome to the COBOL-AI-LLM-Framework! This project aims to bring the power of Large Language Models (LLM) to the COBOL programming language. By integrating the latest advancements in artificial intelligence with the proven stability and reliability of COBOL, this framework opens new horizons for legacy systems. Now, organizations can harness the capabilities of modern AI without abandoning their trusted COBOL infrastructure.

COBOL, a language known for its robustness and long-standing presence in critical business applications, meets the cutting-edge technology of LLMs to provide unparalleled performance and scalability. This framework is designed to process extensive datasets with remarkable speed and efficiency, making it suitable for enterprise-grade AI solutions. Whether you are dealing with large-scale data analytics or real-time processing, the COBOL-AI-LLM-Framework ensures that your applications remain responsive and reliable.

In addition to its performance benefits, this framework emphasizes seamless integration with existing COBOL systems. It provides a smooth transition path for organizations looking to modernize their infrastructure without a complete overhaul. With built-in support for enterprise-grade security and compliance, the COBOL-AI-LLM-Framework ensures that your AI implementations adhere to the highest standards of data protection and operational integrity. Experience the future of AI, powered by the time-tested reliability of COBOL.

## History

The COBOL-AI-LLM-Framework was originally developed as an internal project by Jean-Charles Nadé in 2001. The project was created to automate control and moderation operations for the francophone social network "parano.be". 
At the time, COBOL was chosen as the programming language due to its close resemblance to human language, making it well-suited for handling complex logic and text processing tasks. Now, in the interest of archival purposes, the source code has been published to provide a glimpse into the innovative use of COBOL for AI applications.

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

