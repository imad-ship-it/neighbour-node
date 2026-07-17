from django.conf import settings
from django.contrib import admin

from .models import Node, NodePhoto


class NodePhotoInline(admin.TabularInline):
    model = NodePhoto
    extra = 0
    max_num = 3


_location_fields = ("location",) if settings.USE_GIS else ("latitude", "longitude")


@admin.register(Node)
class NodeAdmin(admin.ModelAdmin):
    list_display = (
        "name",
        "manager",
        "is_active",
        "rating",
        "total_transactions",
        "created_at",
    )
    list_filter = ("is_active",)
    search_fields = ("name", "address", "manager__email")
    ordering = ("-created_at",)
    inlines = [NodePhotoInline]
    actions = ["approve_nodes"]
    readonly_fields = ("rating", "total_transactions", "created_at", "updated_at")
    fields = (
        "manager",
        "name",
        "description",
        "address",
        *_location_fields,
        "operating_hours",
        "capacity",
        "is_active",
        "rating",
        "total_transactions",
        "created_at",
        "updated_at",
    )

    @admin.action(description="Approve selected nodes")
    def approve_nodes(self, request, queryset):
        updated = queryset.update(is_active=True)
        # TODO(Phase 5): FCM-notify managers of newly approved nodes.
        self.message_user(request, f"{updated} node(s) approved.")
