import json
import module_info

effect_type_maps = module_info.effect_type_maps

effect_prototypes_models_all = module_info.effect_prototypes_models_all

for k, v in effect_prototypes_models_all.items():
    n = 0
    for p in v["inputs"].values():
        if p[1] == "CVPort":
            n = n + 1
    effect_prototypes_models_all[k]["num_cv_in"] = n

effect_prototypes_models = {"beebo": {k:effect_prototypes_models_all[k] for k in effect_type_maps["beebo"].keys()}}

for k in effect_prototypes_models.keys():
    effect_prototypes_models[k]["input"] = {"inputs": {},
            "outputs": {"output": ["in", "AudioPort"]},
            "num_cv_in": 0,
            "controls": {}}
    effect_prototypes_models[k]["output"] = {"inputs": {"input": ["out", "AudioPort"]},
            "outputs": {},
            "num_cv_in": 0,
            "controls": {}}
    effect_prototypes_models[k]["midi_input"] = {"inputs": {},
            "outputs": {"output": ["in", "AtomPort"]},
            "num_cv_in": 0,
            "controls": {}}
    effect_prototypes_models[k]["midi_output"] = {"inputs": {"input": ["out", "AtomPort"]},
            "outputs": {},
            "num_cv_in": 0,
            "controls": {}}

class SetEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, set):
            return list(obj)
        return json.JSONEncoder.default(self, obj)

with open("qml/module_info.js", 'w') as outfile:
    outfile.write(".pragma library\nvar effectPrototypes = ")
    outfile.write(json.dumps(effect_prototypes_models["beebo"], cls=SetEncoder))
