import api from "./client"

export interface LoginRequest {
  email: string
  password: string
}

export interface AuthUser {
  id: string
  fullName: string
  email: string
  role: string
}

export interface AuthResponse {
  accessToken: string
  refreshToken: string
  tokenType: string
  user: AuthUser
}

export async function login(payload: LoginRequest): Promise<AuthResponse> {
  const response = await api.post<AuthResponse>("/auth/login", payload)
  return response.data
}
