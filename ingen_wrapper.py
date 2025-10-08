import ingen
from queue import Queue
import json
import queue
import time, re, io
import threading, subprocess
import traceback
import logging
import urllib.parse
import os.path
import random

connected = False
from static_globals import IS_REMOTE_TEST

ingen_started_lock = threading.Lock()
ingen_started = False

atom_AtomPort = "atom:AtomPort"
ingen_max_run_load = "ingen:maxRunLoad"
ingen_mean_run_load = "ingen:meanRunLoad"
ingen_min_run_load = "ingen:minRunLoad"
ingen_Arc = "ingen:Arc"
ingen_Block = "ingen:Block"
ingen_canvasX = "ingen:canvasX"
ingen_canvasY = "ingen:canvasY"
ingen_enabled = "ingen:enabled"
ingen_file = "ingen:file"
ingen_head = "ingen:head"
ingen_minRunLoad = "ingen:minRunLoad"
ingen_tail = "ingen:tail"
ingen_value = "ingen:value"
lv2_AudioPort = "lv2:AudioPort"
lv2_InputPort = "lv2:InputPort"
lv2_OutputPort = "lv2:OutputPort"
lv2_prototype = "lv2:prototype"
midi_binding = "midi:binding"
midi_controllerNumber = "midi:controllerNumber"
patch_Put = "patch:Put"
patch_Patch = "patch:Patch"
patch_Delete = "patch:Delete"
patch_Set = "patch:Set"
patch_body = "patch:body"
patch_property = "patch:property"
patch_subject = "patch:subject"
patch_value = "patch:value"
poly_assigned_footswitch = "http://polyeffects.com/ns/core#assigned_footswitch"
poly_looper_footswitch = "http://polyeffects.com/ns/core#looper_footswitch"
poly_spotlight = "http://polyeffects.com/ns/core#spotlight"
poly_physical_port = "http://polyeffects.com/ns/core#physical_port"
rdf_type = "rdf:type"
rdfs_comment = "rdfs:comment"
ir_url = "http://polyeffects.com/lv2/polyconvo#ir"


class ExceptionThread(threading.Thread):
    def __init__(self, *args, **kwargs):
        threading.Thread.__init__(self, *args, **kwargs)

    def run(self):
        try:
            if self._target:
                self._target(*self._args, **self._kwargs)
        except Exception:
            logging.error(traceback.format_exc())

q = Queue()
_FINISH = False
ui_queue = None
# to_delete = set()
# to_delete_lock = threading.Lock()

def get_timed_interruptable(q, timeout):
    stoploop = time.monotonic() + timeout - 1
    while time.monotonic() < stoploop:
        try:
            return q.get(timeout=1)  # Allow check for Ctrl-C every second
        except queue.Empty:
            pass
    # Final wait for last fraction of a second
    return q.get(timeout=max(0, stoploop + 1 - time.monotonic()))

def DestinationThread( ) :
    global ingen_started
    while True :
        if ingen_started == False:
            with ingen_started_lock:
                if ingen_started == False:
                    while not os.path.exists("/tmp/ingen.sock"):
                        time.sleep(0.1)
                    time.sleep(0.2)

                    # print("setting ingen remote server dest")
                    ingen.socket_connect()
                    ingen_started = True

        if _FINISH:
            return
        try:
            items = get_timed_interruptable(q, 1)
            func = items[0]
            args = items[1:]
            # print("sending args", args)
            func(*args)
            # print("sent")
        except queue.Empty:
            pass

def set_bypass(effect_id, active):
	# a patch:Set ;
	# patch:subject </main/digit_delay> ;
	# patch:property ingen:enabled ;
	# patch:value false .
    q.put((ingen.put, effect_id, "ingen:enabled "+ str(active).lower()))

def set_description(current_sub_graph, description):
    #ingen.set("/main/tone/output", "ingen:value", "0.8") 
    # ingen.set(port, "ingen:value", str(value))
    # q.put((ingen.set, current_sub_graph, "http://www.w3.org/2000/01/rdf-schema#comment", description))
    q.put((ingen.put, current_sub_graph+"/control", 'rdfs:comment """%s"""' % description))

def set_author(current_sub_graph, description):
    q.put((ingen.put, current_sub_graph+"/control", 'doap:maintainer """%s"""' % description))

