
import inspect, functools

def extract_args(func):
    return list(inspect.signature(func).parameters.values())

class Lazy:
    def __init__(self, fn):
        self._fn = fn
        self._obj = None

    def __getattr__(self, name):
        if self._obj is None:
            self._obj = self._fn()
        return getattr(self._ensure(), name)
