import subprocess
import pytest

def test_harn_prolog_verify():
    res = subprocess.run(
        ["swipl", "-q", "-s", "harn/verify.pl", "-g", "main", "-t", "halt"],
        capture_output=True,
        text=True
    )
    assert res.returncode == 0, f"swipl failed: {res.stderr}\n{res.stdout}"
    assert "Base-29 involution property validated." in res.stdout
    assert "Self-asserting candidate successfully rejected by P58-002." in res.stdout
    assert "All evidence and verification obligations successfully verified." in res.stdout

def test_harn_prolog_search_runner():
    for hyp in ["affine29", "reverse", "magic-square", "prime-sequence"]:
        res = subprocess.run(
            ["swipl", "-q", "-s", "harn/search.pl", "-g", f"run('{hyp}')", "-t", "halt"],
            capture_output=True,
            text=True
        )
        assert res.returncode == 0, f"Hypothesis {hyp} runner failed: {res.stderr}"
        assert f"Starting hypothesis runner for: {hyp}" in res.stdout
