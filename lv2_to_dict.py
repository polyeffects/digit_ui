from rdfdict import RDFdict
import namespaces as ns
import rdflib
from pprint import pprint
import sys

ttl_file = sys.argv[1] #"/usr/lib/lv2/avw.lv2/lfo_tempo.ttl"
amp = rdflib.URIRef(sys.argv[2])
rdf_dict = RDFdict()
#we parse the file into the rdf_dict.graph which is a rdflib.ConjunctiveGraph
rdf_dict.parse(ttl_file, subject=amp)

#we populate rdf_dict with a structure
rdf_dict.structure()
#we replace the Literals with ints, floats and strings and the URIRefs according to the 
#namespaces we know about
rdf_dict.interpret(ns.lv2, ns.w3, ns.usefulinc, ns.kxstudio)

# [a for a in rdf_dict.values() if "lv2:symbol" in a and a["rdf:type"] == ["lv2:ControlPort", "lv2:InputPort"]]
# {sc["lv2:symbol"][0] : [sc["lv2:name"][0], sc["lv2:default"][0], sc["lv2:minimum"][0], sc["lv2:maximum"][0]]}
c = [a for a in rdf_dict.values() if "lv2:symbol" in a and set(a["rdf:type"]) == set(["lv2:ControlPort", "lv2:InputPort"])]
controls = dict([[sc["lv2:symbol"][0], [sc["lv2:name"][0], sc["lv2:default"][0], sc["lv2:minimum"][0], sc["lv2:maximum"][0]]] for sc in c])
i_a = [[a["lv2:symbol"][0], "AudioPort"] for a in rdf_dict.values() if "lv2:symbol" in a and set(a["rdf:type"]) == set(["lv2:AudioPort", "lv2:InputPort"])]
i_cv = [[a["lv2:symbol"][0], "CVPort"] for a in rdf_dict.values() if "lv2:symbol" in a and set(a["rdf:type"]) == set(["lv2:CVPort", "lv2:InputPort"])]
inputs = dict(i_a + i_cv)
outputs = dict([[a["lv2:symbol"][0], [b for b in a["rdf:type"] if b != "lv2:OutputPort"][0][4:]] for a in rdf_dict.values() if "lv2:symbol" in a and "lv2:OutputPort" in
    a["rdf:type"]])
out = {"inputs": inputs,
        "outputs": outputs,
        "controls": controls
        }
pprint(out)

