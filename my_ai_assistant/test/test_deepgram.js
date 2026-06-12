const apiKey = "5ad0ebfddedec0b349c567dc7625bef97ad6f3a2";
const url = "wss://api.deepgram.com/v1/listen?model=nova-3&diarize=true&language=th&interim_results=true&endpointing=300";

console.log("Connecting to Deepgram at URL:", url);

const ws = new WebSocket(url, {
  headers: {
    "Authorization": `Token ${apiKey}`
  }
});

ws.onopen = () => {
  console.log("WebSocket opened successfully!");
  
  // Send some dummy silence audio data (a small silence chunk or empty buffer)
  // Let's send a fake 1-second silence in raw PCM/WebM/Ogg format
  // Deepgram expects audio data to start processing
  const buffer = new ArrayBuffer(100);
  ws.send(buffer);
  console.log("Sent dummy audio data of 100 bytes");
  
  // Send KeepAlive JSON
  setInterval(() => {
    console.log("Sending KeepAlive...");
    ws.send(JSON.stringify({ type: "KeepAlive" }));
  }, 3000);
};

ws.onmessage = (event) => {
  console.log("Received message from Deepgram:", event.data);
};

ws.onclose = (event) => {
  console.log("WebSocket closed. Code:", event.code, "Reason:", event.reason);
  process.exit(0);
};

ws.onerror = (err) => {
  console.error("WebSocket error:", err);
};

// Auto close after 15 seconds
setTimeout(() => {
  console.log("Closing socket after 15s timeout...");
  ws.close();
}, 15000);
