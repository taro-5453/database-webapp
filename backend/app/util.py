"""Small request-validation helpers shared by the blueprints."""
from decimal import Decimal

from .db import ApiError


def int_field(data: dict, name: str, required: bool = True):
    """Pull an integer field out of a JSON body, 400 on bad/missing."""
    value = data.get(name)
    if value is None:
        if required:
            raise ApiError(400, f"{name} (integer) is required")
        return None
    if isinstance(value, bool) or not isinstance(value, int):
        raise ApiError(400, f"{name} must be an integer")
    return value


def str_field(data: dict, name: str, required: bool = True):
    value = data.get(name)
    if value is None or (isinstance(value, str) and not value.strip()):
        if required:
            raise ApiError(400, f"{name} is required")
        return None
    if not isinstance(value, str):
        raise ApiError(400, f"{name} must be a string")
    return value.strip()


def bool_field(data: dict, name: str):
    value = data.get(name)
    if not isinstance(value, bool):
        raise ApiError(400, f"{name} (true/false) is required")
    return value


def num_field(data: dict, name: str, required: bool = True):
    """JSON number -> Decimal, so DECIMAL(10,2) params stay exact."""
    value = data.get(name)
    if value is None:
        if required:
            raise ApiError(400, f"{name} (number) is required")
        return None
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ApiError(400, f"{name} must be a number")
    return Decimal(str(value))
