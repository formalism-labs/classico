
import inspect, functools

def extract_args(func):
    return list(inspect.signature(func).parameters.values())
