.pragma library
var name_map = [

//"Pair of classic waveforms" : 
        {"harmonics": "detuning", 
        "timbre": "variable square", 
        "morph": "variable saw" , 
        "aux": "sum of two waveforms"},

//"Waveshaping Oscillator" : 
        {"harmonics": "waveshaper waveform", 
        "timbre": "wavefolder amount", 
        "morph": "waveform asymmetry" , 
        "aux": "wavefolder curve variant"},

//"Two operator FM" : 
        {"harmonics": "frequency ratio", 
        "timbre": "modulation index", 
        "morph": "feedback" , 
        "aux": "sub-oscillator"},

//"Granular formant oscillator" : 
        {"harmonics": "frequency ratio", 
        "timbre": "formant frequency", 
        "morph": " formant width and shape" , 
        "aux": "simulation of filtered waveforms"},

//"Harmonic oscillator" : 
        {"harmonics": "bumps", 
        "timbre": "most prominent harmonic", 
        "morph": "bump shape" , 
        "aux": "harmonics subset"},
     
//"Wavetable oscillator" : 
        {"harmonics": " bank selection", 
        "timbre": "row index", 
        "morph": "column index" , 
        "aux": "low-fi output"},    
        
//"Chords" : 
        {"harmonics": "chord type", 
        "timbre": "chord inversion and transposition", 
        "morph": " waveform" , 
        "aux": "root note"},           

//"Vowel and speech synthesis" : 
        {"harmonics": "crossfade", 
        "timbre": "species selection", 
        "morph": "phoneme or word segment selection" , 
        "aux": "unfiltered vocal cords’ signal"},

//"Granular cloud" : 
        {"harmonics": "pitch randomization", 
        "timbre": "grain density", 
        "morph": " grain duration and overlap" , 
        "aux": "sine wave oscillator variant"},        

//"Filtered noise" : 
        {"harmonics": "filter response", 
        "timbre": "clock frequency", 
        "morph": "filter resonance" , 
        "aux": "band-pass filter variant"}, 

//"Particle noise" : 
        {"harmonics": "frequency randomization", 
         "timbre": "particle density", 
         "morph": "filter type" , 
         "aux": "raw dust noise"},

//"Inharmonic string modeling" : 
        {"harmonics": "inharmonicity", 
        "timbre": " excitation brightness and dust density", 
        "morph": "decay time" , 
        "aux": "raw exciter signal"}, 

//"Modal resonator" : 
        {"harmonics": "attack sharpness & overdrive", 
        "timbre": " excitation brightness and dust density", 
        "morph": "decay time" , 
        "aux": "raw exciter signal"}, 

//"Analog bass drum model" : 
        {"harmonics": "inharmonicity", 
        "timbre": "brightness", 
        "morph": "decay time" , 
        "aux": "shape"}, 

// "Analog snare drum model" : 
        {"harmonics": "harmonic and noisy balance", 
        "timbre": "brightnemode balance", 
        "morph": "decay time" , 
        "aux": "shape"}, 

// "Analog hi-hat model" : 
        {"harmonics": "noise balance", 
        "timbre": "high-pass filter cutoff", 
        "morph": "decay time" , 
        "aux": "shape"}, 
];
