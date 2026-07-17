from rest_framework.permissions import BasePermission


class IsNodeManager(BasePermission):
    """Object-level check: only the node's own manager may modify it."""

    message = "Only this node's manager may perform this action."

    def has_object_permission(self, request, view, obj):
        return obj.manager_id == request.user.id