def set_tags(current_sub_graph, description):
    q.put((ingen.put, current_sub_graph+"/control", 'doap:category """%s"""' % description))

def set_footswitch_control(effect_id, foot_switch):
    q.put((ingen.put, effect_id, '<http://polyeffects.com/ns/core#assigned_footswitch> """%s"""' % foot_switch))

def set_looper_footswitch(current_sub_graph, foot_switch):
    q.put((ingen.put, current_sub_graph+"/control", '<http://polyeffects.com/ns/core#looper_footswitch> """%s"""' % foot_switch))

def set_physical_port(effect_id, port):
    q.put((ingen.put, effect_id, '<http://polyeffects.com/ns/core#physical_port> """%s"""' % port))

def set_parameter_value(port, value):
    #ingen.set("/main/tone/output", "ingen:value", "0.8") 
    # ingen.set(port, "ingen:value", str(value))
    q.put((ingen.set, port, "http://drobilla.net/ns/ingen#value", str(value)))

def get_state(path):
    #ingen.set("/main/tone/output", "ingen:value", "0.8") 
    # ingen.set(port, "ingen:value", str(value))
    q.put((ingen.get, path))

def set_plugin_position(effect_id, x, y):
    q.put((ingen.put, effect_id, 'ingen:canvasX "%s"^^xsd:float; ingen:canvasY "%s"^^xsd:float' % (x, y)))

def add_plugin(effect_id, effect_url):
    # put /main/tone <http://drobilla.net/plugins/mda/Shepard>'
    # print("backend adding effect_id", effect_id)
    q.put((ingen.put, effect_id, 'ingen:canvasX "' + "{:.1f}".format(random.randint(-20, 50) + 900) + '''"^^xsd:float ;
    ingen:canvasY "''' + "{:.1f}".format(random.randint(-20, 50) + 150) + '''"^^xsd:float ;
    a ingen:Block ;
    lv2:prototype ''' + "<" + effect_url + ">"))

def add_sub_graph(effect_id):
    # put /main/tone <http://drobilla.net/plugins/mda/Shepard>'
    # print("backend adding sub_graph", effect_id)
    q.put((ingen.put_internal, effect_id, """ingen:enabled true ;
    ingen:polyphony "1"^^xsd:int ;
    a ingen:Graph"""
    ))

def midi_learn(port):
    q.put((ingen.set, port, "http://lv2plug.in/ns/ext/midi#binding", "<http://lv2plug.in/ns/ext/patch#wildcard>"))

def midi_set_cc(port, channel, in_cc):
    midi_forget(port)
    cc = channel << 8 | in_cc
    q.put((ingen.set, port, "http://lv2plug.in/ns/ext/midi#binding", f"""
        [
        a midi:Controller ;
        midi:controllerNumber "{cc}"^^xsd:int
        ]"""))


def midi_forget(port):
    q.put((ingen.patch, port, "midi:binding patch:wildcard", ""))

def spotlight_set(port, value):
    q.put((ingen.set, port, "http://polyeffects.com/ns/core#spotlight", f'"""{value}"""'))

def spotlight_remove(port):
    q.put((ingen.set, port, "http://polyeffects.com/ns/core#spotlight", f'"""0"""'))

def add_input(port_id, x, y):
    # put /main/left_in 'a lv2:InputPort ; a lv2:AudioPort'
    q.put((ingen.put, port_id, """ingen:canvasX "%s"^^xsd:float ;
    ingen:canvasY "%s"^^xsd:float ;
    a lv2:InputPort ; a lv2:AudioPort""" % (x, y)))

def add_output(port_id, x, y):
    q.put((ingen.put, port_id, """ingen:canvasX "%s"^^xsd:float ;
    ingen:canvasY "%s"^^xsd:float ;
    a lv2:OutputPort ; a lv2:AudioPort""" % (x, y)))

def add_midi_input(port_id, x, y):
    q.put((ingen.put, port_id, """ingen:canvasX "%s"^^xsd:float ;
    ingen:canvasY "%s"^^xsd:float ;
    atom:bufferType atom:Sequence ;
    lv2:name "MIDI In" ;
    a lv2:InputPort ; a atom:AtomPort""" % (x, y)))

