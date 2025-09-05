#!/usr/bin/env python
# Ingen Python Interface
# Copyright 2012-2015 David Robillard <http://drobilla.net>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

import os
import re
import socket
import sys
import time

try:
    import StringIO.StringIO as StringIO
except ImportError:
    from io import StringIO as StringIO

_FINISH = False


class Interface:
    'The core Ingen interface'
    def put(self, subject, body):
        pass

    def put_internal(self, subject, body):
        pass

    def patch(self, subject, remove, add):
        pass

    def get(self, subject):
        pass

    def set(self, subject, key, value):
        pass

    def connect(self, tail, head):
        pass

    def disconnect(self, tail, head):
        pass

    def disconnect_all(self, subject):
        pass

    def delete(self, subject):
        pass

    def copy(self, subject, destination):
        pass

class Error(Exception):
    def __init__(self, msg, cause):
        Exception.__init__(self, '%s; cause: %s' % (msg, cause))

def lv2_path():
    path = os.getenv('LV2_PATH')
    if path:
        return path
    elif sys.platform == 'darwin':
        return os.pathsep.join(['~/Library/Audio/Plug-Ins/LV2',
                                '~/.lv2',
                                '/usr/local/lib/lv2',
                                '/usr/lib/lv2',
                                '/Library/Audio/Plug-Ins/LV2'])
    elif sys.platform == 'haiku':
        return os.pathsep.join(['~/.lv2',
                                '/boot/common/add-ons/lv2'])
    elif sys.platform == 'win32':
        return os.pathsep.join([
                os.path.join(os.getenv('APPDATA'), 'LV2'),
                os.path.join(os.getenv('COMMONPROGRAMFILES'), 'LV2')])
    else:
        return os.pathsep.join(['~/.lv2',
                                '/usr/lib/lv2',
                                '/usr/local/lib/lv2'])


class Remote(Interface):
    def __init__(self, uri='unix:///tmp/ingen.sock'):
        self.msg_id      = 1
        self.server_base = uri + '/'
        self.server_uri = uri
        # self.model       = rdflib.Graph()
        # self.ns_manager  = rdflib.namespace.NamespaceManager(self.model)
        # self.ns_manager.bind('server', self.server_base)


    def __del__(self):
        self.sock.close()

    def socket_connect(self):
        connected = False
        # for (k, v) in NS.__dict__.items():
        #     if not k.startswith("__"):
        #         self.ns_manager.bind(k, v)
        while not connected:
            try:
                if self.server_uri.startswith('unix://'):
                    self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                    self.sock.connect(self.server_uri[len('unix://'):])
                    connected = True
                elif self.server_uri.startswith('tcp://'):
                    self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                    parsed = re.split('[:/]', self.server_uri[len('tcp://'):])
                    addr = (parsed[0], int(parsed[1]))
                    self.sock.connect(addr)
                    connected = True
                else:
                    raise Exception('Unsupported server URI `%s' % self.server_uri)
            except (ConnectionError, FileNotFoundError) as e:
                time.sleep(0.2)


    def msgencode(self, msg):
        if sys.version_info[0] == 3:
            return bytes(msg, 'utf-8')
        else:
            return msg

    def uri_to_path(self, uri):
        path = uri
        if uri.startswith(self.server_base):
            return uri[len(self.server_base)-1:]
        return uri

    def recv(self):
        """Read from socket until a null terminator is received
        or split on \n\n
        """
        msg = u''
        while not _FINISH:
            try:
                self.sock.settimeout(2)
                chunk = self.sock.recv(1)
            except socket.timeout:
                continue

            if not chunk or chunk[0] == 0:  # End of transmission
                break
            # print(chunk.decode('utf-8'), end="")

            msg += chunk.decode('utf-8')
            # if msg[-2:] == '\n\n':
            #     break
        # print("msg is ", msg)

        return msg

    def send(self, msg):
        if type(msg) == list:
            msg = '\n'.join(msg)

        # print("****** sending", msg)
        # Send message to server
        # self.sock.sendall(self.msgencode(msg) + b'\r\n\0')
        # self.sock.sendall(self.msgencode(msg) + b'\0') # null on the end messes with sending!
        self.sock.sendall(self.msgencode(msg))

    def get(self, subject):
        return self.send('''
[]
	a patch:Get ;
	patch:subject <%s> .
''' % subject)

    def put(self, subject, body):
        return self.send('''
[]
	a patch:Put ;
	patch:subject <%s> ;
	patch:body [
%s
	] .
''' % (subject, body))

    def put_internal(self, subject, body):
        return self.send('''
[]
	a patch:Put ;
	patch:subject <%s> ;
    patch:context ingen:internalContext ;
	patch:body [
%s
	] .
''' % (subject, body))

    def patch(self, subject, remove, add):
        return self.send('''
[]
	a patch:Patch ;
	patch:subject <%s> ;
	patch:remove [
%s
	] ;
	patch:add [
%s
	] .
''' % (subject, remove, add))

    def set(self, subject, key, value):
        return self.send('''
[]
	a patch:Set ;
	patch:subject <%s> ;
	patch:property <%s> ;
    patch:value %s .
''' % (subject, key, value))

    def connect(self, tail, head):
        return self.send('''
[]
	a patch:Put ;
	patch:subject <%s> ;
	patch:body [
		a ingen:Arc ;
		ingen:tail <%s> ;
		ingen:head <%s> ;
	] .
''' % (os.path.commonprefix([tail, head]), tail, head))

    def disconnect(self, tail, head):
        return self.send('''
[]
	a patch:Delete ;
	patch:body [
		a ingen:Arc ;
		ingen:tail <%s> ;
		ingen:head <%s> ;
	] .
''' % (tail, head))

    def disconnect_all(self, subject):
        return self.send('''
[]
	a patch:Delete ;
	patch:subject </main> ;
	patch:body [
		a ingen:Arc ;
		ingen:incidentTo <%s>
	] .
''' % subject)

    def delete(self, subject):
        return self.send('''
[]
	a patch:Delete ;
	patch:subject <%s> .
''' % subject)

    def copy(self, subject, destination):
        return self.send('''
[]
	a patch:Copy ;
	patch:subject <%s> ;
	patch:destination <%s> .
''' % (subject, destination))
