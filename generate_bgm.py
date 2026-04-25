import wave
import math
import struct

def generate_bgm(filename, duration, volume, is_intense, sample_rate=44100):
    num_samples = int(duration * sample_rate)
    max_amp = 32767.0
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = float(i) / sample_rate
            
            if is_intense:
                # Intense: deep drum pulse + smooth minor arpeggio
                t_drum = t % 0.5
                drum_env = max(0, 1.0 - t_drum * 4)
                drum_freq = 60 + drum_env * 20
                v_drum = math.sin(2 * math.pi * drum_freq * t) * drum_env * 0.7
                
                # Arpeggio (pure sine, no harsh square waves)
                seq = [300, 350, 400, 450]
                idx = int((t * 8) % 4)
                freq2 = seq[idx]
                v_arp = math.sin(2 * math.pi * freq2 * t) * 0.3
                
                val = v_drum + v_arp
            else:
                # Calm, slow pad-like sound (pure sine waves, very soothing)
                freq1 = 200 + 5 * math.sin(t * 0.5 * math.pi)
                freq2 = 250 + 5 * math.cos(t * 0.4 * math.pi)
                # Adding a soft high chime effect periodically
                chime_env = max(0, 1.0 - (t % 2.0) * 2)
                v_chime = math.sin(2 * math.pi * 523.25 * t) * chime_env * 0.15
                
                v1 = math.sin(2 * math.pi * freq1 * t) * 0.4
                v2 = math.sin(2 * math.pi * freq2 * t) * 0.4
                val = v1 + v2 + v_chime
            
            sample = int(val * max_amp * volume)
            
            # Clip
            if sample > 32767: sample = 32767
            if sample < -32768: sample = -32768
                
            wav_file.writeframes(struct.pack('<h', sample))

# Generate 8 seconds loop with very low soft volume
generate_bgm('bgm_calm.wav', 8.0, 0.2, False)
generate_bgm('bgm_intense.wav', 8.0, 0.2, True)

print("Soft BGM generated with pure sine waves!")
