# Triple-Stage-Audio-Processing-System

This project implements a multi-stage audio processing system in MATLAB and Simulink. It combines **three audio processing modules** into a single GUI application for real-time audio manipulation.

Course: CIE 227 – Signals and Systems  
Institution: Zewail City of Science and Technology  
Semester: Fall 2025

---

## 🎵 Project Overview

The system has **three main stages**:

1. **Audio Distortion Meter** – Measures harmonic distortion using Fourier analysis.  
2. **Bass Amplifier** – Boosts low-frequency components using FIR filtering.  
3. **Echo Generator** – Adds delayed echoes to create spatial sound effects.  

All stages are integrated into a MATLAB App Designer GUI for easy control and visualization.

---

## 🛠 Features

- Load and play audio files  
- Enable/disable any processing stage  
- Adjust parameters (gain, echo delay, attenuation) in real-time  
- Visualize time-domain waveform and frequency spectrum  
- Process and save the output audio  

---

## 🧩 Implementation

- **Stage 1: Audio Distortion Meter** – Uses FFT to compute total harmonic distortion (THD).  
- **Stage 2: Bass Amplifier** – FIR low-pass filter to amplify bass frequencies.  
- **Stage 3: Echo Generator** – Time-domain processing to add delayed echoes.  

All stages are implemented with MATLAB functions and Simulink models.

---

## 👨‍💻 Author

- Mohammed Soliman
- Moustafa Hesham
- Amr Hamed

---

## 📚 References

- McClellan, J. H., Schafer, R. W., & Yoder, M. **Digital Signal Processing First**, 2nd Edition, Pearson, 2016


---

## 📌 Key Takeaways

- Multi-stage audio processing in MATLAB & Simulink

- Implementation of THD measurement, FIR filtering, and echo generation

- Development of interactive GUI for audio analysis and processing

- Educational demonstration of practical signal processing concepts