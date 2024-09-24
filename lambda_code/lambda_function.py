
import json
import boto3
import requests

polly = boto3.client('polly')
s3 = boto3.client('s3')

def lambda_handler(event, context):
    for record in event['Records']:
        message_body = record['body']

        # Send message to GPT-4 API
        gpt_response = call_gpt4(message_body)
        response_text = gpt_response.get('choices')[0].get('text')
        
        # Convert GPT-4 response to speech using Polly
        audio_file = generate_speech(response_text)
        
        # Store the audio file in S3 (optional step)
        s3.upload_file(audio_file, 'YOUR_S3_BUCKET_NAME', 'response.mp3')
        
        return {
            'statusCode': 200,
            'body': json.dumps('Message processed successfully')
        }

def call_gpt4(prompt):
    api_key = "YOUR_GPT_API_KEY"
    url = "https://api.openai.com/v1/completions"
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    data = {"model": "gpt-4", "prompt": prompt, "max_tokens": 150, "temperature": 0.7}

    response = requests.post(url, headers=headers, json=data)
    return response.json()

def generate_speech(text):
    response = polly.synthesize_speech(Text=text, OutputFormat='mp3', VoiceId='Joanna')
    audio_file = "/tmp/response.mp3"
    
    with open(audio_file, 'wb') as f:
        f.write(response['AudioStream'].read())
    
    return audio_file
