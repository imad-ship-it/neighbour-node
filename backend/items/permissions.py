from rest_framework.permissions import BasePermission


class IsOwnerOrNodeManager(BasePermission):
    """Edit/delete: the item's owner, or — for node items — that node's
    manager (MASTER_PLAN §5)."""

    message = "Only the item's owner or the node's manager may do this."

    def has_object_permission(self, request, view, obj):
        if obj.owner_id == request.user.id:
            return True
        return obj.node_id is not None and obj.node.manager_id == request.user.id


class IsNodeManagerOfItem(BasePermission):
    """Donation review: only the manager of the node the item was donated to
    (§6 Phase 3). Owners cannot approve their own donations."""

    message = "Only the manager of this item's node may review donations."

    def has_object_permission(self, request, view, obj):
        return obj.node_id is not None and obj.node.manager_id == request.user.id
