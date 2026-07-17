from django.contrib.auth.models import AbstractUser


class User(AbstractUser):
    """Custom user (MASTER_PLAN §4.1).

    Placeholder so AUTH_USER_MODEL is set before the first migration —
    swapping it later is a painful, data-destroying operation. The real
    fields (phone_number, role, rating, location, ...) land in Phase 1
    together with the initial migration. Do not run `migrate` until then.
    """
