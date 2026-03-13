"""Tests for output normalization logic."""

from __future__ import annotations

import pytest

from block2python.contracts import OutputNormalization
from block2python.judge.normalization import normalize_output


class TestNormalizeOutput:
    """Test output normalization with different policies."""

    def test_strip_trailing_whitespace(self):
        policy = OutputNormalization(
            strip_trailing_whitespace=True,
            normalize_newlines_to_lf=False,
            strip_trailing_newline=False,
        )
        assert normalize_output("hello   \nworld  \n", policy) == "hello\nworld\n"

    def test_normalize_newlines_to_lf(self):
        policy = OutputNormalization(
            strip_trailing_whitespace=False,
            normalize_newlines_to_lf=True,
            strip_trailing_newline=False,
        )
        assert normalize_output("hello\r\nworld\r\n", policy) == "hello\nworld\n"
        assert normalize_output("hello\rworld\r", policy) == "hello\nworld\n"

    def test_strip_trailing_newline(self):
        policy = OutputNormalization(
            strip_trailing_whitespace=False,
            normalize_newlines_to_lf=False,
            strip_trailing_newline=True,
        )
        assert normalize_output("hello\n\n", policy) == "hello"

    def test_combined_normalization(self):
        policy = OutputNormalization(
            strip_trailing_whitespace=True,
            normalize_newlines_to_lf=True,
            strip_trailing_newline=True,
        )
        assert normalize_output("hello  \r\nworld  \r\n\n", policy) == "hello\nworld"

    def test_no_normalization(self):
        policy = OutputNormalization(
            strip_trailing_whitespace=False,
            normalize_newlines_to_lf=False,
            strip_trailing_newline=False,
        )
        original = "hello  \r\nworld  \r\n\n"
        assert normalize_output(original, policy) == original
