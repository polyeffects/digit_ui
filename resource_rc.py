# Resource object code (Python 3)
# Created by: object code
# Created by: The Resource Compiler for Qt version 5.15.3
# WARNING! All changes made in this file will be lost!

from PySide2 import QtCore

qt_resource_data = b"\
\x00\x00\x01+\
[\
Controls]\x0aStyle=\
poly_style\x0aFallb\
ackStyle=Materia\
l\x0a\x0a[Imagine]\x0aPat\
h=:/imagine-asse\
ts\x0aPalette\x5cText=\
#6affcd\x0aPalette\x5c\
ButtonText=#6aff\
cd\x0aPalette\x5cWindo\
wText=#6affcd\x0a\x0a[\
Material]\x0aFont\x5cF\
amily=Open Sans \
Light\x0aFont\x5c\x5c%2A%\
20PixelSize=20 *\
/\x0aFont\x5cWeight=12\
\x0a\x0a[Default]\x0aFont\
\x5cFamily=Open San\
s Light\x0aFont\x5cPix\
elSize=20\x0a\
"

qt_resource_name = b"\
\x00\x15\
\x08\x1e\x16f\
\x00q\
\x00t\x00q\x00u\x00i\x00c\x00k\x00c\x00o\x00n\x00t\x00r\x00o\x00l\x00s\x002\x00.\
\x00c\x00o\x00n\x00f\
"

qt_resource_struct = b"\
\x00\x00\x00\x00\x00\x02\x00\x00\x00\x01\x00\x00\x00\x01\
\x00\x00\x00\x00\x00\x00\x00\x00\
\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\
\x00\x00\x01s\xa4\x18\x7f\x0d\
"

def qInitResources():
    QtCore.qRegisterResourceData(0x03, qt_resource_struct, qt_resource_name, qt_resource_data)

def qCleanupResources():
    QtCore.qUnregisterResourceData(0x03, qt_resource_struct, qt_resource_name, qt_resource_data)

qInitResources()
