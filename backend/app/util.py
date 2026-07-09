"""Small request-validation helpers shared by the blueprints."""
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
