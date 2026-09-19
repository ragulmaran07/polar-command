package com.ncpor.polarcommand.dto.auth;

public record AuthResponse(
        String accessToken,
        String refreshToken,
        String tokenType,
        UserSummary user
) {
    public record UserSummary(
            String id,
            String fullName,
            String email,
            String role
    ) {}
}
