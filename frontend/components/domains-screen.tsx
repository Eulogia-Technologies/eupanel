"use client";

import { useEffect, useState } from "react";

// ── Types ─────────────────────────────────────────────────────────────────────

interface Subscription {
  id: string;
  plan_id: string;
  system_username: string;
  status: string;
  provisioning_status: string;
}

interface DomainRecord {
  id: string;
  subscription_id: string;
  domain: string;
  root_path: string;
  nginx_config_path?: string;
  ssl_status: "pending" | "active" | "failed";
  status: "pending" | "active" | "failed";
  provisioning_log?: string;
  created_at: string;
}

const STATUS: Record<string, { label: string; cls: string }> = {
  active:  { label: "Active",  cls: "ep-badge-success" },
  pending: { label: "Pending", cls: "ep-badge-warning" },
  failed:  { label: "Failed",  cls: "ep-badge-danger"  },
};

const SSL: Record<string, { label: string; cls: string }> = {
  active:  { label: "SSL Active",  cls: "ep-badge-success" },
  pending: { label: "SSL Pending", cls: "ep-badge-neutral" },
  failed:  { label: "SSL Failed",  cls: "ep-badge-warning" },
};

// ── Component ─────────────────────────────────────────────────────────────────

export function DomainsScreen() {
  const [subs, setSubs] = useState<Subscription[]>([]);
  const [selectedSub, setSelectedSub] = useState<string>("");
  const [domains, setDomains] = useState<DomainRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAdd, setShowAdd] = useState(false);
  const [domainInput, setDomainInput] = useState("");
  const [adding, setAdding] = useState(false);
  const [addError, setAddError] = useState<string | null>(null);
  const [expandedLog, setExpandedLog] = useState<string | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);

  const API = process.env.NEXT_PUBLIC_FRONTEND_API_BASE ?? "/api";

  function authHeaders() {
    const token = localStorage.getItem("eupanel_token");
    return { "Content-Type": "application/json", Authorization: `Bearer ${token}` };
  }

  async function fetchSubs() {
    const r = await fetch(`${API}/subscriptions`, { headers: authHeaders() });
    const d = await r.json();
    const active = (d.data ?? []).filter((s: Subscription) => s.status === "active" && s.provisioning_status === "success");
    setSubs(active);
    if (active.length > 0 && !selectedSub) setSelectedSub(active[0].id);
  }

  async function fetchDomains(subId: string) {
    if (!subId) { setDomains([]); setLoading(false); return; }
    setLoading(true);
    try {
      const r = await fetch(`${API}/domains?subscription_id=${subId}`, { headers: authHeaders() });
      const d = await r.json();
      setDomains(d.data ?? []);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { fetchSubs(); }, []);
  useEffect(() => { if (selectedSub) fetchDomains(selectedSub); }, [selectedSub]);

  async function addDomain() {
    if (!domainInput.trim() || !selectedSub) return;
    setAdding(true);
    setAddError(null);
    try {
      const r = await fetch(`${API}/domains`, {
        method: "POST",
        headers: authHeaders(),
        body: JSON.stringify({ subscription_id: selectedSub, domain: domainInput.trim().toLowerCase() }),
      });
      const d = await r.json();
      if (r.status >= 400) {
        setAddError(d.message ?? JSON.stringify(d.errors ?? d));
        return;
      }
      setShowAdd(false);
      setDomainInput("");
      fetchDomains(selectedSub);
    } finally {
      setAdding(false);
    }
  }

  async function deleteDomain(id: string) {
    await fetch(`${API}/domains/${id}`, { method: "DELETE", headers: authHeaders() });
    setDeleteConfirm(null);
    fetchDomains(selectedSub);
  }

  const activeSub = subs.find((s) => s.id === selectedSub);

  // ── Render ────────────────────────────────────────────────────────────────

  return (
    <div className="ep-content">
      {/* Header */}
      <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", marginBottom: "2rem", gap: "1rem" }}>
        <div>
          <h1 style={{ fontSize: "1.375rem", fontWeight: 700, letterSpacing: "-0.02em", margin: 0 }}>
            Domains
          </h1>
          <p style={{ margin: "0.35rem 0 0", color: "var(--ep-text-muted)", fontSize: "0.875rem" }}>
            Add domains to your hosting account. nginx and SSL are configured automatically.
          </p>
        </div>
        {selectedSub && (
          <button className="ep-btn ep-btn-primary ep-btn-sm" onClick={() => { setShowAdd(true); setAddError(null); setDomainInput(""); }}>
            + Add Domain
          </button>
        )}
      </div>

      {/* No active subscriptions */}
      {subs.length === 0 ? (
        <div className="ep-card" style={{ padding: "3rem 2rem", textAlign: "center" }}>
          <p style={{ color: "var(--ep-text-muted)", fontSize: "0.875rem" }}>
            You need an active subscription before adding domains.
          </p>
          <a href="/dashboard/subscriptions" className="ep-btn ep-btn-primary ep-btn-sm" style={{ marginTop: "1rem", display: "inline-flex" }}>
            Go to Subscriptions
          </a>
        </div>
      ) : (
        <>
          {/* Subscription selector */}
          {subs.length > 1 && (
            <div style={{ marginBottom: "1.5rem" }}>
              <label className="ep-label" style={{ marginBottom: "0.4rem", display: "block" }}>Subscription</label>
              <select className="ep-input" style={{ maxWidth: 320 }} value={selectedSub} onChange={(e) => setSelectedSub(e.target.value)}>
                {subs.map((s) => (
                  <option key={s.id} value={s.id}>{s.system_username}</option>
                ))}
              </select>
            </div>
          )}

          {/* Domains list */}
          <div className="ep-card" style={{ padding: 0 }}>
            {loading ? (
              <div className="ep-skeleton-list">
                {[...Array(3)].map((_, i) => <div key={i} className="ep-skeleton ep-skeleton-row" />)}
              </div>
            ) : domains.length === 0 ? (
              <div style={{ padding: "3.5rem 2rem", textAlign: "center" }}>
                <p style={{ color: "var(--ep-text-muted)", fontSize: "0.875rem", margin: "0 0 1rem" }}>
                  No domains yet for <strong>{activeSub?.system_username}</strong>.
                </p>
                <button className="ep-btn ep-btn-primary ep-btn-sm" onClick={() => { setShowAdd(true); setAddError(null); }}>
                  Add First Domain
                </button>
              </div>
            ) : (
              <table className="ep-table">
                <thead>
                  <tr>
                    <th>Domain</th>
                    <th>Root</th>
                    <th>Status</th>
                    <th>SSL</th>
                    <th>Added</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  {domains.map((d) => {
                    const statusInfo = STATUS[d.status] ?? STATUS.pending;
                    const sslInfo = SSL[d.ssl_status] ?? SSL.pending;
                    return (
                      <tr key={d.id}>
                        <td>
                          <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
                            <span style={{ fontWeight: 500 }}>{d.domain}</span>
                            {d.status === "active" && (
                              <a
                                href={`http://${d.domain}`}
                                target="_blank"
                                rel="noopener noreferrer"
                                style={{ fontSize: "0.75rem", color: "var(--ep-accent)" }}
                              >
                                ↗
                              </a>
                            )}
                          </div>
                        </td>
                        <td className="ep-table-muted" style={{ fontFamily: "var(--font-ibm-plex-mono)", fontSize: "0.78rem" }}>
                          {d.root_path}
                        </td>
                        <td><span className={`ep-badge ${statusInfo.cls}`}>{statusInfo.label}</span></td>
                        <td><span className={`ep-badge ${sslInfo.cls}`}>{sslInfo.label}</span></td>
                        <td className="ep-table-muted">{new Date(d.created_at).toLocaleDateString()}</td>
                        <td>
                          <div style={{ display: "flex", gap: "0.5rem", justifyContent: "flex-end" }}>
                            {d.provisioning_log && (d.status === "failed" || d.ssl_status === "failed") && (
                              <button
                                className="ep-btn ep-btn-ghost ep-btn-xs"
                                onClick={() => setExpandedLog(expandedLog === d.id ? null : d.id)}
                              >
                                Log
                              </button>
                            )}
                            <button
                              className="ep-btn ep-btn-ghost ep-btn-xs"
                              style={{ color: "var(--ep-danger)" }}
                              onClick={() => setDeleteConfirm(d.id)}
                            >
                              Remove
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            )}
          </div>

          {/* Expanded provisioning log */}
          {expandedLog && (() => {
            const d = domains.find((x) => x.id === expandedLog);
            return d?.provisioning_log ? (
              <div className="ep-card" style={{ marginTop: "0.75rem" }}>
                <div className="ep-section-label">Provisioning Log — {d.domain}</div>
                <pre style={{ margin: 0, fontSize: "0.78rem", color: "var(--ep-text-muted)", overflowX: "auto", whiteSpace: "pre-wrap" }}>
                  {d.provisioning_log}
                </pre>
              </div>
            ) : null;
          })()}
        </>
      )}

      {/* Add Domain Modal */}
      {showAdd && (
        <div className="ep-modal-overlay" onClick={() => setShowAdd(false)}>
          <div className="ep-modal" style={{ width: "min(520px, 95vw)" }} onClick={(e) => e.stopPropagation()}>
            <div className="ep-modal-header">
              <h2>Add Domain</h2>
              <button className="ep-btn ep-btn-ghost ep-btn-xs" onClick={() => setShowAdd(false)}>✕</button>
            </div>

            <div className="ep-modal-body" style={{ display: "grid", gap: "1rem" }}>
              {addError && (
                <div style={{ padding: "0.6rem 0.75rem", background: "color-mix(in srgb, var(--ep-danger) 8%, transparent)", border: "1px solid color-mix(in srgb, var(--ep-danger) 20%, transparent)", borderRadius: "var(--ep-r-md)", fontSize: "0.84rem", color: "var(--ep-danger)" }}>
                  {addError}
                </div>
              )}

              <div className="ep-form-group">
                <label className="ep-label">Domain Name</label>
                <input
                  className="ep-input"
                  value={domainInput}
                  onChange={(e) => setDomainInput(e.target.value)}
                  placeholder="example.com"
                  onKeyDown={(e) => e.key === "Enter" && addDomain()}
                  autoFocus
                />
                <span style={{ fontSize: "0.78rem", color: "var(--ep-text-muted)", marginTop: "0.3rem", display: "block" }}>
                  Point your DNS A record to this server&rsquo;s IP before adding the domain.
                </span>
              </div>

              {/* What happens */}
              <div style={{ padding: "0.875rem 1rem", background: "var(--ep-bg)", border: "1px solid var(--ep-border)", borderRadius: "var(--ep-r-md)", fontSize: "0.8125rem" }}>
                <strong style={{ display: "block", marginBottom: "0.5rem", color: "var(--ep-text)" }}>What happens automatically</strong>
                <div style={{ display: "grid", gap: "0.35rem", color: "var(--ep-text-muted)" }}>
                  <span>① nginx server block created and enabled</span>
                  <span>② nginx reloaded — domain goes live on HTTP</span>
                  <span>③ Let&rsquo;s Encrypt SSL certificate issued</span>
                  <span>④ nginx reloaded — HTTPS active</span>
                </div>
              </div>

              {activeSub && (
                <div style={{ display: "flex", gap: "0.5rem", alignItems: "center", fontSize: "0.8125rem", color: "var(--ep-text-muted)" }}>
                  <span>Files served from:</span>
                  <code style={{ fontFamily: "var(--font-ibm-plex-mono)", fontSize: "0.78rem", background: "var(--ep-bg)", padding: "0.1rem 0.4rem", borderRadius: "var(--ep-r-sm)", border: "1px solid var(--ep-border)" }}>
                    /home/{activeSub.system_username}/public_html
                  </code>
                </div>
              )}
            </div>

            <div className="ep-modal-footer">
              <button className="ep-btn ep-btn-ghost ep-btn-sm" onClick={() => setShowAdd(false)}>Cancel</button>
              <button
                className="ep-btn ep-btn-primary ep-btn-sm"
                onClick={addDomain}
                disabled={!domainInput.trim() || adding}
              >
                {adding ? "Provisioning…" : "Add Domain"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirm */}
      {deleteConfirm && (() => {
        const d = domains.find((x) => x.id === deleteConfirm);
        return (
          <div className="ep-modal-overlay" onClick={() => setDeleteConfirm(null)}>
            <div className="ep-modal" style={{ width: "min(420px, 95vw)" }} onClick={(e) => e.stopPropagation()}>
              <div className="ep-modal-header">
                <h2>Remove Domain</h2>
                <button className="ep-btn ep-btn-ghost ep-btn-xs" onClick={() => setDeleteConfirm(null)}>✕</button>
              </div>
              <div className="ep-modal-body">
                <p style={{ color: "var(--ep-text-muted)", fontSize: "0.875rem" }}>
                  Remove <strong>{d?.domain}</strong>? The nginx config will be deleted and the domain will stop serving traffic. Your files are not affected.
                </p>
              </div>
              <div className="ep-modal-footer">
                <button className="ep-btn ep-btn-ghost ep-btn-sm" onClick={() => setDeleteConfirm(null)}>Cancel</button>
                <button
                  className="ep-btn ep-btn-sm"
                  style={{ background: "var(--ep-danger)", color: "#fff" }}
                  onClick={() => deleteDomain(deleteConfirm)}
                >
                  Remove Domain
                </button>
              </div>
            </div>
          </div>
        );
      })()}
    </div>
  );
}
