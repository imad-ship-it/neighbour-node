import django_filters

from .models import Item


class ItemFilter(django_filters.FilterSet):
    """Query-param filters layered on top of the nearby geo query (§5)."""

    max_rate = django_filters.NumberFilter(
        field_name="daily_rate", lookup_expr="lte"
    )

    class Meta:
        model = Item
        fields = ("category", "storage_type", "max_rate")
