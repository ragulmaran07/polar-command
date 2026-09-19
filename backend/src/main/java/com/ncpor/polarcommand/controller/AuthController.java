package com.ncpor.polarcommand.controller;

import com.ncpor.polarcommand.dto.auth.AuthResponse;
import com.ncpor.polarcommand.dto.auth.LoginRequest;
import com.ncpor.polarcommand.dto.auth.RefreshRequest;
import com.ncpor.polarcommand.security.CustomUserDetails;
import com.ncpor.polarcommand.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @PostMapping("/refresh")
    public ResponseEntity<AuthResponse> refresh(@Valid @RequestBody RefreshRequest request) {
        return ResponseEntity.ok(authService.refresh(request.refreshToken()));
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout(@Valid @RequestBody RefreshRequest request) {
        authService.logout(request.refreshToken());
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/me")
    public ResponseEntity<Map<String, String>> me(@AuthenticationPrincipal CustomUserDetails principal) {
        return ResponseEntity.ok(Map.of(
                "id", principal.getId().toString(),
                "email", principal.getEmail(),
                "role", principal.getRoleName()
        ));
    }
}
