This confusingly named repo is the UI code for Beebo & Hector. 

The UI is based on QML / QT and using python as the wrapper. The UI communicates with a plugin host (Ingen) that hosts the actual DSP LV2 plugins that are in other repos.

To develope for Beebo / Hector, there is show_single_widget.py that allows you to debug a single widget locally or on the pedal. The current enviroment (Post 400 update) runs on X11 and so it's easy to SSH in and change stuff. 

To SSH into Beebo / Hector, the password is temppwd, user is debian. You can add your own publickey to make this easier to login. To restart the frontend, first kill the running one, and shut down the running Ingen (it doesn't currently cope with the frontend restarting).

To start ingen: 

```
/usr/bin/ingen -e -p 3 -a /home/debian/start_up.ingen
```

add -d to see more of what is going on

to start frontend

```
cd /home/debian/UI
export DISPLAY=:0.0
/usr/bin/python3 show_widget.py
```

If you add a new LV2 module, you'll need to regenerate the cached info the UI uses, 

```
python3 effect_proto_to_js.py
```

By default the enviroment is read only, using an overlay. To write stuff that'll survive reboot, you'll need to use overlayroot-chroot, or cahnge the start up stuff to start in read write. To get a read / write bash prompt, 

```
sudo overlayroot-chroot /bin/bash
```

You can install packages via apt but be warned that any important packages are usually built from source and just installed in prefix=/usr it's an embedded system.

All code where I've forgot to mention it is GPL.
