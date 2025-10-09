
import inspect, functools

def extract_args(func):
    return list(inspect.signature(func).parameters.values())

class Lazy:
    def __init__(self, factory):
        object.__setattr__(self, "_factory", factory)
        object.__setattr__(self, "_obj", None)

    def _object(self):
        obj = object.__getattribute__(self, "_obj")
        if obj is None:
            obj = object.__getattribute__(self, "_factory")()
            object.__setattr__(self, "_obj", obj)
        return obj

    def __getattribute__(self, name):
        if name in ("_factory", "_obj", "_object", "__class__", "__dict__"):
            return object.__getattribute__(self, name)
        return getattr(self._object(), name)

    def __setattr__(self, name, value):
        setattr(self._object(), name, value)

    def __bool__(self):
        return bool(self._object())

    def __str__(self):
        return str(self._object())

    def __eq__(self, other):
        return self._object() == other

    def __repr__(self):
        return f"<Lazy {repr(self._object())}>"

    def __getattr__(self, name):
        return getattr(self._object(), name)
    
    def __call__(self, *args, **kwargs):
        return self._object()(*args, **kwargs)