def add_midi_input2(port_id, x, y):
    q.put((ingen.put, port_id, """ingen:canvasX "%s"^^xsd:float ;
    ingen:canvasY "%s"^^xsd:float ;
    atom:bufferType atom:Sequence ;
    lv2:name "MIDI In" ;
    a lv2:InputPort ; a atom:AtomPort""" % (x, y)))

def add_midi_output(port_id, x, y):
    q.put((ingen.put, port_id, """ingen:canvasX "%s"^^xsd:float ;
    ingen:canvasY "%s"^^xsd:float ;
    atom:bufferType atom:Sequence ;
    lv2:name "MIDI Out" ;
    a lv2:OutputPort ; a atom:AtomPort""" % (x, y)))

def add_midi_output2(port_id, x, y):
    q.put((ingen.put, port_id, """ingen:canvasX "%s"^^xsd:float ;
    ingen:canvasY "%s"^^xsd:float ;
    atom:bufferType atom:Sequence ;
    lv2:name "MIDI Out" ;
    a lv2:OutputPort ; a atom:AtomPort""" % (x, y)))

# def add_top_loop_extra_midi(port_id, x, y):
#     # print("extra midi adding, port_id", port_id, x, y)
#     q.put((ingen.put, port_id, """ingen:canvasX "%s"^^xsd:float ;
#     ingen:canvasY "%s"^^xsd:float ;
#     a lv2:OutputPort ; a lv2:AtomPort""" % (x, y)))

def add_loop_extra_midi(port_id, x, y):
    # print("extra midi adding, port_id", port_id, x, y)
    q.put((ingen.put, port_id, """ingen:canvasX "%s"^^xsd:float ;
    ingen:canvasY "%s"^^xsd:float ;
    atom:bufferType atom:Sequence ;
    lv2:name "loop_extra_midi" ;
    a lv2:OutputPort ; a atom:AtomPort""" % (x, y)))

def add_loop_midi_out(port_id, x, y):
    # print("extra midi adding, port_id", port_id, x, y)
    q.put((ingen.put, port_id, """ingen:canvasX "%s"^^xsd:float ;
    ingen:canvasY "%s"^^xsd:float ;
    atom:bufferType atom:Sequence ;
    lv2:name "loop_midi_out" ;
    a lv2:InputPort ; a atom:AtomPort""" % (x, y)))

def set_json(effect_id, file_name):
    effect_id = effect_id
    file_name = urllib.parse.quote(file_name)
    # print("setting json file", effect_id, file_name)
    body = """[
         a patch:Set ;
         patch:property <http://aidadsp.cc/plugins/aidadsp-bundle/rt-neural-generic#json>;
         patch:value <file://"""+ file_name + "> ]"
    q.put((ingen.set, effect_id+"/CONTROL", "http://drobilla.net/ns/ingen#activity", body))
    q.put((ingen.set, effect_id, "http://polyeffects.com/lv2/polyconvo#ir", "<"+file_name+">")) # for UI persist

def set_json_nam(effect_id, file_name):
    effect_id = effect_id
    file_name = urllib.parse.quote(file_name)
    # strip anything before audio, shouldn't get to here..
    n = file_name.find("/audio")
    file_name = file_name[n:]
    # print("setting json file", effect_id, file_name)
    body = """[
         a patch:Set ;
         patch:property <http://github.com/mikeoliphant/neural-amp-modeler-lv2#model>;
         patch:value <file://"""+ file_name + "> ]"
    q.put((ingen.set, effect_id+"/control", "http://drobilla.net/ns/ingen#activity", body))
    q.put((ingen.set, effect_id, "http://polyeffects.com/lv2/polyconvo#ir", "<"+file_name+">")) # for UI persist


def set_file(effect_id, file_name, is_cab, effect_type):
    effect_id = effect_id
    file_name = urllib.parse.quote(file_name[len("file://"):])
    print("$$$ setting file", effect_id, file_name, is_cab)
    if effect_type in ["quad_ir_reverb", "mono_cab", "stereo_reverb"]:
        body = """[
             a patch:Set ;
             patch:property <http://gareus.org/oss/lv2/zeroconvolv#ir>;
             patch:value <file://"""+ file_name + "> ]"
        q.put((ingen.set, effect_id+"/control", "http://drobilla.net/ns/ingen#activity", body))
        q.put((ingen.set, effect_id, "http://polyeffects.com/lv2/polyconvo#ir", "<"+file_name+">")) # for UI persist
    else:
        body = """[
             a patch:Set ;
             patch:property <http://polyeffects.com/lv2/polyconvo#ir>;
             patch:value <file://"""+ file_name + "> ]"
        q.put((ingen.set, effect_id+"/control", "http://drobilla.net/ns/ingen#activity", body))
        q.put((ingen.set, effect_id, "http://polyeffects.com/lv2/polyconvo#ir", "<"+file_name+">")) # for UI persist

