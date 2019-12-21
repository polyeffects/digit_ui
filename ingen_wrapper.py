import ingen
from ingen import NS
from queue import Queue
import rdflib
import queue
import time
import threading
from io import StringIO as StringIO
import traceback
import logging


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
    while True :
        if _FINISH:
            break
        try:
            items = get_timed_interruptable(q, 1)
            func = items[0]
            args = items[1:]
            func(*args)
        except queue.Empty:
            pass

def set_bypass(effect_id, active):
	# a patch:Set ;
	# patch:subject </main/digit_delay> ;
	# patch:property ingen:enabled ;
	# patch:value false .
    effect_id = "/main/"+effect_id
    q.put((ingen.put, effect_id, "ingen:enabled "+ str(active).lower()))

def set_parameter_value(port, value):
    #ingen.set("/main/tone/output", "ingen:value", "0.8") 
    # ingen.set(port, "ingen:value", str(value))
    q.put((ingen.put, port, "ingen:value "+ str(value)))

def set_plugin_position(effect_id, x, y):
    q.put((ingen.put, "/main/"+effect_id, 'ingen:canvasX "%s"^^xsd:float; ingen:canvasY "%s"^^xsd:float' % (x, y)))

def add_plugin(effect_id, effect_url):
    # put /main/tone <http://drobilla.net/plugins/mda/Shepard>'
    q.put((ingen.put, "/main/"+effect_id, """ingen:canvasX "900.0"^^xsd:float ;
    ingen:canvasY "150.0"^^xsd:float ;
    a ingen:Block ;
    lv2:prototype """ + "<" + effect_url + ">"))

def add_input(port_id, x, y):
    # put /main/left_in 'a lv2:InputPort ; a lv2:AudioPort'
    q.put((ingen.put, "/main/"+port_id, """ingen:canvasX "%s"^^xsd:float ;
    ingen:canvasY "%s"^^xsd:float ;
    a lv2:InputPort ; a lv2:AudioPort""" % (x, y)))

def add_output(port_id, x, y):
    q.put((ingen.put, "/main/"+port_id, """ingen:canvasX "%s"^^xsd:float ;
    ingen:canvasY "%s"^^xsd:float ;
    a lv2:OutputPort ; a lv2:AudioPort""" % (x, y)))

def set_file(effect_id, file_name, is_cab):
    effect_id = "/main/"+effect_id
    if is_cab:
        q.put((ingen.put, effect_id, "patch:property <http://gareus.org/oss/lv2/convoLV2#impulse> ; patch:value <file://"+ file_name +">"))
    else:
        q.put((ingen.put, effect_id, "patch:property <http://polyeffects.com/lv2/polyconvo#ir> ; patch:value <file://"+ file_name +">"))

def save_pedalboard(name):
    q.put((ingen.copy, "/main/", "file:///home/loki/Documents/small_delay.ingen"))

def load_pedalboard(name):
    q.put((ingen.copy, "file:///home/loki/Documents/small_delay.ingen", "/main/"))

def remove_plugin(effect_id):
    q.put((ingen.delete, effect_id))

def connect_port(src_port, target_port):
    # "connect /main/left_in /main/tone/left_in"
    q.put((ingen.connect, src_port, target_port))

def disconnect_port(src_port, target_port):
    q.put((ingen.disconnect, src_port, target_port))

def set_midi_cc():
    pass

def set_bpm():
    pass

def get_parameter_value():
    pass


### ------------------------- recv from server

def ingen_recv_thread( ) :
    while True :
        if _FINISH:
            break
        r = ingen.recv()
        for s in r.split("\n\n"):
            if len(s) > 10:
                if not (len(s) < 80 and ("ingen:BundleEnd" in s or "ingen:BundleStart" in s)):
                    # print("len is ", len(s), )
                    a = ingen._get_prefixes_string() + s
                    parse_ingen(a)

