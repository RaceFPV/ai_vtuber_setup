
// Live2D SDK: Trigger a happy expression
function reactToSpeech(text, emotion) {
    // Set facial expression based on emotion
    if (emotion == "happy") {
        live2DModel.setExpression("happy");
    } else if (emotion == "sad") {
        live2DModel.setExpression("sad");
    }

    // Trigger specific gesture based on text content
    if (text.includes("great job") || text.includes("well done")) {
        live2DModel.playMotion("thumbs_up", 0, 1);
    }
}