def get_valid_filename(s):
    """
    Return the given string converted to a string that can be used for a clean
    filename. Remove leading and trailing spaces; convert other spaces to
    underscores; and remove anything that is not an alphanumeric, dash,
    underscore, or dot.
    >>> get_valid_filename("john's portrait in 2004.jpg")
    'johns_portrait_in_2004.jpg'
    """
    s = str(s).strip().replace(' ', '_')
    return re.sub(r'(?u)[^-\w.]', '', s)

def save_pedalboard(pedal_name, name, current_sub_graph):
    clean_filename = get_valid_filename(name)
    if len(clean_filename) > 0:
        q.put((ingen.copy, current_sub_graph, "file:///mnt/presets/"+pedal_name+"/"+clean_filename+".ingen"))
        # q.put((ingen.copy, "/main", "file:///mnt/presets/"+clean_filename+".ingen"))

def load_pedalboard(name, current_sub_graph):
    # print("loading pedalboard", name)
    q.put((ingen.copy, name, current_sub_graph))
    # q.put((ingen.copy, name, "/main"))

def set_broadcast(port, is_broadcast):
    # s.set("/main/plug/left_out", "http://drobilla.net/ns/ingen#broadcast", "true" if is_broadcast else "false")
    q.put((ingen.set, port, "http://drobilla.net/ns/ingen#broadcast", "true" if is_broadcast else "false"))

def remove_plugin(effect_id):
    # add to delete list, copies wait for delete
    # with to_delete_lock:
    #     to_delete.add(effect_id[6:])
    #     print("added to to delete", effect_id[6:])
    q.put((ingen.delete, effect_id))

def connect_port(src_port, target_port):
    # "connect /main/left_in /main/tone/left_in"
    # print("### connecting", src_port, target_port)
    q.put((ingen.connect, src_port, target_port))

def disconnect_port(src_port, target_port):
    q.put((ingen.disconnect, src_port, target_port))

def disconnect_plugin(effect_id):
    # print("############### disconnnecting plugin ", effect_id)
    q.put((ingen.disconnect_all, effect_id))

def set_midi_cc():
    pass

def set_bpm():
    pass

def get_parameter_value():
    pass


### ------------------------- recv from server

def ingen_recv_thread( ) :
    global ingen_started
    while True :
        if ingen_started == False:
            with ingen_started_lock:
                if ingen_started == False:
                    while not os.path.exists("/tmp/ingen.sock"):
                        time.sleep(0.1)
                    time.sleep(0.2)
                    ingen.socket_connect()
                    print("setting ingen remote server recv")
                    ingen_started = True


        if _FINISH:
            ingen._FINISH = True
            return
        r = ingen.recv()
        # print("recv in ingen_wrapper", r)
        # for s in r.split("\n\n"):
        #     if len(s) > 10:
        #         if not (len(s) < 80 and ("ingen:BundleEnd" in s or "ingen:BundleStart" in s) or "@prefix" in s):
        if len(r) > 0:
            # print("len is ", len(r), )
            # print (" to parse", r)
            bundle = {}
            try:
            # if True:
                with open("/tmp/ingen.json", "w") as f:
                    f.write(r)
                bundle = json.loads(r)

                for k, v in bundle.items():
                    parse_ingen(v)
            except Exception as e:
                print("!!! failed to parse json from ingen, tried to parse \n\n", r)
                print("!!!")
                print(e)
                logging.error(traceback.format_exc())



"""
sooperlooper:loop0_in_1
sooperlooper:loop0_out_1
"""