def parse_ingen(to_parse):
    g = rdflib.Graph()
    g.parse(StringIO(to_parse), format="n3")
    # print("parsing", to_parse)
    for t in g.triples([None, NS.rdf.type, NS.patch.Put]):
        response = t[0]
        r_subject  = str(g.value(response, NS.patch.subject, None))[7:]
        subject  = r_subject[6:]
        body     = g.value(response, NS.patch.body, None)
        if body is not None:
            # p = list(g.triples([body, None, None]))
            if r_subject == "/engine":
                max_load = 0
                mean_load = 0
                min_load = 0
                send = False
                for p in g.triples([body, None, None]):
                    if p[1] == NS.ingen.maxRunLoad:
                        send = True
                        max_load = float(p[2])
                    elif p[1] == NS.ingen.meanRunLoad:
                        mean_load = float(p[2])
                        send = True
                    elif p[1] == NS.ingen.minRunLoad:
                        min_load = float(p[2])
                        send = True
                print("load subject", subject, max_load, mean_load, min_load)
                if send:
                    ui_queue.put(("dsp_load", max_load, mean_load, min_load))
            if (body, NS.rdf.type, NS.ingen.Block) in g:
                # print("response is", t[0], "subject is", subject, "body is", body)
                # adding new block
                x = 0
                y = 0
                plugin = ""
                for p in g.triples([body, None, None]):
                    if p[1] == NS.lv2.prototype:
                        plugin = str(p[2])
                    elif p[1] == NS.ingen.canvasY:
                        y = float(p[2])
                    elif p[1] == NS.ingen.canvasX:
                        x = float(p[2])
                print("x", x, "y", y, "plugin", plugin, "subject", subject)
                ui_queue.put(("add_plugin", subject, plugin, x, y))
            elif (body, NS.ingen.value, None) in g:
                # setting value
                value = str(g.value(body, NS.ingen.value, None))
                print("value", value, "subject", subject)
                ui_queue.put(("value_change", subject, value))
            elif (body, NS.rdf.type, NS.ingen.Arc) in g:
                head = ""
                tail = ""
                for p in g.triples([body, None, None]):
                    if p[1] == NS.ingen.head:
                        head = str(p[2])
                    elif p[1] == NS.ingen.tail:
                        tail = str(p[2])
                print("arc head", head, "tail", tail)
                ui_queue.put(("add_connection", head[7:], tail[7:]))
            elif (body, NS.lv2.name, None) in g:
                # setting value
                is_in = None
                is_audio = None
                # print("lv2.name", str(subject))
                for p in g.triples([body, NS.rdf.type, None]):
                    if p[2] == NS.lv2.OutputPort:
                        is_in = False
                    elif p[2] == NS.lv2.InputPort:
                        is_in = True
                    elif p[2] == NS.lv2.AudioPort:
                        is_audio = True
                if is_in is not None and is_audio:
                    print("port is_in", is_in, "subject", subject)
                else:
                    print("None! port is_in", is_in, "subject", subject)
            elif (body, NS.ingen.enabled, None) in g:
                # setting value
                value = g.value(body, NS.ingen.enabled, None)
                # print("in put enabled", subject, "value", value)
                print("in put enabled", subject, "value", value, "b value", bool(value))
                # print("to parse", to_parse)
                ui_queue.put(("enabled_change", subject, bool(value)))

    for t in g.triples([None, NS.rdf.type, NS.patch.Set]):
        response = t[0]
        subject  = str(g.value(response, NS.patch.subject, None))[13:]
        if (response, NS.patch.property, NS.ingen.value) in g:
            value = g.value(response, NS.patch.value, None)
            print("in set subject", subject, "value", value)
            ui_queue.put(("value_change", subject, value))
        elif (response, NS.patch.property, NS.ingen.enabled) in g:
            value = g.value(response, NS.patch.value, None)
            print("in set enabled", subject, "value", value, "b value", bool(value))
            ui_queue.put(("enabled_change", subject, bool(value)))
    for t in g.triples([None, NS.rdf.type, NS.patch.Delete]):
        response = t[0]
        body     = g.value(response, NS.patch.body, None)
        if body is None:
            subject  = g.value(response, NS.patch.subject, None)
            if subject is not None:
                subject = str(subject)[13:]
                print("in delete subject", subject)
                ui_queue.put(("remove_plugin", subject))
        elif (body, NS.rdf.type, NS.ingen.Arc) in g:
            head = ""
            tail = ""
            for p in g.triples([body, None, None]):
                if p[1] == NS.ingen.head:
                    head = str(p[2])
                elif p[1] == NS.ingen.tail:
                    tail = str(p[2])
            if head and tail:
                print("in remove arc head", head, "tail", tail)
                ui_queue.put(("remove_connection", head[7:], tail[7:]))

r_thread = None
def start_recv_thread(r_q):
    global ui_queue
    ui_queue = r_q
    global r_thread
    r_thread = ExceptionThread(target=ingen_recv_thread)
    r_thread.start()

def start_send_thread():
    t = ExceptionThread(target=DestinationThread)
    t.start()

import platform
if platform.system() == "Linux":
    # server = "tcp://127.0.0.1:16180"
    server = "unix:///tmp/ingen.sock"
else:
    server = "tcp://192.168.1.140:16180"
    # server = "tcp://192.168.1.139:16180"
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
