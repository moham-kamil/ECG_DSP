# ECG Signal Processing using MATLAB

## Overview
![Demonstration](assets/demo.gif)

This project is a component of an **Electrocardiograph (ECG) Circuit Design and Software-based Processing** system utilizing the **MATLAB** environment. The code captures ECG signals directly from an audio input (such as a microphone or line-in) and processes them in real-time.

It employs Digital Signal Processing (DSP) techniques to clean the signal, detect peaks, and calculate essential vital indicators such as the Heart Rate in Beats Per Minute (BPM) and the Signal-to-Noise Ratio (SNR) both before and after filtering.

* **Core Functions:**
    * Acquiring audio/bio-signals using the `audiorecorder` object.
    * Designing and implementing an **IIR Low-pass Filter** (`designfilt`) to clean high-frequency noise from the signal.
    * Peak detection (R-peak identification) using `findpeaks`.
    * Calculating the Heart Rate (BPM) based on the time interval between detected R-peaks.
    * Calculating the Signal-to-Noise Ratio (SNR) as a performance metric for the filter.
    * Real-time graphical display of the raw and filtered signals.

## Key Parameters

These parameters can be adjusted at the beginning of the `ECG_DSP.m` file to fine-tune the system's performance:

| Parameter | Description | Default Value |
| :--- | :--- | :--- |
| `Fs` | Sampling frequency in Hertz (Hz). | 44100 Hz |
| `recordTime` | Duration of recording in each loop iteration (in seconds). | 4 seconds |
| `cutoffFreq` | Cutoff frequency for the Low-pass Filter. | 20 Hz |
| `triggerThreshold` | Amplitude threshold value for R-peak detection. | 0.02 |
| `FilterOrder` | The order of the IIR filter used. | 8 |

## How to Run

1.  Ensure you have the MATLAB environment installed and access to the Signal Processing Toolbox.
2.  Connect your bio-signal source (the output from your ECG circuit) to your computer's audio input.
3.  Run the `ECG_DSP.m` file in MATLAB.
4.  A Figure window will open, displaying the raw and filtered signals, and updating the calculated metrics (BPM, Frequency, SNR) in real-time.

## Real-Time Displayed Metrics

The following values are displayed directly on the figure window during live monitoring:

* **Frequency:** The signal frequency in Hertz (Hz).
* **BPM (Beats Per Minute):** The calculated heart rate.
* **Period:** The average time interval between R-peaks (in seconds).
* **Peak Amplitude:** The amplitude of the highest detected peak.
* **SNR1 (Before Filtering):** Signal-to-Noise Ratio before applying the filter.
* **SNR2 (After Filtering):** Signal-to-Noise Ratio after applying the filter (this should ideally be higher than SNR1).

---

**Note:** This script is specifically designed to receive an ECG signal from an external circuit. You may need to adjust the `cutoffFreq` and `triggerThreshold` values based on the noise characteristics and voltage output of your specific circuit.
