"""
ChatOps bot permission tiers for Day 5.

Read-only queries được phép tự động.
Write/destructive actions cần human approval.
"""
from typing import Literal

PermissionTier = Literal["read", "write", "destructive"]

WRITE_KEYWORDS = [
    "scale",
    "restart",
    "deploy",
    "update",
    "rollback",
    "roll back",
    "apply",
]
DESTRUCTIVE_KEYWORDS = [
    "delete",
    "drain",
    "shutdown",
    "terminate",
    "destroy",
]


def get_permission_tier(question: str) -> PermissionTier:
    normalized = question.lower()
    if any(keyword in normalized for keyword in DESTRUCTIVE_KEYWORDS):
        return "destructive"
    if any(keyword in normalized for keyword in WRITE_KEYWORDS):
        return "write"
    return "read"


def requires_human_approval(tier: PermissionTier) -> bool:
    return tier in ("write", "destructive")
