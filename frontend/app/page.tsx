"use client";

import { FormEvent, useMemo, useState } from "react";
import { useRouter } from "next/navigation";

type LoginResponse = {
  status: string;
  data?: {
    token?: string;
    user?: { id?: string; name?: string; email?: string; role?: string };
  };
  message?: string;
};

/* ── Logo Mark ─────────────────────────────────────────────────── */
function LogoMark({ size = 36 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg">
      <rect width="36" height="36" rx="10" fill="url(#lgrad)" />
      <path d="M10 18h16M10 13h10M10 23h13" stroke="white" strokeWidth="2.2" strokeLinecap="round" />
      <defs>
        <linearGradient id="lgrad" x1="0" y1="0" x2="36" y2="36" gradientUnits="userSpaceOnUse">
          <stop stopColor="#10B981" />
          <stop offset="1" stopColor="#065F46" />
        </linearGradient>
      </defs>
    </svg>
  );
}

/* ── Spinner ───────────────────────────────────────────────────── */
function Spinner() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" style={{ animation: "ep-spin 0.7s linear infinite" }}>
      <circle cx="8" cy="8" r="6" stroke="rgba(255,255,255,0.3)" strokeWidth="2" />
      <path d="M8 2a6 6 0 0 1 6 6" stroke="white" strokeWidth="2" strokeLinecap="round" />
    </svg>
  );
}

/* ── Feature row ───────────────────────────────────────────────── */
function Feature({ icon, text }: { icon: string; text: string }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: "0.625rem" }}>
      <span style={{
        width: 28, height: 28, borderRadius: 8,
        background: "rgba(16,185,129,0.15)",
        border: "1px solid rgba(16,185,129,0.25)",
        display: "flex", alignItems: "center", justifyContent: "center",
        fontSize: 13, flexShrink: 0,
      }}>{icon}</span>
      <span style={{ fontSize: "0.875rem", color: "#94A3B8" }}>{text}</span>
    </div>
  );
}

/* ── Stat pill ─────────────────────────────────────────────────── */
function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div style={{
      flex: 1, padding: "0.75rem 1rem",
      background: "rgba(255,255,255,0.04)",
      border: "1px solid rgba(255,255,255,0.08)",
      borderRadius: 12,
      display: "grid", gap: "0.2rem",
    }}>
      <div style={{ fontSize: "1.25rem", fontWeight: 700, color: "#F1F5F9", letterSpacing: "-0.03em" }}>{value}</div>
      <div style={{ fontSize: "0.72rem", color: "#64748B", textTransform: "uppercase", letterSpacing: "0.06em" }}>{label}</div>
    </div>
  );
}