# on enabled / disable looper add / remove ports
connected_ports = set()
def connect_jack_port(port, x, y, physical_port):
    port = port.lstrip("ingen:")
    if port not in connected_ports:
            port_map = {"/main/out_1": "ingen:out_1 system:playback_3",
                    "/main/out_2": "ingen:out_2 system:playback_4",
                    "/main/out_3": "ingen:out_3 system:playback_6",
                    "/main/out_4": "ingen:out_4 system:playback_8",
                    "/main/out_5": "ingen:out_4 system:playback_8",
                    "/main/out_6": "ingen:out_4 system:playback_8",
                    "/main/out_7": "ingen:out_4 system:playback_8",
                    "/main/out_8": "ingen:out_4 system:playback_8",
                    "/main/in_1": "system:capture_2 ingen:in_1",
                    "/main/in_2": "system:capture_4 ingen:in_2",
                    "/main/in_3": "system:capture_3 ingen:in_3",
                    "/main/in_4": "system:capture_5 ingen:in_4",
                    "/main/in_5": "system:capture_5 ingen:in_4",
                    "/main/in_6": "system:capture_5 ingen:in_4",
                    "/main/midi_in": "ttymidi:MIDI_in ingen:midi_in",
                    "/main/midi_out": "ttymidi:MIDI_out ingen:midi_out",
                    "/main/control": "ttymidi:MIDI_in ingen:control",
                    "/main/loop_common_in_1": "ingen:loop_common_in_1 sooperlooper:common_in_1",
                    "/main/loop_common_in_2": "ingen:loop_common_in_2 sooperlooper:common_in_2",
                    "/main/loop_common_out_1": "sooperlooper:common_out_1 ingen:loop_common_out_1",
                    "/main/loop_common_out_2": "sooperlooper:common_out_2 ingen:loop_common_out_2",
                    "/main/loop_midi_out": "ingen:extra_midi sooperlooper:midi_in",
                    "/main/loop_extra_midi": "ingen:extra_midi sooperlooper:midi_in",
                    }
            # if connected_ports == set(port_map.keys()):
            #     all_connected = True
            # print("got port", port, x, y)
            if port in port_map:
                pass
                # connected_ports.add(port)
                # command = ["/usr/bin/jack_connect",  *port_map[port].split()]
                # if not IS_REMOTE_TEST:
                #     ret_var = subprocess.run(command)
            else:
                # check if it's a sub module io we need to connect
                port_suffix = port.rsplit("/", 1)[1]
                # print("got por not in port map", port, x, y, port_suffix)
                io_ports = ['in_1', 'in_2', 'in_3', 'in_4', "in_5", "in_6", 'out_1', 'out_2', 'out_3', 'out_4', 'out_5', 'out_6', 'out_7', 'out_8', "midi_in", "midi_out"]
                # XXX loop common in / out, loop 1 in loop 1 out etc
                if port_suffix in io_ports or "loop_common_" in port_suffix or "loop_extra_midi" in port_suffix or "loop_midi_out" in port_suffix:
                    plugin = ""
                    if port_suffix == "midi_in":
                        #connect to in
                        plugin = "midi_input"
                        connect_port("/main/"+port_suffix, port)
                    elif port_suffix == "midi_out":
                        plugin = "midi_output"
                        connect_port(port, "/main/"+port_suffix)
                    elif "loop_common_in" in port_suffix:
                        plugin = "loop_common_in"
                        connect_port(port, "/main/"+port_suffix)
                    elif "loop_common_out" in port_suffix:
                        plugin = "loop_common_out"
                        connect_port("/main/"+port_suffix, port)
                    elif "loop_extra_midi" in port_suffix:
                        plugin = "loop_extra_midi"
                        connect_port(port, "/main/loop_extra_midi")
                    elif "loop_midi_out" in port_suffix:
                        plugin = "loop_midi_out"
                        connect_port("/main/loop_midi_out", port)
                    elif "in" in port_suffix:
                        #connect to in
                        plugin = "input"
                        connect_port("/main/"+port_suffix, port)
                    else:
                        plugin = "output"
                        connect_port(port, "/main/"+port_suffix)
                    ui_queue.put(("add_plugin", port, plugin, x, y, True))
                else:
                    pass
                    # print("got port we don't know", port, x, y, physical_port)

def parse_value(v):
    r = v.split("^")[0].strip('"').strip("<>")
    # print("parsing value", v, r)
    return r

