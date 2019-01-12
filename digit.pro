TEMPLATE = app
TARGET = digit
QT += quick quickcontrols2

SOURCES += \
    digit.cpp

RESOURCES += \
    icons/icons.qrc \
    imagine-assets/imagine-assets.qrc \
    qml/qml.qrc \
    qtquickcontrols2.conf

target.path = D:/git_repos/polydigit/UI
INSTALLS += target

DISTFILES += \
    qtquickcontrols2.conf
