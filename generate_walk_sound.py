import wave
import math
import struct

def generate_tone(filename, duration, freq_func, vol_func=None, sample_rate=44100):
    num_samples = int(duration * sample_rate)
    max_amp = 32767.0
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = float(i) / sample_rate
            freq = freq_func(t)
            # Noise-like for walking step
            import random
            val = random.uniform(-1, 1) if freq < 100 else (1 if math.sin(2 * math.pi * freq * t) > 0 else -1)
            
            vol = 1.0
            if vol_func:
                vol = vol_func(t, duration)
            else:
                if duration - t < 0.05:
                    vol = (duration - t) / 0.05
                    
            sample = int(val * max_amp * 0.25 * vol)  # 25% max volume for walk
            wav_file.writeframes(struct.pack('<h', sample))

def fade_out(t, dur):
    return max(0, 1.0 - (t / dur))

# Walk step (Short low noise burst)
generate_tone('walk.wav', 0.15, lambda t: 50, fade_out)

print("Walk sound generated!")
