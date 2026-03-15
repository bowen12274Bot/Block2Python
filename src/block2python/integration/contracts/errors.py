from __future__ import annotations


class IntegrationContractError(Exception):
    """Base class for integration contract failures."""


class IntegrationContractValidationError(IntegrationContractError):
    """Raised when serialized contract payloads are malformed."""
