(function() {
  let mediaRecorder = null;
  let audioContext = null;
  let micStream = null;
  let systemStream = null;
  let socket = null;

  window.webAudioRecorder = {
    isRecording: false,

    async start(socketUrl, includeMic, includeSystem, onTranscript, onError) {
      if (this.isRecording) {
        if (onError) onError("Already recording");
        return;
      }

      try {
        let streamsToMix = [];

        // 1. Capture Microphone Audio
        if (includeMic) {
          micStream = await navigator.mediaDevices.getUserMedia({
            audio: {
              echoCancellation: !includeSystem,
              noiseSuppression: !includeSystem,
              autoGainControl: !includeSystem
            }
          });
          streamsToMix.push(micStream);
        }

        // 2. Capture System/Display Audio
        if (includeSystem) {
          try {
            // getDisplayMedia will prompt the user to choose a tab/window/screen to share
            systemStream = await navigator.mediaDevices.getDisplayMedia({
              video: {
                width: 1,
                height: 1,
                frameRate: 1
              },
              audio: {
                echoCancellation: false,
                noiseSuppression: false,
                autoGainControl: false
              }
            });
            
            const audioTracks = systemStream.getAudioTracks();
            if (audioTracks.length > 0) {
              // Push original systemStream; AudioContext will pull and mix only the audio tracks
              streamsToMix.push(systemStream);
            } else {
              console.warn("System audio was requested but no audio tracks were returned. Stopping display capture.");
              // Stop the video track so browser sharing indicator disappears
              systemStream.getTracks().forEach(t => t.stop());
              systemStream = null;
              
              if (!includeMic) {
                if (micStream) micStream.getTracks().forEach(t => t.stop());
                if (onError) onError("System audio was requested but not shared by the user.");
                return;
              }
            }
          } catch (e) {
            console.error("Error capturing system audio:", e);
            if (systemStream) {
              systemStream.getTracks().forEach(t => t.stop());
              systemStream = null;
            }
            if (!includeMic) {
              if (micStream) micStream.getTracks().forEach(t => t.stop());
              if (onError) onError("Failed to capture system audio: " + e.message);
              return;
            }
          }
        }

        if (streamsToMix.length === 0) {
          if (onError) onError("No audio source selected.");
          return;
        }

        // 3. Mix audio streams using AudioContext only if there are multiple streams
        let finalStream;
        if (streamsToMix.length > 1) {
          audioContext = new (window.AudioContext || window.webkitAudioContext)();
          if (audioContext.state === 'suspended') {
            await audioContext.resume();
          }
          
          const dest = audioContext.createMediaStreamDestination();

          streamsToMix.forEach(stream => {
            const source = audioContext.createMediaStreamSource(stream);
            const gainNode = audioContext.createGain();
            
            if (stream === systemStream) {
              gainNode.gain.value = 0.4; // 40% volume for system audio to avoid drowning out user's mic
            } else {
              gainNode.gain.value = 1.0; // 100% volume for mic
            }
            
            source.connect(gainNode);
            gainNode.connect(dest);
          });

          finalStream = dest.stream;
        } else {
          const stream = streamsToMix[0];
          if (stream.getVideoTracks().length > 0) {
            finalStream = new MediaStream(stream.getAudioTracks());
          } else {
            finalStream = stream;
          }
        }

        // 4. Connect WebSocket
        socket = new WebSocket(socketUrl);
        
        socket.onopen = () => {
          console.log("STT WebSocket proxy connection opened");
          
          // 5. Initialize MediaRecorder
          let options = { mimeType: 'audio/webm;codecs=opus' };
          if (!MediaRecorder.isTypeSupported(options.mimeType)) {
            options = { mimeType: 'audio/ogg;codecs=opus' };
          }
          if (!MediaRecorder.isTypeSupported(options.mimeType)) {
            options = { mimeType: 'audio/mp4' };
          }
          if (!MediaRecorder.isTypeSupported(options.mimeType)) {
            options = {}; // fallback to default
          }

          mediaRecorder = new MediaRecorder(finalStream, options);

          mediaRecorder.ondataavailable = (event) => {
            if (event.data && event.data.size > 0 && socket && socket.readyState === WebSocket.OPEN) {
              socket.send(event.data);
            }
          };

          mediaRecorder.onstop = () => {
            console.log("MediaRecorder stopped");
          };

          mediaRecorder.start(250);
          this.isRecording = true;
        };

        socket.onmessage = (event) => {
          if (onTranscript) {
            onTranscript(event.data);
          }
        };

        socket.onclose = (event) => {
          console.log("STT WebSocket proxy connection closed:", event.code, event.reason);
          this.stop();
        };

        socket.onerror = (err) => {
          console.error("STT WebSocket error:", err);
          if (onError) onError("WebSocket error: " + err.message);
        };

      } catch (err) {
        console.error("Failed to start audio recording:", err);
        this.stop();
        if (onError) onError(err.message || err.toString());
      }
    },

    stop() {
      if (!this.isRecording) return;
      this.isRecording = false;

      if (mediaRecorder && mediaRecorder.state !== 'inactive') {
        mediaRecorder.stop();
      }
      mediaRecorder = null;

      if (socket) {
        if (socket.readyState === WebSocket.OPEN || socket.readyState === WebSocket.CONNECTING) {
          socket.close();
        }
      }
      socket = null;

      if (micStream) {
        micStream.getTracks().forEach(track => track.stop());
        micStream = null;
      }

      if (systemStream) {
        systemStream.getTracks().forEach(track => track.stop());
        systemStream = null;
      }

      if (audioContext) {
        audioContext.close();
        audioContext = null;
      }
      
      console.log("Audio recording stopped and cleaned up");
    }
  };
  console.log("audio_recorder.js script has run, window.webAudioRecorder is initialized:", !!window.webAudioRecorder);
})();