/* ── Main Page ─────────────────────────────────────────────────── */
export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail]       = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading]   = useState(false);
  const [error, setError]       = useState("");
  const [info, setInfo]         = useState("");

  const apiBase = useMemo(() => process.env.NEXT_PUBLIC_FRONTEND_API_BASE ?? "/api", []);

  async function handleLogin(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setLoading(true); setError(""); setInfo("");
    try {
      const res    = await fetch(`${apiBase}/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      const result = (await res.json()) as LoginResponse;
      if (!res.ok || !result.data?.token || !result.data.user?.role)
        throw new Error(result.message ?? "Invalid credentials.");
      localStorage.setItem("eupanel_token", result.data.token);
      localStorage.setItem("eupanel_user",  JSON.stringify(result.data.user));
      const role = result.data.user.role.toLowerCase();
      router.push(role === "admin" ? "/dashboard/admin" : role === "reseller" ? "/dashboard/reseller" : "/dashboard");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed.");
    } finally { setLoading(false); }
  }

  async function seedUsers() {
    setLoading(true); setError(""); setInfo("");
    try {
      const res = await fetch(`${apiBase}/auth/seed-default-users`, { method: "POST" });
      if (!res.ok) throw new Error("Seed failed.");
      setInfo("Demo users ready — use quick-fill below.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Seed failed.");
    } finally { setLoading(false); }
  }

  function fill(role: "admin" | "customer" | "reseller") {
    const creds = {
      admin:    { e: "admin@eupanel.local",    p: "Admin@12345"    },
      customer: { e: "customer@eupanel.local", p: "Customer@12345" },
      reseller: { e: "reseller@eupanel.local", p: "Reseller@12345" },
    };
    setEmail(creds[role].e);
    setPassword(creds[role].p);
    setError(""); setInfo("");
  }

  /* ── Dot grid pattern as SVG data URI ── */
  const dotGrid = `url("data:image/svg+xml,%3Csvg width='28' height='28' viewBox='0 0 28 28' xmlns='http://www.w3.org/2000/svg'%3E%3Ccircle cx='1' cy='1' r='1' fill='rgba(255,255,255,0.06)'/%3E%3C/svg%3E")`;

  return (
    <div style={{
      minHeight: "100vh",
      display: "grid",
      gridTemplateColumns: "1fr 1fr",
      fontFamily: "var(--font-space-grotesk), ui-sans-serif, system-ui, sans-serif",
    }}>
      {/* ══════════════════ LEFT — Brand Panel ══════════════════ */}
      <div style={{
        background: "#0B0E13",
        backgroundImage: dotGrid,
        position: "relative",
        overflow: "hidden",
        display: "flex",
        flexDirection: "column",
        justifyContent: "space-between",
        padding: "2.5rem",
      }}>
        {/* Glow orbs */}
        <div style={{
          position: "absolute", width: 480, height: 480,
          borderRadius: "50%",
          background: "radial-gradient(circle, rgba(16,185,129,0.18) 0%, transparent 70%)",
          bottom: -120, left: -80, pointerEvents: "none",
        }} />
        <div style={{
          position: "absolute", width: 300, height: 300,
          borderRadius: "50%",
          background: "radial-gradient(circle, rgba(16,185,129,0.08) 0%, transparent 70%)",
          top: -60, right: 40, pointerEvents: "none",
        }} />

        {/* Top — Logo */}
        <div style={{ position: "relative", zIndex: 1 }}>
          <div style={{ display: "flex", alignItems: "center", gap: "0.75rem", marginBottom: "0.5rem" }}>
            <LogoMark size={38} />
            <div>
              <div style={{ fontSize: "1.25rem", fontWeight: 800, color: "#F8FAFC", letterSpacing: "-0.03em" }}>
                eupanel
              </div>
              <div style={{
                fontSize: "0.68rem", color: "#10B981",
                fontFamily: "var(--font-ibm-plex-mono), monospace",
                letterSpacing: "0.08em", textTransform: "uppercase",
              }}>
                hosting control panel
              </div>
            </div>
          </div>
        </div>

        {/* Middle — Headline + Features */}
        <div style={{ position: "relative", zIndex: 1, display: "grid", gap: "2rem" }}>
          <div>
            <h2 style={{
              fontSize: "clamp(1.5rem, 3vw, 2.25rem)",
              fontWeight: 800,
              color: "#F8FAFC",
              lineHeight: 1.15,
              letterSpacing: "-0.03em",
              marginBottom: "0.75rem",
            }}>
              The panel your<br />
              <span style={{ color: "#10B981" }}>servers deserve.</span>
            </h2>
            <p style={{ fontSize: "0.9rem", color: "#64748B", maxWidth: "36ch", lineHeight: 1.6 }}>
              Provision sites, manage databases, automate SSL and DNS — all from one unified interface.
            </p>
          </div>

          <div style={{ display: "grid", gap: "0.75rem" }}>
            <Feature icon="🌐" text="PHP · Node.js · Dart · Python · Docker" />
            <Feature icon="🔒" text="Automated Let's Encrypt SSL certificates" />
            <Feature icon="🗄️" text="MySQL & PostgreSQL with isolated users" />
            <Feature icon="⚡" text="Real-time agent job execution per server" />
            <Feature icon="🌍" text="PowerDNS zone & record management" />
          </div>

          {/* Stats */}
          <div style={{ display: "flex", gap: "0.75rem" }}>
            <Stat value="5+" label="Runtimes" />
            <Stat value="3" label="Roles" />
            <Stat value="∞" label="Servers" />
          </div>
        </div>

        {/* Bottom — Powered by */}
        <div style={{ position: "relative", zIndex: 1 }}>
          <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
            <div style={{
              width: 6, height: 6, borderRadius: "50%",
              background: "#10B981",
              boxShadow: "0 0 6px #10B981",
            }} />
            <span style={{ fontSize: "0.78rem", color: "#475569" }}>
              Powering{" "}
              <span style={{ color: "#10B981", fontWeight: 600 }}>EuCloudHost</span>
            </span>
          </div>
        </div>
      </div>

      {/* ══════════════════ RIGHT — Form Panel ══════════════════ */}
      <div style={{
        background: "#F6F5F1",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        padding: "2rem 1.5rem",
      }}>
        <div style={{ width: "100%", maxWidth: 400, display: "grid", gap: "1.5rem" }}>

          {/* Heading */}
          <div>
            <h1 style={{
              fontSize: "1.75rem", fontWeight: 800,
              letterSpacing: "-0.03em", color: "#0F172A",
              marginBottom: "0.4rem",
            }}>
              Welcome back
            </h1>
            <p style={{ fontSize: "0.875rem", color: "#64748B" }}>
              Sign in — role-based routing happens automatically.
            </p>
          </div>

          {/* Alerts */}
          {error && (
            <div style={{
              padding: "0.75rem 1rem",
              background: "#FEF2F2", border: "1px solid #FECACA",
              borderRadius: 10, fontSize: "0.875rem", color: "#DC2626",
              display: "flex", gap: "0.5rem", alignItems: "flex-start",
            }}>
              <span style={{ flexShrink: 0 }}>⚠</span> {error}
            </div>
          )}
          {info && (
            <div style={{
              padding: "0.75rem 1rem",
              background: "#F0FDF4", border: "1px solid #BBF7D0",
              borderRadius: 10, fontSize: "0.875rem", color: "#16A34A",
              display: "flex", gap: "0.5rem", alignItems: "flex-start",
            }}>
              <span style={{ flexShrink: 0 }}>✓</span> {info}
            </div>
          )}

          {/* Form */}
          <form onSubmit={handleLogin} style={{ display: "grid", gap: "1.125rem" }}>
            {/* Email */}
            <div style={{ display: "grid", gap: "0.4rem" }}>
              <label htmlFor="email" style={{ fontSize: "0.8125rem", fontWeight: 600, color: "#0F172A" }}>
                Email address
              </label>
              <div style={{ position: "relative" }}>
                <span style={{
                  position: "absolute", left: "0.75rem", top: "50%", transform: "translateY(-50%)",
                  color: "#94A3B8", fontSize: "0.875rem", pointerEvents: "none",
                }}>✉</span>
                <input
                  id="email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="you@example.com"
                  autoComplete="email"
                  required
                  style={{
                    width: "100%", padding: "0.65rem 0.85rem 0.65rem 2.25rem",
                    border: "1.5px solid #E2E8F0",
                    borderRadius: 10, fontSize: "0.9rem",
                    background: "white", color: "#0F172A",
                    outline: "none", transition: "border-color 0.15s, box-shadow 0.15s",
                    fontFamily: "inherit",
                  }}
                  onFocus={(e) => {
                    e.target.style.borderColor = "#10B981";
                    e.target.style.boxShadow = "0 0 0 3px rgba(16,185,129,0.12)";
                  }}
                  onBlur={(e) => {
                    e.target.style.borderColor = "#E2E8F0";
                    e.target.style.boxShadow = "none";
                  }}
                />
              </div>
            </div>

            {/* Password */}
            <div style={{ display: "grid", gap: "0.4rem" }}>
              <label htmlFor="password" style={{ fontSize: "0.8125rem", fontWeight: 600, color: "#0F172A" }}>
                Password
              </label>
              <div style={{ position: "relative" }}>
                <span style={{
                  position: "absolute", left: "0.75rem", top: "50%", transform: "translateY(-50%)",
                  color: "#94A3B8", fontSize: "0.875rem", pointerEvents: "none",
                }}>🔑</span>
                <input
                  id="password"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  autoComplete="current-password"
                  required
                  style={{
                    width: "100%", padding: "0.65rem 0.85rem 0.65rem 2.25rem",
                    border: "1.5px solid #E2E8F0",
                    borderRadius: 10, fontSize: "0.9rem",
                    background: "white", color: "#0F172A",
                    outline: "none", transition: "border-color 0.15s, box-shadow 0.15s",
                    fontFamily: "inherit",
                  }}
                  onFocus={(e) => {
                    e.target.style.borderColor = "#10B981";
                    e.target.style.boxShadow = "0 0 0 3px rgba(16,185,129,0.12)";
                  }}
                  onBlur={(e) => {
                    e.target.style.borderColor = "#E2E8F0";
                    e.target.style.boxShadow = "none";
                  }}
                />
              </div>
            </div>

            {/* Submit */}
            <button
              type="submit"
              disabled={loading}
              style={{
                display: "flex", alignItems: "center", justifyContent: "center", gap: "0.5rem",
                padding: "0.75rem 1rem",
                background: loading ? "#059669" : "linear-gradient(135deg, #10B981 0%, #059669 100%)",
                color: "white", border: "none", borderRadius: 10,
                fontSize: "0.9375rem", fontWeight: 700,
                cursor: loading ? "not-allowed" : "pointer",
                opacity: loading ? 0.85 : 1,
                transition: "opacity 0.15s, transform 0.1s, box-shadow 0.15s",
                boxShadow: "0 2px 12px rgba(16,185,129,0.35)",
                fontFamily: "inherit",
                letterSpacing: "-0.01em",
              }}
              onMouseEnter={(e) => { if (!loading) { (e.currentTarget as HTMLButtonElement).style.boxShadow = "0 4px 20px rgba(16,185,129,0.45)"; (e.currentTarget as HTMLButtonElement).style.transform = "translateY(-1px)"; } }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.boxShadow = "0 2px 12px rgba(16,185,129,0.35)"; (e.currentTarget as HTMLButtonElement).style.transform = ""; }}
            >
              {loading ? <><Spinner /> Signing in…</> : "Sign in →"}
            </button>
          </form>

          {/* Divider */}
          <div style={{ display: "flex", alignItems: "center", gap: "0.75rem" }}>
            <div style={{ flex: 1, height: 1, background: "#E2E8F0" }} />
            <span style={{ fontSize: "0.75rem", color: "#94A3B8", fontWeight: 500 }}>DEMO ACCOUNTS</span>
            <div style={{ flex: 1, height: 1, background: "#E2E8F0" }} />
          </div>

          {/* Quick fill */}
          <div style={{
            background: "white",
            border: "1.5px solid #E2E8F0",
            borderRadius: 12, overflow: "hidden",
          }}>
            <div style={{
              padding: "0.625rem 1rem",
              background: "#F8FAFC",
              borderBottom: "1px solid #E2E8F0",
              fontSize: "0.72rem", fontWeight: 600,
              letterSpacing: "0.06em", textTransform: "uppercase", color: "#94A3B8",
            }}>
              Quick fill
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr" }}>
              {(["admin", "customer", "reseller"] as const).map((role, i) => (
                <button
                  key={role}
                  onClick={() => fill(role)}
                  style={{
                    padding: "0.75rem 0.5rem",
                    background: "white", border: "none",
                    borderRight: i < 2 ? "1px solid #E2E8F0" : "none",
                    cursor: "pointer", textAlign: "center",
                    transition: "background 0.12s",
                    fontFamily: "inherit",
                  }}
                  onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.background = "#F0FDF4"; }}
                  onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.background = "white"; }}
                >
                  <div style={{ fontSize: "0.875rem", fontWeight: 600, color: "#0F172A" }}>
                    {role.charAt(0).toUpperCase() + role.slice(1)}
                  </div>
                  <div style={{ fontSize: "0.68rem", color: "#94A3B8", marginTop: "0.15rem" }}>
                    {role}@eupanel.local
                  </div>
                </button>
              ))}
            </div>
          </div>

          {/* Seed */}
          <button
            onClick={seedUsers}
            disabled={loading}
            style={{
              padding: "0.6rem 1rem",
              background: "transparent",
              border: "1.5px solid #E2E8F0",
              borderRadius: 10,
              fontSize: "0.8125rem", fontWeight: 500,
              color: "#64748B", cursor: "pointer",
              transition: "border-color 0.15s, color 0.15s, background 0.15s",
              fontFamily: "inherit",
            }}
            onMouseEnter={(e) => {
              (e.currentTarget as HTMLButtonElement).style.borderColor = "#10B981";
              (e.currentTarget as HTMLButtonElement).style.color = "#059669";
              (e.currentTarget as HTMLButtonElement).style.background = "#F0FDF4";
            }}
            onMouseLeave={(e) => {
              (e.currentTarget as HTMLButtonElement).style.borderColor = "#E2E8F0";
              (e.currentTarget as HTMLButtonElement).style.color = "#64748B";
              (e.currentTarget as HTMLButtonElement).style.background = "transparent";
            }}
          >
            Seed default users to database
          </button>

          {/* Footer */}
          <p style={{ textAlign: "center", fontSize: "0.72rem", color: "#CBD5E1" }}>
            eupanel v1.0 · EuCloudHost
          </p>
        </div>
      </div>

      {/* Mobile: stack vertically */}
      <style>{`
        @media (max-width: 800px) {
          div[style*="gridTemplateColumns: 1fr 1fr"] {
            grid-template-columns: 1fr !important;
          }
          div[style*="background: #0B0E13"] {
            display: none !important;
          }
        }
      `}</style>
    </div>
  );
}
