from django.contrib import admin

from .models import Item, ItemImage


class ItemImageInline(admin.TabularInline):
    model = ItemImage
    extra = 0
    max_num = 5


@admin.register(Item)
class ItemAdmin(admin.ModelAdmin):
    list_display = (
        "title",
        "owner",
        "node",
        "storage_type",
        "listing_status",
        "daily_rate",
        "is_available",
        "created_at",
    )
    list_filter = ("listing_status", "category", "storage_type", "is_available")
    search_fields = ("title", "owner__email", "node__name")
    ordering = ("-created_at",)
    inlines = [ItemImageInline]
    readonly_fields = ("created_at", "updated_at")