def ask(d, k, v):
    if k in d and v in d[k]:
        return True
    else:
        return False

def parse_ingen(to_parse):
    # try:
    # if True:
        # print("parsing", to_parse)
    m = to_parse
    # except:
        # print("parsing", to_parse)
        # print("###\n###\n###\nfailed to parse")
        # return
    if ask(m, "a", "patch:Put"):
        subject = m["patch:subject"][0]

        # print("### got put subject", subject)
        if "patch:body" in m:
            body = m["patch:body"]
            if body is None:
                return
            # print("### got put, body is ", body)

            if subject == "/engine":
                max_load = 0
                mean_load = 0
                min_load = 0
                send = False
                if ingen_max_run_load in body:
                    send = True
                    max_load = float(body[max_load][0])
                elif ingen_mean_run_load in body:
                    mean_load = float(body[mean_load][0])
                    send = True
                elif ingen_min_run_load in body:
                    min_load = float(body[min_load][0])
                    send = True
                # print("load subject", subject, max_load, mean_load, min_load)
                if send:
                    ui_queue.put(("dsp_load", max_load, mean_load, min_load))
            if rdfs_comment in body:
                value = body[rdfs_comment][0]
                ui_queue.put(("set_comment", value, subject))
            if poly_assigned_footswitch in body:
                value = body[poly_assigned_footswitch][0]
                ui_queue.put(("assign_footswitch", value, subject))
            if poly_looper_footswitch in body:
                value = body[poly_looper_footswitch][0]
                ui_queue.put(("looper_footswitch", value, subject))

            if ask(body, "a", ingen_Block):
                print("adding new block", "subject is", subject, "body is", body)
                # adding new block
                x = 0
                y = 0
                plugin = ""
                ir = None
                is_enabled = True
                # print("got a block, triples are ")
                if lv2_prototype in body:
                    plugin = body[lv2_prototype][0]
                if ingen_canvasY in body:
                    y = float(body[ingen_canvasY][0])
                if ingen_canvasX in body:
                    x = float(body[ingen_canvasX][0])
                if ir_url in body:
                    ir = body[ir_url][0]
                if ingen_enabled in body:
                    is_enabled = body[ingen_enabled][0] != "false"
                    print("## is enabled", is_enabled)
                # print("x", x, "y", y, "plugin", plugin, "subject", subject)
                ui_queue.put(("add_plugin", subject, plugin, x, y, is_enabled))
                if ir is not None:
                    ir = "file://" + ir
                    # print("#### ir file is ", ir)
                    ui_queue.put(("set_file", subject, ir))

            elif ingen_value in body:
                # setting value
                value = body[ingen_value][0]
                # print("has predicate value", value, "subject", subject, "body", body)
                ui_queue.put(("value_change", subject, value))
                if poly_spotlight in body:
                    value = body[poly_spotlight][0]
                    # print("has poly_spoltlight", subject, "value", value)
                    ui_queue.put(("spotlight", subject, str(value)))
                if midi_binding in body:
                    # print("midi binding predicate")
                    midi_s = m[midi_binding]
                    if midi_controllerNumber in midi_s:
                        try:
                            value = midi_s[midi_controllerNumber][0]
                            # print("midi learn parsed: value, ", int(str(value)))
                            ui_queue.put(("midi_learn", subject, int(str(value))))
                        except IndexError:
                            # bender etc are just an out of range CC number... 
                            # print("midi learn parsed: index error ")
                            ui_queue.put(("midi_learn", subject, int(256)))

            elif ask(body, "a", ingen_Arc):
                head = body[ingen_head][0]
                tail = body[ingen_tail][0]
                # print("##### \n\n ### \n arc head", head, "tail", tail)
                # ui_queue.put(("add_connection", head[7:], tail[7:]))
                ui_queue.put(("add_connection", head, tail))
            elif "a" in body and (lv2_AudioPort in body["a"] or atom_AtomPort in body["a"]):
                # setting value
                is_in = None
                is_audio = None
                is_midi = None
                # print("### got audioport or atomport_, subject", str(subject))
                x = None
                y = None
                physical_port = None
                port_types = body["a"]

                if lv2_OutputPort in port_types:
                    is_in = False
                elif lv2_InputPort in port_types:
                    is_in = True

                if lv2_AudioPort in port_types:
                    is_audio = True
                if atom_AtomPort in port_types:
                    is_midi = True

                if ingen_canvasY in body:
                    y = float(body[ingen_canvasY][0])
                if ingen_canvasX in body:
                    x = float(body[ingen_canvasX][0])
                if poly_physical_port in body:
                    physical_port = body[poly_physical_port][0]

                if is_in is not None and (is_audio or is_midi):
                    # print("### connecting jack port", is_in, "subject", subject)
                    # connect to jack port
                    if x is not None and y is not None:
                        connect_jack_port(subject, x, y, physical_port)
                else:
                    print("None! port is_in", is_in, "subject", subject)
            elif ingen_enabled in body:
                # setting value
                value = body[ingen_enabled][0]
                # print("in put enabled", subject, "value", value)
                # print("in put enabled", subject, "value", value, "b value", value != "false")
                # print("to parse", to_parse)
                ui_queue.put(("enabled_change", subject, str(value) != "false"))

    elif ask(m, "a", patch_Set):
        # print ("in patch_Set")
        subject = m[patch_subject][0]
        # print("set subject is", subject)
        if patch_property in m:
            if ingen_enabled in m[patch_property]:
                value = m[patch_value][0]
                print("in set enabled", subject, "value", value, "b value", bool(value))
                ui_queue.put(("enabled_change", subject, str(value) != "false"))
            if ingen_file in m[patch_property]:
                value = m[patch_value][0]
                print("in set enabled", subject, "value", value, "b value", bool(value))
                ui_queue.put(("pedalboard_loaded", subject, str(value)))
            if poly_spotlight in m[patch_property]:
                value = m[patch_value][0]
                # print("broadcast_update parsed", subject, "value", value)
                ui_queue.put(("spotlight", subject, str(value)))
            elif ingen_value in m[patch_property]:
                value = m[patch_value][0]
                # print("broadcast_update parsed", subject, "value", value)
                ui_queue.put(("broadcast_update", subject, float(str(value))))
            elif midi_binding in m[patch_property]:
                # print("midi learn parsed subject:", subject)
                try:
                    value = m[midi_controllerNumber][0]
                    # print("midi learn parsed: value, ", int(str(value)))
                    ui_queue.put(("midi_learn", subject, int(str(value))))
                except IndexError:
                    # bender etc are just an out of range CC number... 
                    ui_queue.put(("midi_learn", subject, int(256)))


    elif ask(m, "a", patch_Delete):
        body = None
        if "patch:body" not in m:
            subject = m[patch_subject][0]
            if subject is not None:
                # subject = str(subject)[7:]
                # subject = str(subject)[7:]
                # print("in delete subject", subject)
                ui_queue.put(("remove_plugin", subject))
        else:
            body = m["patch:body"]
            if body is None:
                return

            if ask(body, "a", ingen_Arc):
                head = ""
                tail = ""
                if ingen_head in body:
                    head = body[ingen_head][0]
                if ingen_tail in body:
                    tail = body[ingen_tail][0]
                if head and tail:
                    print("in remove arc head", head, "tail", tail)
                    # ui_queue.put(("remove_connection", head[7:], tail[7:]))
                    ui_queue.put(("remove_connection", head, tail))

    elif ask(m, "a", patch_Patch):
        # print ("in patch_Set")
        subject = m[patch_subject][0]
        # print("set subject is", subject)
        # print ("after get_value")
        if midi_binding in m:
            # print("midi unlearn parsed", subject)
            ui_queue.put(("midi_learn", subject, -1))



r_thread = None
def start_recv_thread(r_q):
    global ui_queue
    ui_queue = r_q
    global r_thread
    r_thread = ExceptionThread(target=ingen_recv_thread)
    r_thread.start()

s_thread = None
def start_send_thread():
    global s_thread
    s_thread = ExceptionThread(target=DestinationThread)
    s_thread.start()

# if not IS_REMOTE_TEST:
#     # server = "tcp://127.0.0.1:16180"
#     server = "unix:///tmp/ingen.sock"
# else:
#     # server = "tcp://192.168.1.139:16180"
#     server = "tcp://10.1.1.246:16180"
# server = "tcp://localhost:16180"
server = "unix:///tmp/ingen.sock"
ingen = ingen.Remote(server)

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
