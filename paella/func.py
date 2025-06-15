
from functools import reduce

_sentinel = object()

def foldl(func, seq, z=_sentinel):
    if z is _sentinel:
        return reduce(func, seq)
    return reduce(func, z, seq)

def foldr(func, seq, z=_sentinel):
    if z is _sentinel:
        return reduce(lambda acc, x: func(x, acc), seq[::-1])
    return reduce(lambda acc, x: func(x, acc), seq[::-1], z)
