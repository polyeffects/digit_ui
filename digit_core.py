# 26 total effect slots? 
# delay 1-4
# reverb
# cab
# effects 1-4 per delay & reverb

#    
from pluginsmanager.banks_manager import BanksManager
from pluginsmanager.observer.mod_host.mod_host import ModHost
from pluginsmanager.model.pedalboard import Pedalboard
from pluginsmanager.model.connection import Connection
from pluginsmanager.model.lv2.lv2_effect_builder import Lv2EffectBuilder
from pluginsmanager.model.system.system_effect import SystemEffect

# connect to mod host and load plugins
manager = BanksManager()

bank = Bank('Bank 1')
manager.append(bank)
mod_host = ModHost('localhost')
mod_host.connect()
manager.register(mod_host)
pedalboard = Pedalboard('Digit')
bank.append(pedalboard)
mod_host.pedalboard = pedalboard

builder = Lv2EffectBuilder()
delays = []
delays[0] = builder.build("http://drobilla.net/plugins/mda/Delay")
reverb = builder.build('http://drobilla.net/plugins/fomp/reverb')
# cab
# load mixer LV2

pedalboard.append(delay)
pedalboard.append(reverb)

# connect outputs
from pluginsmanager.jack.jack_client import JackClient
client = JackClient()
sys_effect = SystemEffect('system', ['capture_1', 'capture_2', "capture_3, capture_4"],
        ['playback_1', 'playback_2', 'playback_3', 'playback_4'])


## on ui knob change, set value in lv2
# def ui_knob_change(value):
    # knob is zero to 1, map to pedal range 
    #fuzz.params[0].minimum / fuzz.params[0].maximum
    #fuzz.params[0].value

# 4 out, delay, reverb, cab
# 4 in, delay, reverb, cab

#
# fuzz.toggle()
# or
# fuzz.active = not fuzz.active

# mixer points
# effects on wet path dry option later
# delay wet to other delay
# delay wet to [reverb .... 
# delay post to
# one effect is send?


# delay 1 wet to delay 2,3,4. Reverb, output 1,2,3,4
# collapsable mixer? only 1->1 shown?
# delay 1 post to delay 2,3,4. Reverb, output 1,2,3,4


# tape / tube, filter, eq, flange, bit crush


# cv mixer


# calculate tap tempo then
# set transport state


