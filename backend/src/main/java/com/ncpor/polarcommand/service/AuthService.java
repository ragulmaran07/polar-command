package com.ncpor.polarcommand.service;

import com.ncpor.polarcommand.config.JwtProperties;
import com.ncpor.polarcommand.dto.auth.AuthResponse;
import com.ncpor.polarcommand.dto.auth.LoginRequest;
import com.ncpor.polarcommand.entity.RefreshToken;
import com.ncpor.polarcommand.entity.User;
import com.ncpor.polarcommand.exception.InvalidTokenException;
import com.ncpor.polarcommand.repository.RefreshTokenRepository;
import com.ncpor.polarcommand.repository.UserRepository;
import com.ncpor.polarcommand.security.CustomUserDetails;
import com.ncpor.polarcommand.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final JwtProperties jwtProperties;
    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;

    @Transactional
    public AuthResponse login(LoginRequest request) {
        var authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.email(), request.password()));

        CustomUserDetails principal = (CustomUserDetails) authentication.getPrincipal();
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new InvalidTokenException("User no longer exists."));

        return issueTokens(user, principal);
    }

    @Transactional
    public AuthResponse refresh(String refreshTokenValue) {
        RefreshToken stored = refreshTokenRepository.findByToken(refreshTokenValue)
                .orElseThrow(() -> new InvalidTokenException("Refresh token is invalid."));

        if (stored.isRevoked() || stored.getExpiresAt().isBefore(OffsetDateTime.now(ZoneOffset.UTC))) {
            throw new InvalidTokenException("Refresh token has expired or was revoked. Please log in again.");
        }

        User user = stored.getUser();
        stored.setRevoked(true);
        refreshTokenRepository.save(stored);

        CustomUserDetails principal = new CustomUserDetails(user);
        return issueTokens(user, principal);
    }

    @Transactional
    public void logout(String refreshTokenValue) {
        refreshTokenRepository.findByToken(refreshTokenValue).ifPresent(rt -> {
            rt.setRevoked(true);
            refreshTokenRepository.save(rt);
        });
    }

    private AuthResponse issueTokens(User user, CustomUserDetails principal) {
        String accessToken = jwtService.generateAccessToken(principal);
        String refreshTokenValue = jwtService.generateOpaqueRefreshToken();

        RefreshToken refreshToken = new RefreshToken();
        refreshToken.setUser(user);
        refreshToken.setToken(refreshTokenValue);
        refreshToken.setExpiresAt(OffsetDateTime.now(ZoneOffset.UTC)
                .plusSeconds(jwtProperties.getRefreshTokenExpiryMs() / 1000));
        refreshTokenRepository.save(refreshToken);

        return new AuthResponse(
                accessToken,
                refreshTokenValue,
                "Bearer",
                new AuthResponse.UserSummary(
                        user.getId().toString(),
                        user.getFullName(),
                        user.getEmail(),
                        user.getRole().getName()
                )
        );
    }
}
