package com.ncpor.polarcommand.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

import java.time.OffsetDateTime;

@Component
public class RestAuthenticationEntryPoint implements AuthenticationEntryPoint {

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response,
                          AuthenticationException authException) throws java.io.IOException {
        response.setContentType("application/json");
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);

        String path = request.getRequestURI().replace("\"", "'");
        String json = """
                {"timestamp":"%s","status":401,"error":"Unauthorized","message":"Authentication required or token is invalid/expired.","path":"%s"}"""
                .formatted(OffsetDateTime.now(), path);

        response.getWriter().write(json);
    }
}
