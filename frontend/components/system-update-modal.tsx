"use client";

import { useEffect, useRef, useState } from "react";

type UpdateState = "idle" | "confirming" | "running" | "success" | "failed";

export function SystemUpdateButton() {
  const [state, setState]       = useState<UpdateState>("idle");
  const [log, setLog]           = useState("");
  const [lineCount, setLineCount] = useState(0);
  const logRef                  = useRef<HTMLPreElement>(null);
  const pollRef                 = useRef<ReturnType<typeof setInterval> | null>(null);

  const API = process.env.NEXT_PUBLIC_FRONTEND_API_BASE ?? "/api";

  function authHeaders() {
    const token = typeof window !== "undefined" ? localStorage.getItem("eupanel_token") : "";
    return { "Content-Type": "application/json", Authorization: `Bearer ${token}` };
  }

  // Auto-scroll log to bottom
  useEffect(() => {
    if (logRef.current) {
      logRef.current.scrollTop = logRef.current.scrollHeight;
    }
  }, [log]);

  // Poll while running
  useEffect(() => {
    if (state === "running") {
      pollRef.current = setInterval(pollStatus, 2000);
    } else {
      if (pollRef.current) clearInterval(pollRef.current);
    }
    return () => { if (pollRef.current) clearInterval(pollRef.current); };
  }, [state]);

  async function pollStatus() {
    try {
      const r = await fetch(`${API}/admin/system/update-status`, { headers: authHeaders() });
      const d = await r.json();
      setLog(d.log ?? "");
      setLineCount(d.lines ?? 0);
      if (d.status === "success") setState("success");
      if (d.status === "failed")  setState("failed");
    } catch { /* network may be down during restart — keep polling */ }
  }

  async function startUpdate() {
    setState("running");
    setLog("");
    setLineCount(0);
    try {
      await fetch(`${API}/admin/system/update`, {
        method: "POST",
        headers: authHeaders(),
      });
    } catch {
      // Backend may restart before we get a response — that's fine, keep polling
    }
    // Start polling immediately
    pollStatus();
  }

  function close() {
    setState("idle");
    setLog("");
  }

  // ── Render ──────────────────────────────────────────────────────────────────

  return (
    <>
      {/* Trigger button */}
      <button
        className="ep-btn ep-btn-ghost ep-btn-sm"
        style={{ gap: "0.4rem", display: "flex", alignItems: "center" }}
        onClick={() => setState("confirming")}
      >
        <span style={{ fontSize: "0.85rem" }}>↑</span>
        Update Panel
      </button>

      {/* Confirm modal */}
      {state === "confirming" && (
        <div className="ep-modal-overlay" onClick={close}>
          <div className="ep-modal" style={{ width: "min(440px, 95vw)" }} onClick={(e) => e.stopPropagation()}>
            <div className="ep-modal-header">
              <h2>Update EuPanel</h2>
              <button className="ep-btn ep-btn-ghost ep-btn-xs" onClick={close}>✕</button>
            </div>
            <div className="ep-modal-body">
              <p style={{ fontSize: "0.875rem", color: "var(--ep-text-muted)", lineHeight: 1.6 }}>
                This will pull the latest code from GitHub, rebuild the backend, frontend, and agent, run any new migrations, and restart all services.
              </p>
              <p style={{ fontSize: "0.875rem", color: "var(--ep-text-muted)", marginTop: "0.75rem", lineHeight: 1.6 }}>
                The panel will be briefly unavailable while services restart. The update runs as a detached process so it continues even if the connection drops.
              </p>
            </div>
            <div className="ep-modal-footer">
              <button className="ep-btn ep-btn-ghost ep-btn-sm" onClick={close}>Cancel</button>
              <button className="ep-btn ep-btn-primary ep-btn-sm" onClick={startUpdate}>
                Start Update
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Progress / result modal */}
      {(state === "running" || state === "success" || state === "failed") && (
        <div className="ep-modal-overlay" onClick={state !== "running" ? close : undefined}>
          <div
            className="ep-modal"
            style={{ width: "min(760px, 95vw)", maxHeight: "90vh" }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="ep-modal-header">
              <h2 style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
                {state === "running" && <Spinner />}
                {state === "success" && <span style={{ color: "var(--ep-success)" }}>✓</span>}
                {state === "failed"  && <span style={{ color: "var(--ep-danger)" }}>✗</span>}
                {state === "running" ? "Updating…" : state === "success" ? "Update Complete" : "Update Failed"}
              </h2>
              {state !== "running" && (
                <button className="ep-btn ep-btn-ghost ep-btn-xs" onClick={close}>✕</button>
              )}
            </div>

            <div className="ep-modal-body" style={{ padding: 0 }}>
              {/* Status bar */}
              <div style={{
                padding: "0.5rem 1rem",
                borderBottom: "1px solid var(--ep-border)",
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                fontSize: "0.78rem",
                color: "var(--ep-text-muted)",
              }}>
                <span>
                  {state === "running" && "Running update script on server…"}
                  {state === "success" && "All services restarted successfully."}
                  {state === "failed"  && "Update encountered an error — check log below."}
                </span>
                <span>{lineCount} lines</span>
              </div>

              {/* Log output */}
              <pre
                ref={logRef}
                style={{
                  margin: 0,
                  padding: "1rem",
                  fontFamily: "var(--font-ibm-plex-mono, monospace)",
                  fontSize: "0.75rem",
                  lineHeight: 1.6,
                  overflowY: "auto",
                  maxHeight: "50vh",
                  minHeight: "200px",
                  background: "var(--ep-surface-2, #0d0d0f)",
                  color: "var(--ep-text-code, #e2e8f0)",
                  whiteSpace: "pre-wrap",
                  wordBreak: "break-all",
                }}
              >
                {log || (state === "running" ? "Waiting for output…" : "No output.")}
              </pre>
            </div>

            {state !== "running" && (
              <div className="ep-modal-footer">
                <button className="ep-btn ep-btn-ghost ep-btn-sm" onClick={close}>Close</button>
                {state === "success" && (
                  <button
                    className="ep-btn ep-btn-primary ep-btn-sm"
                    onClick={() => window.location.reload()}
                  >
                    Reload Page
                  </button>
                )}
              </div>
            )}
          </div>
        </div>
      )}
    </>
  );
}

function Spinner() {
  return (
    <span style={{
      display: "inline-block",
      width: "14px",
      height: "14px",
      border: "2px solid var(--ep-border)",
      borderTopColor: "var(--ep-accent)",
      borderRadius: "50%",
      animation: "ep-spin 0.7s linear infinite",
      flexShrink: 0,
    }} />
  );
}
