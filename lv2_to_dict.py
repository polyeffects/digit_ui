from rdfdict import RDFdict
import namespaces as ns
import rdflib
from pprint import pprint
import sys, subprocess

effect_type_map = { # "mono_compressor": "http://gareus.org/oss/lv2/darc#mono",
        # "stereo_compressor": "http://gareus.org/oss/lv2/darc#stereo",
        "phaser": "http://jpcima.sdf1.org/lv2/stone-phaser",
        "stereo_phaser": "http://jpcima.sdf1.org/lv2/stone-phaser-stereo",
        "j_chorus": "https://chrisarndt.de/plugins/ykchorus",
        # "thruzero_flange": "http://drobilla.net/plugins/mda/ThruZero",
        # "rotary": "http://gareus.org/oss/lv2/b_whirl#simple",
        # "attenuverter":"http://drobilla.net/plugins/blop/product",
        # "tempo_ratio": "http://drobilla.net/plugins/blop/ratio",
        }

def parse_ttl(ttl_file, uri, name="placeholder"):
    rdf_dict = RDFdict()
    #we parse the file into the rdf_dict.graph which is a rdflib.ConjunctiveGraph
    rdf_dict.parse(ttl_file, subject=uri)

    #we populate rdf_dict with a structure
    rdf_dict.structure()
    #we replace the Literals with ints, floats and strings and the URIRefs according to the 
    #namespaces we know about
    rdf_dict.interpret(ns.lv2, ns.w3, ns.usefulinc, ns.kxstudio)

    # [a for a in rdf_dict.values() if "lv2:symbol" in a and a["rdf:type"] == ["lv2:ControlPort", "lv2:InputPort"]]
    # {sc["lv2:symbol"][0] : [sc["lv2:name"][0], sc["lv2:default"][0], sc["lv2:minimum"][0], sc["lv2:maximum"][0]]}
    c = [a for a in rdf_dict.values() if "lv2:symbol" in a and (set(a["rdf:type"]).issuperset(set(["lv2:ControlPort", "lv2:InputPort"])) or
        set(a["rdf:type"]).issuperset(set(["lv2:CVPort", "lv2:InputPort"])))]
    controls = dict([[sc["lv2:symbol"][0], [sc["lv2:name"][0], sc["lv2:default"][0] if "lv2:default" in sc else 0.5, sc["lv2:minimum"][0] if "lv2:minimum" in sc else 0.0,
        sc["lv2:maximum"][0] if "lv2:maximum" in sc else 1.0]] for sc in c])
    i_a = [[a["lv2:symbol"][0], [a["lv2:name"][0], "AudioPort"]] for a in rdf_dict.values() if "lv2:symbol" in a and set(a["rdf:type"]).issuperset(set(["lv2:AudioPort",
        "lv2:InputPort"]))]
    i_cv = [[a["lv2:symbol"][0], [a["lv2:name"][0], "CVPort"]] for a in rdf_dict.values() if "lv2:symbol" in a and set(a["rdf:type"]).issuperset(set(["lv2:CVPort",
        "lv2:InputPort"]))]
    inputs = dict(i_a + i_cv)
    outputs = dict([[a["lv2:symbol"][0], [a["lv2:name"][0], [b for b in a["rdf:type"] if b != "lv2:OutputPort"][0][4:]]] for a in rdf_dict.values() if "lv2:symbol" in a and "lv2:OutputPort" in
        a["rdf:type"]])
    out = {"inputs": inputs,
            "outputs": outputs,
            "controls": controls
            }
    # print("'", name,"':", )
    # pprint(out)
    return out
def convert_all():
    a = {}
    for k, v in effect_type_map.items():
        c = 'lv2info '+v+ ' | grep ttl | grep -v manifest | grep -v modgui'
        file_name = subprocess.Popen(c, stdout=subprocess.PIPE, shell=True).stdout.read()[20:].strip()[7:].decode()
        print (file_name, v, k)
        b = parse_ttl(file_name, v, k)
        a[k] = b
    pprint(a)

if __name__ == "__main__":
    # ttl_file = sys.argv[1] #"/usr/lib/lv2/avw.lv2/lfo_tempo.ttl"
    # uri = rdflib.URIRef(sys.argv[2])
    # out = parse_ttl(ttl_file, uri)
    # pprint(out)
    convert_all()
