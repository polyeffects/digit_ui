# properties.py

from functools import wraps

# from PyQt5.QtCore import QObject, pyqtProperty, pyqtSignal
# Or for PySide2:
from PySide2.QtCore import QObject, Property as pyqtProperty, Signal as pyqtSignal

class PropertyMeta(type(QObject)):
    """Lets a class succinctly define Qt properties."""
    def __new__(cls, name, bases, attrs):
        for key in list(attrs.keys()):
            attr = attrs[key]
            if not isinstance(attr, Property):
                continue

            types = {list: 'QVariantList', dict: 'QVariantMap'}
            type_ = types.get(attr.type_, attr.type_)

            notifier = pyqtSignal(type_)
            attrs[f'_{key}_changed'] = notifier
            attrs[key] = PropertyImpl(type_=type_, name=key, notify=notifier)

        return super().__new__(cls, name, bases, attrs)


class Property:
    """Property definition.

    Instances of this class will be replaced with their full
    implementation by the PropertyMeta metaclass.
    """
    def __init__(self, type_):
        self.type_ = type_


class PropertyImpl(pyqtProperty):
    """Property implementation: gets, sets, and notifies of change."""
    def __init__(self, type_, name, notify):
        super().__init__(type_, self.getter, self.setter, notify=notify)
        self.name = name

    def getter(self, instance):
        # print("getting value", f'_{self.name}', instance.__dict__.keys())
        return getattr(instance, f'_{self.name}')

    def setter(self, instance, value):
        signal = getattr(instance, f'_{self.name}_changed')

        # print("signal emitted", instance, f'_{self.name}', value)
        if type(value) in {list, dict}:
            value = make_notified(value, signal)

        setattr(instance, f'_{self.name}', value)
        # print("set attr signal emitted", instance, f'_{self.name}', value)
        signal.emit(value)


class MakeNotified:
    """Adds notifying signals to lists and dictionaries.

    Creates the modified classes just once, on initialization.
    """
    change_methods = {
        list: ['__delitem__', '__iadd__', '__imul__', '__setitem__', 'append',
               'extend', 'insert', 'pop', 'remove', 'reverse', 'sort'],
        dict: ['__delitem__', '__ior__', '__setitem__', 'clear', 'pop',
               'popitem', 'setdefault', 'update']
    }

    def __init__(self):
        if not hasattr(dict, '__ior__'):
            # Dictionaries don't have | operator in Python < 3.9.
            self.change_methods[dict].remove('__ior__')
        self.notified_class = {type_: self.make_notified_class(type_)
                               for type_ in [list, dict]}

    def __call__(self, seq, signal):
        """Returns a notifying version of the supplied list or dict."""
        notified_class = self.notified_class[type(seq)]
        notified_seq = notified_class(seq)
        notified_seq.signal = signal
        return notified_seq

    @classmethod
    def make_notified_class(cls, parent):
        notified_class = type(f'notified_{parent.__name__}', (parent,), {})
        for method_name in cls.change_methods[parent]:
            original = getattr(notified_class, method_name)
            notified_method = cls.make_notified_method(original, parent)
            setattr(notified_class, method_name, notified_method)
        return notified_class

    @staticmethod
    def make_notified_method(method, parent):
        @wraps(method)
        def notified_method(self, *args, **kwargs):
            result = getattr(parent, method.__name__)(self, *args, **kwargs)
            self.signal.emit(self)
            return result
        return notified_method


make_notified = MakeNotified()
