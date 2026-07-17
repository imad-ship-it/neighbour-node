from drf_spectacular.utils import OpenApiResponse, extend_schema
from rest_framework import generics, status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .serializers import RegisterSerializer, UserSerializer, VerifyPhoneSerializer


class RegisterView(generics.CreateAPIView):
    """POST /api/v1/auth/register/ — public signup, returns user + JWT pair."""

    serializer_class = RegisterSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response(
            {
                "user": UserSerializer(user, context=self.get_serializer_context()).data,
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            },
            status=status.HTTP_201_CREATED,
        )


class MeView(generics.RetrieveUpdateAPIView):
    """GET/PATCH /api/v1/auth/me/ — own profile (multipart supported for photo)."""

    serializer_class = UserSerializer
    http_method_names = ["get", "patch", "head", "options"]

    def get_object(self):
        return self.request.user


class VerifyPhoneView(APIView):
    """POST /api/v1/auth/verify-phone/ — stub until Firebase verification lands."""

    @extend_schema(
        request=VerifyPhoneSerializer,
        responses={501: OpenApiResponse(description="Not implemented yet")},
    )
    def post(self, request):
        # TODO(MASTER_PLAN §8.1): verify the Firebase ID token with
        # firebase-admin, then set phone_number + is_phone_verified on
        # request.user. Client-side firebase_auth obtains the token.
        return Response(
            {
                "detail": (
                    "Phone verification is not implemented yet. This endpoint "
                    "will accept a Firebase ID token once the Firebase-admin "
                    "hybrid flow (MASTER_PLAN §8.1) is wired up."
                )
            },
            status=status.HTTP_501_NOT_IMPLEMENTED,
        )
