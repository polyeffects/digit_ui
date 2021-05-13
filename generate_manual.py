import module_info
a = module_info.effect_prototypes_models_all
# sort by category and alphabetically
# state if pedal is Digit / Beebo or Both.
cat_effects = [[] for a in module_info.categories]
hidden_effects = ["mix_vca", "midi_input", "midi_output", "input", "output"]
effects = set(a.keys()) - set(hidden_effects)

def w_l(s):
    print(s)

def port_name(p):
    return {"CVPort":"CV", "AudioPort": "Audio", "AtomPort": "MIDI", "ControlPort": "Tempo"}[p]

for e in effects:
    cat_effects[a[e]["category"]].append(e)

for cat_num, cat_name in enumerate(module_info.categories):
    # print category name
    w_l("\\section{"+cat_name+"}\n")

    for k in sorted(cat_effects[cat_num]):
        e = a[k]
        pedal = ""
        if (k in module_info.effect_type_maps["digit"]) and (k in module_info.effect_type_maps["beebo"]):
            pedal = "Beebo And Digit."

        elif k in module_info.effect_type_maps["digit"]:
            pedal = "Digit."
        elif k in module_info.effect_type_maps["beebo"]:
            pedal = "Beebo."
        # print title, deescription, long description 
        w_l("\\subsection{"+k.replace("_", " ").title()+"}\n")
        w_l("Included in "+pedal+"\n")
        w_l(e["description"]+"\n")
        w_l(e["long_description"]+"\n")

# \begin{description}
# \item [Ant] \blindtext
# \item [Elephant] \blindtext
# \end{description}

        if len(e["inputs"]) > 0:
            # input, output, controls
            w_l("\\subsubsection{Inputs}")
            w_l("\\begin{description}")
            port_types = set([b[1] for b in e["inputs"].values()])
            for port_type in port_types:
                c = ", ".join([b[0].replace("_", " ").title() for b in sorted(e['inputs'].values()) if b[1] == port_type])
                w_l("\\item ["+port_name(port_type)+"] "+c)
            w_l("\\end{description}\n")

        if len(e["outputs"]) > 0:
            w_l("\\subsubsection{Outputs}")

            w_l("\\begin{description}")
            port_types = set([b[1] for b in e["outputs"].values()])
            for port_type in port_types:
                c = ", ".join([b[0].replace("_", " ").title() for b in sorted(e['outputs'].values()) if b[1] == port_type])
                w_l("\\item ["+port_name(port_type)+"] "+c)
            w_l("\\end{description}\n")

        if len(e["controls"]) > 0:
            w_l("\\subsubsection{Controls}")
            w_l("\\begin{itemize}")
            for b in sorted([c[0].replace("_", " ").title() for c in e['controls'].values()]):
                w_l("\\item "+b)
            w_l("\\end{itemize}\n")
