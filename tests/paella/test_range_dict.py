
import os
import sys
import pytest

HERE = os.path.dirname(__file__)
CLASSICO = os.path.abspath(os.path.join(HERE, "../.."))
sys.path.insert(0, CLASSICO)

from paella import RangeDict  # noqa

@pytest.fixture
def rd():
    return RangeDict({
        (0, 9): "low",
        range(10, 20): "medium",
        25: "point",
        (30,): "singleton",
    })

# Dict-like behavior
def test_dict(rd):
    assert len(rd) == 4
    assert 0 in rd
    assert 1 in rd
    assert 9 in rd
    assert (0, 9) in rd
    assert (15,) in rd
    assert (15, 16) in rd
    assert (15, 20) not in rd
    assert 100 not in rd

# Iteration like dict
def test_iteration(rd):
    vals = []
    for rng, val in rd.items():
        vals.append([rng, val])
    assert vals == [[(0, 9), 'low'], [(10, 19), 'medium'], [(25, 25), 'point'], [(30, 30), 'singleton']]

# Keys, values
def test_keys_values(rd):
    assert list(rd.keys()) == [(0, 9), (10, 19), (25, 25), (30, 30)]
    assert list(rd.values()) ==  ['low', 'medium', 'point', 'singleton']
