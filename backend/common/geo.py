"""Geo helpers for the non-GIS fallback mode (MASTER_PLAN §8.3).

With USE_GIS=false there is no PostGIS, so radius queries are done as a
cheap bounding-box prefilter in SQL followed by an exact haversine check
in Python. With USE_GIS=true the ORM does all of this natively and these
helpers are unused.
"""
import math

EARTH_RADIUS_M = 6_371_000


def haversine_m(lat1, lng1, lat2, lng2):
    """Great-circle distance between two (lat, lng) points, in meters."""
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lng2 - lng1)
    a = (
        math.sin(dphi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    )
    return 2 * EARTH_RADIUS_M * math.asin(math.sqrt(a))


def bounding_box(lat, lng, radius_m):
    """(min_lat, max_lat, min_lng, max_lng) box containing the radius circle.

    Slightly oversized (a box around a circle), so callers must still do the
    exact haversine check on each candidate.
    """
    dlat = math.degrees(radius_m / EARTH_RADIUS_M)
    # Longitude degrees shrink with latitude; guard cos() hitting 0 at poles.
    cos_lat = max(math.cos(math.radians(lat)), 1e-12)
    dlng = math.degrees(radius_m / (EARTH_RADIUS_M * cos_lat))
    return lat - dlat, lat + dlat, lng - dlng, lng + dlng
