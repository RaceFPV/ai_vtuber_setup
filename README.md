
# AI VTuber Setup with AWS Infrastructure

This project allows you to create an AI VTuber that interacts with Twitch chat messages using AWS infrastructure. It integrates API Gateway, SQS, Lambda, GPT-4, and Polly.

## Requirements
- Python 3.7+
- Node.js (for Live2D SDK)
- OBS Studio
- AWS Account (for Terraform configuration)
- GPT-4 API Key

## 1. Python Setup
```bash
python3 -m venv venv
python_code source venv/bin/activate
```

Install the required Python libraries using `pip`:
```bash
pip install requests TTS SpeechRecognition
pip install pyaudio  # For capturing microphone input
```

## 2. Coqui TTS Setup
Coqui TTS will be used for generating speech from GPT-4 responses locally:
```bash
pip install TTS
```

## 3. Terraform Setup for AWS
Navigate to the `terraform_aws` directory and initialize Terraform for AWS services:
```bash
cd terraform_aws
terraform init
terraform apply
```

This will create:
- API Gateway to receive Twitch messages.
- SQS queue to handle message flow.
- Lambda function to process messages, send them to GPT-4, and convert responses to speech using Polly.
- IAM roles to grant required permissions to Lambda.

## 4. Running the Lambda Function
You need to deploy the Lambda function code provided in the `lambda_code` folder. You can use the AWS CLI or the AWS Lambda console to upload the code.

## 5. Live2D Setup
Download and install the Live2D Cubism SDK. The provided `live2d_control.js` file contains basic JavaScript functions to control your Live2D model's expressions and gestures.
