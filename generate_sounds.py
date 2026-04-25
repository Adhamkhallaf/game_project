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
            # Square wave for retro feel
            val = 1 if math.sin(2 * math.pi * freq * t) > 0 else -1
            
            vol = 1.0
            if vol_func:
                vol = vol_func(t, duration)
            else:
                # Default quick fade out to prevent clicks
                if duration - t < 0.05:
                    vol = (duration - t) / 0.05
                    
            sample = int(val * max_amp * 0.5 * vol)  # 50% max volume
            wav_file.writeframes(struct.pack('<h', sample))

def fade_out(t, dur):
    return max(0, 1.0 - (t / dur))

# 1. Collect (Short blip, pitch going up slightly)
generate_tone('collect.wav', 0.1, lambda t: 800 + 400 * t, fade_out)

# 2. Correct (Happy chime, arpeggio-like)
generate_tone('correct.wav', 0.4, lambda t: 523.25 if t < 0.1 else (659.25 if t < 0.2 else 783.99), fade_out)

# 3. Wrong (Low buzz)
generate_tone('wrong.wav', 0.3, lambda t: 150 - 50 * t, fade_out)

# 4. Door Open (Low rumble)
generate_tone('door.wav', 0.8, lambda t: 100 + 50 * math.sin(t * 50), fade_out)

# 5. Victory (Fanfare)
generate_tone('win.wav', 1.0, lambda t: 440 if t < 0.2 else (554 if t < 0.4 else (659 if t < 0.6 else 880)), lambda t, d: 1.0 if d - t > 0.1 else (d - t)/0.1)

print("Sounds generated!")
