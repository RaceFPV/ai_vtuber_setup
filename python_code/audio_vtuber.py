
import speech_recognition as sr
import requests
from TTS.api import TTS

# Initialize recognizer and TTS model
recognizer = sr.Recognizer()
tts = TTS(model_name="tts_models/en/ljspeech/tacotron2-DDC", progress_bar=False)

# Function to capture microphone input
def capture_microphone_input():
    with sr.Microphone() as source:
        recognizer.adjust_for_ambient_noise(source)
        print("Listening...")
        audio = recognizer.listen(source)
        return audio

# Function to convert speech to text
def convert_speech_to_text(audio):
    try:
        return recognizer.recognize_google(audio)
    except sr.UnknownValueError:
        print("Sorry, I couldn't understand that.")
    except sr.RequestError:
        print("Could not request results.")
    return None

# GPT-4 API call
def call_gpt4(prompt):
    api_key = "YOUR_OPENAI_API_KEY"
    url = "https://api.openai.com/v1/completions"
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    data = {"model": "gpt-4", "prompt": prompt, "max_tokens": 100, "temperature": 0.7}
    
    response = requests.post(url, headers=headers, json=data)
    return response.json()["choices"][0]["text"]

# Main loop
while True:
    audio_input = capture_microphone_input()
    text_input = convert_speech_to_text(audio_input)

    if text_input:
        gpt_response = call_gpt4(text_input)
        print(f"GPT-4 Response: {gpt_response}")
        
        # Generate speech using Coqui TTS
        tts.tts_to_file(text=gpt_response, file_path="output.wav")
        print("Audio generated: output.wav")

        # Here, you can trigger Live2D animations and stream the output using OBS
