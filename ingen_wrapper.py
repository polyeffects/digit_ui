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
