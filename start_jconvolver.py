import os.path, os, subprocess

reverb_conf_file = """
/cd "{0}"
#                in  out   partition    maxsize    density
/convolver/new    1    2         1024      100000       1.0
/input/name     1     In
/output/name    1     OutL
/output/name    2     OutR
#               in out  gain  delay  offset  length  chan      file
/impulse/read    1   1   0.5    0       0       0     1    "{1}"
/impulse/read    1   2   0.5    0       0       0     2    "{1}"
"""
cab_conf_file = """
/cd "{0}"
#                in  out   partition    maxsize    density
/convolver/new    1    1         256      2000       1.0
/input/name     1     In
/output/name    1     Out
#               in out  gain  delay  offset  length  chan      file
/impulse/read    1   1   0.5    0       0       0     1    "{1}"
"""

def generate_reverb_conf(ir_filename):
    with open("/tmp/reverb.conf", "w") as f:
        f.write(reverb_conf_file.format(os.path.dirname(ir_filename), os.path.basename(ir_filename)))
    subprocess.call("restart_reverb.sh", shell=True)

def generate_cab_conf(ir_filename):
    with open("/tmp/cab.conf", "w") as f:
        f.write(cab_conf_file.format(os.path.dirname(ir_filename), os.path.basename(ir_filename)))
    subprocess.call("restart_cab.sh", shell=True)
