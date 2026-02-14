import React, { useState, useRef, useEffect } from 'react';
import { Upload, Play, Square, Download, Settings } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, AreaChart, Area } from 'recharts';

export default function AudioProcessorPro() {
  const [audioFile, setAudioFile] = useState(null);
  const [audioBuffer, setAudioBuffer] = useState(null);
  const [processedBuffer, setProcessedBuffer] = useState(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [playingType, setPlayingType] = useState(null);
  const [status, setStatus] = useState('No file loaded');
  
  // Project 1: Distortion Meter
  const [enableDistortion, setEnableDistortion] = useState(false);
  const [clipLevel, setClipLevel] = useState(0.8);
  const [thdResult, setThdResult] = useState('N/A');
  
  // Project 2: Bass Amplifier
  const [enableBass, setEnableBass] = useState(false);
  const [lpfCutoff, setLpfCutoff] = useState(250);
  const [filterOrder, setFilterOrder] = useState(20);
  const [bassGain, setBassGain] = useState(30.0);
  
  // Project 3: Echo Generator
  const [enableEcho, setEnableEcho] = useState(false);
  const [echoDelay, setEchoDelay] = useState(500);
  const [echoAlpha, setEchoAlpha] = useState(0.6);
  
  // Visualization data
  const [originalTimeData, setOriginalTimeData] = useState([]);
  const [processedTimeData, setProcessedTimeData] = useState([]);
  const [originalFreqData, setOriginalFreqData] = useState([]);
  const [processedFreqData, setProcessedFreqData] = useState([]);
  
  const audioContextRef = useRef(null);
  const sourceNodeRef = useRef(null);

  useEffect(() => {
    audioContextRef.current = new (window.AudioContext || window.webkitAudioContext)();
    return () => {
      if (audioContextRef.current) {
        audioContextRef.current.close();
      }
    };
  }, []);

  const handleFileUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    setAudioFile(file);
    const arrayBuffer = await file.arrayBuffer();
    const audioBuffer = await audioContextRef.current.decodeAudioData(arrayBuffer);
    setAudioBuffer(audioBuffer);
    
    const duration = audioBuffer.duration.toFixed(2);
    const sampleRate = audioBuffer.sampleRate;
    setStatus(`Loaded "${file.name}" (${duration} sec @ ${sampleRate} Hz)`);
    
    visualizeAudio(audioBuffer, 'original');
    setProcessedBuffer(null);
    setProcessedTimeData([]);
    setProcessedFreqData([]);
    stopAudio();
  };

  const visualizeAudio = (buffer, type) => {
    const channelData = buffer.getChannelData(0);
    const sampleRate = buffer.sampleRate;
    
    // Time domain - sample points for smooth visualization
    const targetPoints = 3000;
    const step = Math.max(1, Math.floor(channelData.length / targetPoints));
    const timePoints = [];
    
    for (let i = 0; i < channelData.length && timePoints.length < targetPoints; i += step) {
      timePoints.push({
        time: i / sampleRate,
        amplitude: channelData[i]
      });
    }
    
    // Frequency domain using FFT
    const fftSize = 8192;
    const fftData = new Float32Array(fftSize);
    for (let i = 0; i < Math.min(fftSize, channelData.length); i++) {
      fftData[i] = channelData[i];
    }
    const freqPoints = performFFT(fftData, sampleRate);
    
    if (type === 'original') {
      setOriginalTimeData(timePoints);
      setOriginalFreqData(freqPoints);
    } else {
      setProcessedTimeData(timePoints);
      setProcessedFreqData(freqPoints);
    }
  };

  const performFFT = (data, sampleRate) => {
    const n = data.length;
    const spectrum = [];
    
    // Compute FFT (simplified DFT for demonstration)
    for (let k = 0; k < n / 2; k += 4) { // Step by 4 for performance
      let real = 0, imag = 0;
      
      // Sample subset for performance
      const step = Math.max(1, Math.floor(n / 1024));
      for (let t = 0; t < n; t += step) {
        const angle = (2 * Math.PI * k * t) / n;
        real += data[t] * Math.cos(angle);
        imag -= data[t] * Math.sin(angle);
      }
      
      const magnitude = Math.sqrt(real * real + imag * imag) / n;
      const db = 20 * Math.log10(magnitude + 1e-10);
      const frequency = (k * sampleRate) / n;
      
      if (frequency <= 5000) {
        spectrum.push({ frequency, magnitude: db });
      }
    }
    
    return spectrum;
  };

  const processAudio = async () => {
    if (!audioBuffer) return;
    
    setStatus('Processing audio...');
    
    const channelData = audioBuffer.getChannelData(0);
    let processedData = new Float32Array(channelData.length);
    
    // Copy original data
    for (let i = 0; i < channelData.length; i++) {
      processedData[i] = channelData[i];
    }
    
    // Apply Distortion/Clipping
    if (enableDistortion) {
      for (let i = 0; i < processedData.length; i++) {
        if (processedData[i] > clipLevel) processedData[i] = clipLevel;
        if (processedData[i] < -clipLevel) processedData[i] = -clipLevel;
      }
      
      // Calculate THD
      const thd = calculateTHD(processedData);
      setThdResult((thd * 100).toFixed(2) + '%');
    }
    
    // Apply Bass Boost
    if (enableBass) {
      processedData = applyBassBoost(processedData, audioBuffer.sampleRate);
    }
    
    // Apply Echo
    if (enableEcho) {
      processedData = applyEcho(processedData, audioBuffer.sampleRate);
    }
    
    // Create processed buffer
    const newBuffer = audioContextRef.current.createBuffer(
      audioBuffer.numberOfChannels,
      processedData.length,
      audioBuffer.sampleRate
    );
    newBuffer.copyToChannel(processedData, 0);
    
    // Copy to other channels if stereo
    for (let channel = 1; channel < audioBuffer.numberOfChannels; channel++) {
      newBuffer.copyToChannel(processedData, channel);
    }
    
    setProcessedBuffer(newBuffer);
    visualizeAudio(newBuffer, 'processed');
    
    let statusMsg = 'Processing complete! [';
    if (enableDistortion) statusMsg += `Distortion (Clip=${clipLevel}, THD=${thdResult}), `;
    if (enableBass) statusMsg += `Bass Boost (Gain=${bassGain}dB), `;
    if (enableEcho) statusMsg += `Echo (Delay=${echoDelay}ms), `;
    statusMsg = statusMsg.slice(0, -2) + ']';
    
    setStatus(statusMsg);
  };

  const calculateTHD = (data) => {
    // Simple THD approximation based on signal clipping
    let clipped = 0;
    let total = 0;
    
    for (let i = 0; i < data.length; i++) {
      total++;
      if (Math.abs(data[i]) >= clipLevel * 0.99) {
        clipped++;
      }
    }
    
    return clipped / total;
  };

  const applyBassBoost = (data, sampleRate) => {
    const result = new Float32Array(data.length);
    
    // Simple low-pass filter implementation
    const omega = 2 * Math.PI * lpfCutoff / sampleRate;
    const alpha = omega / (omega + 1);
    
    // Apply filter
    result[0] = data[0];
    for (let i = 1; i < data.length; i++) {
      result[i] = alpha * data[i] + (1 - alpha) * result[i - 1];
    }
    
    // Apply gain
    const linearGain = Math.pow(10, bassGain / 20);
    for (let i = 0; i < result.length; i++) {
      // Mix: original + boosted bass
      result[i] = data[i] * 0.7 + result[i] * linearGain * 0.3;
      // Prevent clipping
      result[i] = Math.max(-1, Math.min(1, result[i]));
    }
    
    return result;
  };

  const applyEcho = (data, sampleRate) => {
    const delaySamples = Math.floor((echoDelay / 1000) * sampleRate);
    const result = new Float32Array(data.length);
    
    for (let i = 0; i < data.length; i++) {
      result[i] = data[i];
      if (i >= delaySamples) {
        result[i] += echoAlpha * data[i - delaySamples];
      }
      // Prevent clipping
      result[i] = Math.max(-1, Math.min(1, result[i]));
    }
    
    return result;
  };

  const playAudio = (type) => {
    const buffer = type === 'original' ? audioBuffer : processedBuffer;
    if (!buffer) return;

    stopAudio();

    const source = audioContextRef.current.createBufferSource();
    source.buffer = buffer;
    source.connect(audioContextRef.current.destination);

    sourceNodeRef.current = source;
    source.onended = () => {
      setIsPlaying(false);
      setPlayingType(null);
    };
    
    source.start();
    setIsPlaying(true);
    setPlayingType(type);
  };

  const stopAudio = () => {
    if (sourceNodeRef.current) {
      try {
        sourceNodeRef.current.stop();
      } catch (e) {}
      sourceNodeRef.current = null;
    }
    setIsPlaying(false);
    setPlayingType(null);
  };

  const downloadAudio = () => {
    if (!processedBuffer) return;

    const wav = audioBufferToWav(processedBuffer);
    const blob = new Blob([wav], { type: 'audio/wav' });
    const url = URL.createObjectURL(blob);
    
    const a = document.createElement('a');
    a.href = url;
    a.download = `processed_${audioFile?.name.replace(/\.[^.]+$/, '') || 'audio'}.wav`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const audioBufferToWav = (buffer) => {
    const length = buffer.length * buffer.numberOfChannels * 2 + 44;
    const arrayBuffer = new ArrayBuffer(length);
    const view = new DataView(arrayBuffer);
    let pos = 0;

    const writeString = (str) => {
      for (let i = 0; i < str.length; i++) {
        view.setUint8(pos++, str.charCodeAt(i));
      }
    };

    const writeUint32 = (data) => {
      view.setUint32(pos, data, true);
      pos += 4;
    };

    const writeUint16 = (data) => {
      view.setUint16(pos, data, true);
      pos += 2;
    };

    writeString('RIFF');
    writeUint32(length - 8);
    writeString('WAVE');
    writeString('fmt ');
    writeUint32(16);
    writeUint16(1);
    writeUint16(buffer.numberOfChannels);
    writeUint32(buffer.sampleRate);
    writeUint32(buffer.sampleRate * 2 * buffer.numberOfChannels);
    writeUint16(buffer.numberOfChannels * 2);
    writeUint16(16);
    writeString('data');
    writeUint32(length - pos - 4);

    for (let i = 0; i < buffer.length; i++) {
      for (let channel = 0; channel < buffer.numberOfChannels; channel++) {
        const sample = buffer.getChannelData(channel)[i];
        const clampedSample = Math.max(-1, Math.min(1, sample));
        view.setInt16(pos, clampedSample < 0 ? clampedSample * 0x8000 : clampedSample * 0x7FFF, true);
        pos += 2;
      }
    }

    return arrayBuffer;
  };

  return (
    <div className="min-h-screen bg-gray-900 text-white p-4">
      <div className="max-w-[1600px] mx-auto">
        {/* Top Control Bar */}
        <div className="grid grid-cols-5 gap-2 mb-4">
          <label className="bg-blue-600 hover:bg-blue-700 px-6 py-3 rounded cursor-pointer flex items-center justify-center gap-2 transition shadow-lg">
            <Upload className="w-5 h-5" />
            <span className="font-semibold">LOAD FILE</span>
            <input type="file" className="hidden" accept="audio/*" onChange={handleFileUpload} />
          </label>
          
          <button
            onClick={() => playAudio('original')}
            disabled={!audioBuffer}
            className="bg-green-600 hover:bg-green-700 disabled:bg-gray-700 disabled:cursor-not-allowed px-6 py-3 rounded flex items-center justify-center gap-2 transition shadow-lg"
          >
            <Play className="w-5 h-5" />
            <span className="font-semibold">PLAY ORIGINAL</span>
          </button>
          
          <button
            onClick={() => playAudio('result')}
            disabled={!processedBuffer}
            className="bg-orange-600 hover:bg-orange-700 disabled:bg-gray-700 disabled:cursor-not-allowed px-6 py-3 rounded flex items-center justify-center gap-2 transition shadow-lg"
          >
            <Play className="w-5 h-5" />
            <span className="font-semibold">PLAY RESULT</span>
          </button>
          
          <button
            onClick={stopAudio}
            disabled={!isPlaying}
            className="bg-red-600 hover:bg-red-700 disabled:bg-gray-700 disabled:cursor-not-allowed px-6 py-3 rounded flex items-center justify-center gap-2 transition shadow-lg"
          >
            <Square className="w-5 h-5" />
            <span className="font-semibold">STOP</span>
          </button>
          
          <button
            onClick={downloadAudio}
            disabled={!processedBuffer}
            className="bg-purple-600 hover:bg-purple-700 disabled:bg-gray-700 disabled:cursor-not-allowed px-6 py-3 rounded flex items-center justify-center gap-2 transition shadow-lg"
          >
            <Download className="w-5 h-5" />
            <span className="font-semibold">SAVE FILE</span>
          </button>
        </div>

        {/* Status Bar */}
        <div className="bg-gray-800 px-4 py-2 rounded mb-4 flex items-center gap-2 border border-gray-700">
          <span className="text-green-400 font-bold">✓</span>
          <span className="text-sm">Status: <span className="text-gray-300">{status}</span></span>
        </div>

        {/* Process Button */}
        <button
          onClick={processAudio}
          disabled={!audioBuffer}
          className="w-full bg-green-500 hover:bg-green-600 disabled:bg-gray-700 disabled:cursor-not-allowed px-6 py-4 rounded mb-4 flex items-center justify-center gap-2 text-lg font-bold transition shadow-lg"
        >
          <Settings className="w-6 h-6" />
          PROCESS AUDIO
        </button>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-4">
          {/* Project 1: Distortion Meter */}
          <div className="bg-gray-800 rounded-lg p-5 border-2 border-gray-700">
            <h3 className="text-base font-bold mb-4 pb-2 border-b border-gray-600 text-gray-300">
              PROJECT 1: Distortion Meter
            </h3>
            
            <label className="flex items-center gap-2 mb-4 cursor-pointer hover:text-blue-400 transition">
              <input
                type="checkbox"
                checked={enableDistortion}
                onChange={(e) => setEnableDistortion(e.target.checked)}
                className="w-4 h-4"
              />
              <span className="text-sm">Enable Distortion Analysis</span>
            </label>

            <div className="mb-4 flex items-center justify-between">
              <label className="text-sm text-gray-400">Clip Level:</label>
              <input
                type="number"
                value={clipLevel}
                onChange={(e) => {
                  const val = parseFloat(e.target.value);
                  if (!isNaN(val)) setClipLevel(val);
                }}
                disabled={!enableDistortion}
                className="bg-gray-900 px-3 py-1.5 rounded disabled:opacity-50 border border-gray-600 text-sm text-right focus:outline-none focus:ring-1 focus:ring-blue-500 w-32"
                step="0.1"
                min="0"
                max="1"
              />
            </div>

            <div className="bg-gray-900 p-4 rounded border border-gray-700">
              <div className="flex items-center gap-2 mb-2">
                <div className="w-3 h-3 bg-purple-500 rounded"></div>
                <span className="text-xs text-gray-400">THD Result:</span>
              </div>
              <div className="text-3xl font-mono text-red-400 font-bold">{thdResult}</div>
            </div>
          </div>

          {/* Project 2: Bass Amplifier */}
          <div className="bg-gray-800 rounded-lg p-5 border-2 border-gray-700">
            <h3 className="text-base font-bold mb-4 pb-2 border-b border-gray-600 text-gray-300">
              PROJECT 2: Bass Amplifier
            </h3>
            
            <label className="flex items-center gap-2 mb-4 cursor-pointer hover:text-blue-400 transition">
              <input
                type="checkbox"
                checked={enableBass}
                onChange={(e) => setEnableBass(e.target.checked)}
                className="w-4 h-4"
              />
              <span className="text-sm">Enable Bass Boost</span>
            </label>

            <div className="mb-3 flex items-center justify-between">
              <label className="text-sm text-gray-400">LPF Cutoff (Hz):</label>
              <input
                type="number"
                value={lpfCutoff}
                onChange={(e) => {
                  const val = parseFloat(e.target.value);
                  if (!isNaN(val) && val > 0) setLpfCutoff(val);
                }}
                disabled={!enableBass}
                className="bg-gray-900 px-3 py-1.5 rounded disabled:opacity-50 border border-gray-600 text-sm text-right focus:outline-none focus:ring-1 focus:ring-green-500 w-32"
                min="20"
                max="2000"
                step="10"
              />
            </div>

            <div className="mb-3 flex items-center justify-between">
              <label className="text-sm text-gray-400">Filter Order:</label>
              <input
                type="number"
                value={filterOrder}
                onChange={(e) => {
                  const val = parseInt(e.target.value);
                  if (!isNaN(val) && val > 0) setFilterOrder(val);
                }}
                disabled={!enableBass}
                className="bg-gray-900 px-3 py-1.5 rounded disabled:opacity-50 border border-gray-600 text-sm text-right focus:outline-none focus:ring-1 focus:ring-green-500 w-32"
                min="1"
                max="50"
                step="1"
              />
            </div>

            <div className="mb-3">
              <div className="flex items-center justify-between mb-1">
                <label className="text-sm text-gray-400">Bass Gain:</label>
                <span className="text-white font-bold text-sm">{bassGain.toFixed(1)}</span>
              </div>
              <div className="bg-gray-900 p-3 rounded border border-gray-600">
                <input
                  type="range"
                  min="0"
                  max="40"
                  step="0.5"
                  value={bassGain}
                  onChange={(e) => setBassGain(parseFloat(e.target.value))}
                  disabled={!enableBass}
                  className="w-full disabled:opacity-50"
                />
                <div className="flex justify-between text-xs text-gray-500 mt-1">
                  <span>0</span>
                  <span>4</span>
                  <span>8</span>
                  <span>12</span>
                  <span>16</span>
                  <span>20</span>
                  <span>24</span>
                  <span>28</span>
                  <span>32</span>
                  <span>36</span>
                  <span>40</span>
                </div>
              </div>
            </div>
          </div>

          {/* Project 3: Echo Generator */}
          <div className="bg-gray-800 rounded-lg p-5 border-2 border-gray-700">
            <h3 className="text-base font-bold mb-4 pb-2 border-b border-gray-600 text-gray-300">
              PROJECT 3: Echo Generator
            </h3>
            
            <label className="flex items-center gap-2 mb-4 cursor-pointer hover:text-blue-400 transition">
              <input
                type="checkbox"
                checked={enableEcho}
                onChange={(e) => setEnableEcho(e.target.checked)}
                className="w-4 h-4"
              />
              <span className="text-sm">Enable Echo Effect</span>
            </label>

            <div className="mb-4 flex items-center justify-between">
              <label className="text-sm text-gray-400">Echo Delay (ms):</label>
              <input
                type="number"
                value={echoDelay}
                onChange={(e) => {
                  const val = parseInt(e.target.value);
                  if (!isNaN(val) && val >= 0) setEchoDelay(val);
                }}
                disabled={!enableEcho}
                className="bg-gray-900 px-3 py-1.5 rounded disabled:opacity-50 border border-gray-600 text-sm text-right focus:outline-none focus:ring-1 focus:ring-purple-500 w-32"
                min="0"
                max="2000"
                step="50"
              />
            </div>

            <div className="mb-3">
              <div className="flex items-center justify-between mb-1">
                <label className="text-sm text-gray-400">Echo Alpha:</label>
                <span className="text-white font-bold text-sm">{echoAlpha.toFixed(2)}</span>
              </div>
              <div className="bg-gray-900 p-3 rounded border border-gray-600">
                <input
                  type="range"
                  min="0"
                  max="1"
                  step="0.01"
                  value={echoAlpha}
                  onChange={(e) => setEchoAlpha(parseFloat(e.target.value))}
                  disabled={!enableEcho}
                  className="w-full disabled:opacity-50"
                />
                <div className="flex justify-between text-xs text-gray-500 mt-1">
                  <span>0</span>
                  <span>0.1</span>
                  <span>0.2</span>
                  <span>0.3</span>
                  <span>0.4</span>
                  <span>0.5</span>
                  <span>0.6</span>
                  <span>0.7</span>
                  <span>0.8</span>
                  <span>0.9</span>
                  <span>1</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Signal Visualization */}
        <div className="bg-gray-800 rounded-lg p-5 border-2 border-gray-700">
          <h3 className="text-lg font-bold mb-4 text-gray-200">Signal Visualization</h3>
          
          <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
            {/* Original Signal - Time Domain */}
            <div className="bg-gray-900 p-4 rounded border border-gray-700">
              <h4 className="text-sm font-semibold mb-3 text-gray-300">Original Signal - Time Domain</h4>
              <ResponsiveContainer width="100%" height={280}>
                <LineChart data={originalTimeData} margin={{ top: 5, right: 20, bottom: 20, left: 10 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                  <XAxis 
                    dataKey="time" 
                    stroke="#9ca3af" 
                    tick={{ fill: '#9ca3af', fontSize: 11 }}
                    label={{ value: 'Time (s)', position: 'insideBottom', offset: -10, fill: '#9ca3af', fontSize: 12 }} 
                  />
                  <YAxis 
                    stroke="#9ca3af" 
                    tick={{ fill: '#9ca3af', fontSize: 11 }}
                    label={{ value: 'Amplitude', angle: -90, position: 'insideLeft', fill: '#9ca3af', fontSize: 12 }} 
                    domain={[-0.25, 0.25]} 
                  />
                  <Tooltip 
                    contentStyle={{ backgroundColor: '#1f2937', border: '1px solid #374151', borderRadius: '4px', fontSize: '12px' }} 
                    labelStyle={{ color: '#9ca3af' }}
                  />
                  <Line type="monotone" dataKey="amplitude" stroke="#3b82f6" dot={false} strokeWidth={1.5} />
                </LineChart>
              </ResponsiveContainer>
            </div>

            {/* Processed Signal - Time Domain */}
            <div className="bg-gray-900 p-4 rounded border border-gray-700">
              <h4 className="text-sm font-semibold mb-3 text-gray-300">Processed Signal - Time Domain</h4>
              <ResponsiveContainer width="100%" height={280}>
                <LineChart data={processedTimeData.length > 0 ? processedTimeData : originalTimeData} margin={{ top: 5, right: 20, bottom: 20, left: 10 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                  <XAxis 
                    dataKey="time" 
                    stroke="#9ca3af" 
                    tick={{ fill: '#9ca3af', fontSize: 11 }}
                    label={{ value: 'Time (s)', position: 'insideBottom', offset: -10, fill: '#9ca3af', fontSize: 12 }} 
                  />
                  <YAxis 
                    stroke="#9ca3af" 
                    tick={{ fill: '#9ca3af', fontSize: 11 }}
                    label={{ value: 'Amplitude', angle: -90, position: 'insideLeft', fill: '#9ca3af', fontSize: 12 }} 
                    domain={[-0.25, 0.25]} 
                  />
                  <Tooltip 
                    contentStyle={{ backgroundColor: '#1f2937', border: '1px solid #374151', borderRadius: '4px', fontSize: '12px' }} 
                    labelStyle={{ color: '#9ca3af' }}
                  />
                  <Line type="monotone" dataKey="amplitude" stroke="#ef4444" dot={false} strokeWidth={1.5} />
                </LineChart>
              </ResponsiveContainer>
            </div>

            {/* Original - Frequency Spectrum */}
            <div className="bg-gray-900 p-4 rounded border border-gray-700">
              <h4 className="text-sm font-semibold mb-3 text-gray-300">Original - Frequency Spectrum</h4>
              <ResponsiveContainer width="100%" height={280}>
                <AreaChart data={originalFreqData} margin={{ top: 5, right: 20, bottom: 20, left: 10 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                  <XAxis 
                    dataKey="frequency" 
                    stroke="#9ca3af" 
                    tick={{ fill: '#9ca3af', fontSize: 11 }}
                    label={{ value: 'Frequency (Hz)', position: 'insideBottom', offset: -10, fill: '#9ca3af', fontSize: 12 }} 
                  />
                  <YAxis 
                    stroke="#9ca3af" 
                    tick={{ fill: '#9ca3af', fontSize: 11 }}
                    label={{ value: 'Magnitude (dB)', angle: -90, position: 'insideLeft', fill: '#9ca3af', fontSize: 12 }} 
                    domain={[-180, -20]} 
                  />
                  <Tooltip 
                    contentStyle={{ backgroundColor: '#1f2937', border: '1px solid #374151', borderRadius: '4px', fontSize: '12px' }} 
                    labelStyle={{ color: '#9ca3af' }}
                  />
                  <Area type="monotone" dataKey="magnitude" stroke="#3b82f6" fill="#3b82f688" strokeWidth={1.5} />
                </AreaChart>
              </ResponsiveContainer>
            </div>

            {/* Processed - Frequency Spectrum */}
            <div className="bg-gray-900 p-4 rounded border border-gray-700">
              <h4 className="text-sm font-semibold mb-3 text-gray-300">Processed - Frequency Spectrum</h4>
              <ResponsiveContainer width="100%" height={280}>
                <AreaChart data={processedFreqData.length > 0 ? processedFreqData : originalFreqData} margin={{ top: 5, right: 20, bottom: 20, left: 10 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                  <XAxis 
                    dataKey="frequency" 
                    stroke="#9ca3af" 
                    tick={{ fill: '#9ca3af', fontSize: 11 }}
                    label={{ value: 'Frequency (Hz)', position: 'insideBottom', offset: -10, fill: '#9ca3af', fontSize: 12 }} 
                  />
                  <YAxis 
                    stroke="#9ca3af" 
                    tick={{ fill: '#9ca3af', fontSize: 11 }}
                    label={{ value: 'Magnitude (dB)', angle: -90, position: 'insideLeft', fill: '#9ca3af', fontSize: 12 }} 
                    domain={[-180, -20]} 
                  />
                  <Tooltip 
                    contentStyle={{ backgroundColor: '#1f2937', border: '1px solid #374151', borderRadius: '4px', fontSize: '12px' }} 
                    labelStyle={{ color: '#9ca3af' }}
                  />
                  <Area type="monotone" dataKey="magnitude" stroke="#ef4444" fill="#ef444488" strokeWidth={1.5} />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>

        {/* Current Parameters */}
        <div className="bg-gray-800 rounded-lg p-5 mt-4 border-2 border-gray-700">
          <h3 className="text-lg font-bold mb-4 text-gray-200">Current Parameters</h3>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="bg-gray-900 p-4 rounded border border-gray-700">
              <div className="flex items-center gap-2 mb-2">
                <div className="w-3 h-3 bg-blue-500 rounded"></div>
                <span className="text-xs font-semibold text-blue-400">SAMPLE RATE:</span>
              </div>
              <div className="text-lg font-mono text-white">{audioBuffer ? `${audioBuffer.sampleRate} Hz` : 'N/A'}</div>
            </div>
            
            <div className="bg-gray-900 p-4 rounded border border-gray-700">
              <div className="flex items-center gap-2 mb-2">
                <div className="w-3 h-3 bg-red-500 rounded"></div>
                <span className="text-xs font-semibold text-red-400">DISTORTION SETTINGS:</span>
              </div>
              <div className="text-sm text-gray-300">
                {enableDistortion ? `Enabled (Clip=${clipLevel})` : 'Disabled'}
              </div>
            </div>
            
            <div className="bg-gray-900 p-4 rounded border border-gray-700">
              <div className="flex items-center gap-2 mb-2">
                <div className="w-3 h-3 bg-green-500 rounded"></div>
                <span className="text-xs font-semibold text-green-400">BASS BOOST SETTINGS:</span>
              </div>
              <div className="text-sm text-gray-300">
                {enableBass ? `Enabled (Gain=${bassGain}dB)` : 'Disabled'}
              </div>
            </div>
            
            <div className="bg-gray-900 p-4 rounded border border-gray-700">
              <div className="flex items-center gap-2 mb-2">
                <div className="w-3 h-3 bg-purple-500 rounded"></div>
                <span className="text-xs font-semibold text-purple-400">ECHO SETTINGS:</span>
              </div>
              <div className="text-sm text-gray-300">
                {enableEcho ? `Enabled (${echoDelay}ms)` : 'Disabled'}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}