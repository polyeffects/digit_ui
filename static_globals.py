from enum import Enum, IntEnum
IS_REMOTE_TEST = False

pedal_types = Enum("pedals", """verbs
ample
""")

PEDAL_TYPE = pedal_types.ample # pedal_types.verbs
