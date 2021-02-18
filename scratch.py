# need to expose getable elements to QML for each loop.
# add loop adds IO to ingen, node per loop?
# load patch with loops? USB flash stores loops?
# load patch adds additional loops if required but doesn't clear current loops. Does delete extra loops if send to master isn't on.
# preset needs to store looper state. Anything apart from number of loops? to start with no
# output has a physical output property attached to it, use to attach sub patch outs to actual jack outs. Default out 3 connects to 3 etc, if no property found.
# patch looper in outs need to connect to parent looper in out to jack
# loop cv LV2 module? takes in CV sends out OSC commands
# MIDI io modules have loop property, will connect to named loop or all. 

