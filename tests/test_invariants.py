import json
import pytest
from curry import test_curry_properties

def test_base29_involution():
    passed, msg = test_curry_properties.test_involution_z29()
    assert passed, msg

def test_affine_reversibility():
    passed, msg = test_curry_properties.test_affine_round_trip()
    assert passed, msg

def test_sacred_primes():
    passed, msg = test_curry_properties.test_gematria_primes()
    assert passed, msg

def test_stream_reversal():
    passed, msg = test_curry_properties.test_reversal_involution()
    assert passed, msg
