import module_info
import subprocess
a = module_info.effect_type_maps["beebo"]
# sort by category and alphabetically
# state if pedal is Digit / Beebo or Both.
hidden_effects = ["mix_vca", "midi_input", "midi_output", "input", "output", "loop_common_in", "loop_common_out",
        "foot_switch_a","foot_switch_b","foot_switch_c","foot_switch_d","foot_switch_e", ]
effects_k = set(a.keys()) - set(hidden_effects)

for k in sorted(effects_k):
    if "clouds" in a[k]:
        print("# calling ", k)
        subprocess.call("/usr/bin/lv2bench "+a[k], shell=True)
