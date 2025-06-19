
import functools

#----------------------------------------------------------------------------------------------

def noctor(f):
    @functools.wraps(f)
    def wrapper(self, *args, **kwargs):
        raise TypeError(f"No default constrcutor for {self.__class__.__name__}")
    return wrapper

#----------------------------------------------------------------------------------------------

class CtorDecorator(object):
    def __init__(self, f):
        self.f = f

    def __get__(self, obj, klass=None):
        if klass is None:
            klass = type(obj)
        def ctor(*args, **kwargs):
            x = klass.__new__(klass)
            self.f(x, *args, **kwargs)
            return x
        def bound_ctor(*args, **kwargs):
            self.f(obj, *args, **kwargs)
        return ctor if obj is None else bound_ctor

ctor=CtorDecorator

#----------------------------------------------------------------------------------------------

def add_base_class(base_cls, *, base_first=True):
    """
    Decorator factory.
    `base_cls` – the class you want the decorated class to inherit from.
    `base_first` – if True:  (base_cls, original_cls, …)
                   if False: (original_cls, base_cls, …)
    """
    def decorator(original_cls):
        # Avoid work if it's already a subclass
        if issubclass(original_cls, base_cls):
            return original_cls

        # Choose the base‑class order that gives the MRO you need
        bases = ((base_cls,) + original_cls.__bases__) if base_first \
                else (original_cls.__bases__ + (base_cls,))

        # Build a *new* class object
        new_cls = type(
            original_cls.__name__,      # keep the same name
            bases,                      # new bases
            dict(original_cls.__dict__) # copy attributes/annotations
        )
        # Preserve metadata (optional but polite)
        new_cls.__module__   = original_cls.__module__
        new_cls.__qualname__ = original_cls.__qualname__
        new_cls.__doc__      = original_cls.__doc__
        return new_cls
    return decorator
