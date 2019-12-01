import ingen

def set_bypass():
    pass

def set_parameter_value(port, value):
    #ingen.set("/main/tone/output", "ingen:value", "0.8") 
    # ingen.set(port, "ingen:value", str(value))
    ingen.put(port, "ingen:value "+ str(value))

def add_plugin(effect_id, effect_url):
    # put /main/tone <http://drobilla.net/plugins/mda/Shepard>'
    ingen.put("/main/"+effect_id, "a ingen:Block ; lv2:prototype " + "<" + effect_url + ">")

def add_input(port_id):
    # put /main/left_in 'a lv2:InputPort ; a lv2:AudioPort'
    ingen.put("/main/"+port_id, "a lv2:InputPort ; a lv2:AudioPort")

def add_output(port_id):
    ingen.put("/main/"+port_id, "a lv2:OutputPort ; a lv2:AudioPort")

def set_file(effect_id, file_name, is_cab):
    if is_cab:
        ingen.put(effect_id, "patch:property <http://gareus.org/oss/lv2/convoLV2#impulse> ; patch:value <file://"+ file_name +">")
    else:
        ingen.put(effect_id, "patch:property <http://polyeffects.com/lv2/polyconvo#ir> ; patch:value <file://"+ file_name +">")


# """
# a patch:Set ;
# 	patch:property <http://gareus.org/oss/lv2/convoLV2#impulse> ;
# 	patch:value <file:///home/loki/.lv2/sisel4-ir.lv2/hall1-huge.flac> .
# """

	# a patch:Set ;"
	# patch:subject </main/Mono> ;
	# patch:property <http://lv2plug.in/ns/ext/presets#preset> ;
	# patch:value <http://gareus.org/oss/lv2/zeroconvolv/pset#noopMono> .
	# a patch:Put ;
	# patch:sequenceNumber "468"^^xsd:int ;
	# patch:subject <file:///home/loki/.lv2/Preset_Convolver_Stereo_test4.preset.lv2/test4.ttl> ;
	# patch:body [
	# 	lv2:appliesTo <http://gareus.org/oss/lv2/zeroconvolv#Stereo> ;
	# 	a <http://lv2plug.in/ns/ext/presets#Preset> ;
	# 	rdfs:label "test4"
	# ] .
	# a patch:Set ;
	# patch:subject </main/Stereo> ;
	# patch:property <http://lv2plug.in/ns/ext/presets#preset> ;
	# patch:value <http://gareus.org/oss/lv2/zeroconvolv/pset#SISEL4_hall1-small> .
# ingen.set("/main/Stereo", "http://lv2plug.in/ns/ext/presets#preset", "http://gareus.org/oss/lv2/zeroconvolv/pset#SISEL4_hall1-small")
# ingen.put("/main/Stereo", "patch:property <http://lv2plug.in/ns/ext/presets#preset> ; patch.value <http://gareus.org/oss/lv2/zeroconvolv/pset#SISEL4_hall1-small>")

	# a patch:Copy ;
	# patch:sequenceNumber "66"^^xsd:int ;
	# patch:subject </main/> ;
	# patch:destination <file:///home/loki/Documents/small_delay.ingen> .

def save_pedalboard(name):
    ingen.copy("/main/", "file:///home/loki/Documents/small_delay.ingen")

def load_pedalboard(name):
    ingen.copy("file:///home/loki/Documents/small_delay.ingen", "/main/")

def remove_plugin(effect_id):
    ingen.delete(effect_id)

def connect_port(src_port, target_port):
    # "connect /main/left_in /main/tone/left_in"
    ingen.connect(src_port, target_port)

def disconnect_port(src_port, target_port):
    ingen.disconnect(src_port, target_port)

def set_midi_cc():
    pass

def set_bpm():
    pass

def get_parameter_value():
    pass

server = "tcp://192.168.1.140:16180"
ingen = ingen.Remote(server)
