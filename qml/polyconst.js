.pragma library
var audio_color = "#53A2FD";
var cv_color = "#80FFE8";
var control_color = "#AC8EFF";
var midi_color = "#FFD645";
var background_color = "#000000";
var outline_color = "#4c4c4c"; 
var poly_pink = "#FFA9EC";
var poly_blue = "#53A2FD";
var poly_green = "#80FFE8";
var poly_yellow = "#FFD645";
var poly_purple = "#AC8EFF";
var loopler_purple = "#FFA9EC";
var poly_dark_grey = "#282828";
var poly_very_dark_grey = "#151515";
var poly_grey = "#323232";
var left_col = 130; 
var note_names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B", "C"]
var port_color_map = {"AudioPort": audio_color, "CVPort": cv_color, 
    "ControlPort": control_color, "AtomPort": midi_color};
var port_display_name = {"AudioPort": "AUDIO", "CVPort": "CV", 
    "ControlPort": "TEMPO", "AtomPort": "MIDI"};
var rainbow = ["#FF2C6B", "#FF7B8B", "#FF8540", "#FF9E45", "#FFD645", "#FFF84E", "#B1FF81", "#3ED279", "#4CCBC5", "#80FFE8", "#5CE2FF", "#00B2FF", "#74CBFC", "#2077EE", "#AC8EFF", "#E680FF", "#FF75D0"];
var short_rainbow = ["#80FFE8", "#53A2FD", "#FF75D0", "#FFC045", "#FF9E45"];
var longer_rainbow = ["#53A2FD", "#AC8EFF", "#FF75D0", "#FF7B8B", "#FF9E45", "#FFD645", "#B1FF81", "#4CCBC5", "#80FFE8", "74CBFC"];
var loopler_rainbow = ["#FF75D0", "#FF7B8B", "#FF6464", "#FF8540", "#FFD645", "#FFF84E", "#C3FF76", "#20FF79", "#2DFFC0", "#80FFE8", "#5CE2FF", "#53A2FD", "#AC8EFF", "#E680FF", "#FF2BBF"];

var help = {"select": "Tap or add a module, drag to move. HOLD TO CONNECT.", "connect_to": "Advanced connect. You should use multi touch instead. Tap a module to connect to", "connect_from": "Advanced connect. You should use multi touch instead. Tap a module to connect from", "sliders_detail": "Tap the eye to see more. Tapping a slider assigns it to the knobs.", "sliders": "Hold dots and press slider for more.", 
    "delay_detail": "Milliseconds doesn't reflect tap tempo", 
    "eq_detail": "Drag bands",
    "hold": "Now tap the module to you want connect to, while holding this one",
    "reverb_detail": "Tap to choose IR. Up button moves up a folder.",
    "move": "Drag a module to move it. Hold and tap another module to connect"}
