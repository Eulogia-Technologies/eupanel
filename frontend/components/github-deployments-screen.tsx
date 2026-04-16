"use client";

import { useState, useEffect } from "react";

// ── Types ────────────────────────────────────────────────────────────────────

interface GithubStatus {
  connected: boolean;
  github_username?: string;
  avatar_url?: string;
}

interface GithubRepo {
  id: number;
  full_name: string;
  name: string;
  private: boolean;
  default_branch: string;
  description?: string;
  updated_at: string;
}

interface GitDeploy {
  id: string;
  repo_full_name: string;
  branch: string;
  deploy_path: string;
  deploy_status: "idle" | "deploying" | "success" | "failed";
  last_commit_sha?: string;
  last_commit_msg?: string;
  last_deployed_at?: string;
  deploy_log?: string;
}

interface Subscription {
  id: string;
  system_username: string;
  home_directory?: string;
  status: string;
  plan_id: string;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

const API = process.env.NEXT_PUBLIC_API_URL ?? "/api";

async function apiFetch(path: string, init?: RequestInit) {
  const token = typeof window !== "undefined" ? localStorage.getItem("token") : null;
  const res = await fetch(`${API}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(init?.headers ?? {}),
    },
  });
  return res.json();
}

function StatusBadge({ status }: { status: string }) {
  const map: Record<string, string> = {
    idle:       "ep-badge ep-badge-neutral",
    deploying:  "ep-badge ep-badge-warning",
    success:    "ep-badge ep-badge-success",
    failed:     "ep-badge ep-badge-danger",
  };
  return <span className={map[status] ?? "ep-badge ep-badge-neutral"}>{status}</span>;
}

function timeAgo(iso?: string) {
  if (!iso) return "—";
  const diff = Date.now() - new Date(iso).getTime();
  const m = Math.floor(diff / 60000);
  if (m < 1) return "just now";
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  return `${Math.floor(h / 24)}d ago`;
}

// ── Main component ────────────────────────────────────────────────────────────

export default function GithubDeploymentsScreen() {
  const [ghStatus, setGhStatus]       = useState<GithubStatus | null>(null);
  const [deploys, setDeploys]         = useState<GitDeploy[]>([]);
  const [repos, setRepos]             = useState<GithubRepo[]>([]);
  const [subscriptions, setSubs]      = useState<Subscription[]>([]);
  const [loading, setLoading]         = useState(true);
  const [showConnect, setShowConnect] = useState(false);
  const [selectedLog, setSelectedLog] = useState<GitDeploy | null>(null);
  const [repoSearch, setRepoSearch]   = useState("");

  // New deploy form
  const [newDeploy, setNewDeploy] = useState({
    subscription_id: "",
    repo_full_name: "",
    branch: "main",
  });
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError]   = useState("");

  useEffect(() => { loadAll(); }, []);

  async function loadAll() {
    setLoading(true);
    const [status, deployData, subData] = await Promise.all([
      apiFetch("/github/status"),
      apiFetch("/github/deploys"),
      apiFetch("/subscriptions"),
    ]);
    setGhStatus(status);
    setDeploys(deployData.data ?? []);
    setSubs((subData.data ?? []).filter((s: Subscription) => s.status === "active"));
    setLoading(false);
  }

  async function loadRepos() {
    const data = await apiFetch("/github/repos");
    setRepos(data.data ?? []);
  }

  async function handleConnect() {
    window.location.href = `${API}/github/connect`;
  }

  async function handleDisconnect() {
    if (!confirm("Disconnect your GitHub account? Existing deploy links will stop working.")) return;
    await apiFetch("/github/disconnect", { method: "DELETE" });
    setGhStatus({ connected: false });
    setRepos([]);
  }

  async function handleCreateDeploy() {
    setFormError("");
    if (!newDeploy.subscription_id) { setFormError("Select a subscription."); return; }
    if (!newDeploy.repo_full_name)  { setFormError("Select a repository.");   return; }

    setSubmitting(true);
    const data = await apiFetch("/github/deploys", {
      method: "POST",
      body: JSON.stringify(newDeploy),
    });
    setSubmitting(false);

    if (data.status === "success") {
      setDeploys(prev => [data.data, ...prev]);
      setShowConnect(false);
      setNewDeploy({ subscription_id: "", repo_full_name: "", branch: "main" });
    } else {
      setFormError(data.message ?? JSON.stringify(data.errors ?? data));
    }
  }

  async function handleDelete(id: string) {
    if (!confirm("Remove this deploy link? The webhook will be deleted from GitHub.")) return;
    await apiFetch(`/github/deploys/${id}`, { method: "DELETE" });
    setDeploys(prev => prev.filter(d => d.id !== id));
  }

  const filteredRepos = repos.filter(r =>
    r.full_name.toLowerCase().includes(repoSearch.toLowerCase())
  );

  // ── Render ────────────────────────────────────────────────────────────────

  if (loading) {
    return (
      <div className="ep-card" style={{ padding: "2rem", textAlign: "center", color: "var(--ep-muted)" }}>
        Loading GitHub integration…
      </div>
    );
  }

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "1.5rem" }}>

      {/* ── GitHub account status ─────────────────────────────────────── */}
      <div className="ep-card" style={{ padding: "1.5rem" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", flexWrap: "wrap", gap: "1rem" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "1rem" }}>
            <div style={{
              width: 44, height: 44, borderRadius: "50%",
              background: "var(--ep-surface-2)",
              display: "flex", alignItems: "center", justifyContent: "center",
              overflow: "hidden",
            }}>
              {ghStatus?.avatar_url
                ? <img src={ghStatus.avatar_url} alt="gh" style={{ width: "100%", height: "100%" }} />
                : <GithubIcon />
              }
            </div>
            <div>
              <div style={{ fontWeight: 600, fontSize: "0.95rem" }}>
                {ghStatus?.connected
                  ? <>GitHub · <span style={{ color: "var(--ep-primary)" }}>@{ghStatus.github_username}</span></>
                  : "GitHub"}
              </div>
              <div style={{ fontSize: "0.8rem", color: "var(--ep-muted)", marginTop: 2 }}>
                {ghStatus?.connected
                  ? "Account connected — push to deploy is active"
                  : "Connect your GitHub account to enable auto-deploy"}
              </div>
            </div>
          </div>

          <div style={{ display: "flex", gap: "0.5rem" }}>
            {ghStatus?.connected ? (
              <>
                <button className="ep-btn ep-btn-sm ep-btn-outline" onClick={handleDisconnect}>
                  Disconnect
                </button>
                <button
                  className="ep-btn ep-btn-sm ep-btn-primary"
                  onClick={() => { setShowConnect(true); loadRepos(); }}
                >
                  + Link Repo
                </button>
              </>
            ) : (
              <button className="ep-btn ep-btn-sm ep-btn-primary" onClick={handleConnect}>
                <GithubIcon size={14} />
                &nbsp; Connect GitHub
              </button>
            )}
          </div>
        </div>
      </div>

      {/* ── Link repo modal ───────────────────────────────────────────── */}
      {showConnect && (
        <div className="ep-modal-overlay" onClick={() => setShowConnect(false)}>
          <div className="ep-modal" style={{ maxWidth: 540 }} onClick={e => e.stopPropagation()}>
            <div className="ep-modal-header">
              <span className="ep-modal-title">Link a GitHub Repository</span>
              <button className="ep-modal-close" onClick={() => setShowConnect(false)}>✕</button>
            </div>
            <div className="ep-modal-body" style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>

              {/* Subscription picker */}
              <div>
                <label className="ep-label">Hosting subscription</label>
                <select
                  className="ep-input"
                  value={newDeploy.subscription_id}
                  onChange={e => setNewDeploy(p => ({ ...p, subscription_id: e.target.value }))}
                >
                  <option value="">Select subscription…</option>
                  {subscriptions.map(s => (
                    <option key={s.id} value={s.id}>
                      {s.system_username} ({s.home_directory ?? `/home/${s.system_username}`})
                    </option>
                  ))}
                </select>
              </div>

              {/* Repo search */}
              <div>
                <label className="ep-label">Repository</label>
                <input
                  className="ep-input"
                  placeholder="Search repos…"
                  value={repoSearch}
                  onChange={e => setRepoSearch(e.target.value)}
                />
                <div style={{
                  marginTop: 6, maxHeight: 220, overflowY: "auto",
                  border: "1px solid var(--ep-border)", borderRadius: 8,
                }}>
                  {filteredRepos.length === 0 ? (
                    <div style={{ padding: "1rem", color: "var(--ep-muted)", fontSize: "0.85rem", textAlign: "center" }}>
                      {repos.length === 0 ? "Loading repos…" : "No repos match."}
                    </div>
                  ) : filteredRepos.map(r => (
                    <div
                      key={r.id}
                      onClick={() => setNewDeploy(p => ({ ...p, repo_full_name: r.full_name, branch: r.default_branch }))}
                      style={{
                        padding: "0.65rem 1rem",
                        cursor: "pointer",
                        borderBottom: "1px solid var(--ep-border)",
                        background: newDeploy.repo_full_name === r.full_name
                          ? "var(--ep-primary-faint)" : "transparent",
                        display: "flex", justifyContent: "space-between", alignItems: "center",
                      }}
                    >
                      <div>
                        <div style={{ fontWeight: 500, fontSize: "0.9rem" }}>{r.full_name}</div>
                        {r.description && (
                          <div style={{ fontSize: "0.78rem", color: "var(--ep-muted)", marginTop: 2 }}>
                            {r.description.slice(0, 60)}{r.description.length > 60 ? "…" : ""}
                          </div>
                        )}
                      </div>
                      <span style={{ fontSize: "0.75rem", color: "var(--ep-muted)" }}>
                        {r.private ? "🔒" : "🌐"} {r.default_branch}
                      </span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Branch */}
              <div>
                <label className="ep-label">Branch to deploy</label>
                <input
                  className="ep-input"
                  value={newDeploy.branch}
                  onChange={e => setNewDeploy(p => ({ ...p, branch: e.target.value }))}
                  placeholder="main"
                />
                <div style={{ fontSize: "0.78rem", color: "var(--ep-muted)", marginTop: 4 }}>
                  EuPanel will deploy every time you push to this branch.
                </div>
              </div>

              {/* Selected summary */}
              {newDeploy.repo_full_name && (
                <div style={{
                  background: "var(--ep-surface-2)", borderRadius: 8,
                  padding: "0.75rem 1rem", fontSize: "0.85rem",
                }}>
                  <strong>{newDeploy.repo_full_name}</strong> · branch <code>{newDeploy.branch}</code>
                  <br />
                  <span style={{ color: "var(--ep-muted)" }}>
                    Will be deployed to <code>/home/{subscriptions.find(s => s.id === newDeploy.subscription_id)?.system_username ?? "…"}/public_html</code>
                  </span>
                </div>
              )}

              {formError && (
                <div style={{ color: "var(--ep-danger)", fontSize: "0.85rem" }}>{formError}</div>
              )}
            </div>
            <div className="ep-modal-footer">
              <button className="ep-btn ep-btn-outline" onClick={() => setShowConnect(false)}>Cancel</button>
              <button
                className="ep-btn ep-btn-primary"
                onClick={handleCreateDeploy}
                disabled={submitting}
              >
                {submitting ? "Linking…" : "Link & Deploy Now"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Deploy log modal ──────────────────────────────────────────── */}
      {selectedLog && (
        <div className="ep-modal-overlay" onClick={() => setSelectedLog(null)}>
          <div className="ep-modal" style={{ maxWidth: 640 }} onClick={e => e.stopPropagation()}>
            <div className="ep-modal-header">
              <span className="ep-modal-title">Deploy Log — {selectedLog.repo_full_name}</span>
              <button className="ep-modal-close" onClick={() => setSelectedLog(null)}>✕</button>
            </div>
            <div className="ep-modal-body">
              <pre style={{
                background: "#0d1117", color: "#e6edf3",
                borderRadius: 8, padding: "1rem",
                fontSize: "0.78rem", lineHeight: 1.6,
                overflowX: "auto", maxHeight: 400,
                whiteSpace: "pre-wrap",
              }}>
                {selectedLog.deploy_log ?? "No log available."}
              </pre>
            </div>
          </div>
        </div>
      )}

      {/* ── Deploys table ─────────────────────────────────────────────── */}
      <div className="ep-card">
        <div style={{ padding: "1rem 1.5rem", borderBottom: "1px solid var(--ep-border)" }}>
          <span style={{ fontWeight: 600 }}>Auto-deploy connections</span>
          <span style={{
            marginLeft: 8, background: "var(--ep-surface-2)",
            borderRadius: 999, padding: "2px 8px", fontSize: "0.78rem",
          }}>{deploys.length}</span>
        </div>

        {deploys.length === 0 ? (
          <div style={{ padding: "3rem", textAlign: "center", color: "var(--ep-muted)" }}>
            <GithubIcon size={32} />
            <div style={{ marginTop: "0.75rem", fontWeight: 500 }}>No repos linked yet</div>
            <div style={{ fontSize: "0.85rem", marginTop: 4 }}>
              {ghStatus?.connected
                ? 'Click "+ Link Repo" to connect a repository'
                : "Connect your GitHub account above to get started"}
            </div>
          </div>
        ) : (
          <div className="ep-table-wrap">
            <table className="ep-table">
              <thead>
                <tr>
                  <th>Repository</th>
                  <th>Branch</th>
                  <th>Last commit</th>
                  <th>Status</th>
                  <th>Deployed</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {deploys.map(d => (
                  <tr key={d.id}>
                    <td>
                      <a
                        href={`https://github.com/${d.repo_full_name}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        style={{ color: "var(--ep-primary)", fontWeight: 500 }}
                      >
                        {d.repo_full_name}
                      </a>
                      <div style={{ fontSize: "0.78rem", color: "var(--ep-muted)", marginTop: 2 }}>
                        {d.deploy_path}
                      </div>
                    </td>
                    <td>
                      <code style={{ fontSize: "0.82rem" }}>{d.branch}</code>
                    </td>
                    <td style={{ maxWidth: 220 }}>
                      {d.last_commit_sha ? (
                        <>
                          <code style={{ fontSize: "0.75rem", color: "var(--ep-muted)" }}>
                            {d.last_commit_sha.slice(0, 7)}
                          </code>
                          <div style={{ fontSize: "0.78rem", marginTop: 2 }}>
                            {d.last_commit_msg?.slice(0, 50) ?? ""}
                            {(d.last_commit_msg?.length ?? 0) > 50 ? "…" : ""}
                          </div>
                        </>
                      ) : (
                        <span style={{ color: "var(--ep-muted)", fontSize: "0.82rem" }}>—</span>
                      )}
                    </td>
                    <td><StatusBadge status={d.deploy_status} /></td>
                    <td style={{ color: "var(--ep-muted)", fontSize: "0.82rem" }}>
                      {timeAgo(d.last_deployed_at)}
                    </td>
                    <td>
                      <div style={{ display: "flex", gap: 6, justifyContent: "flex-end" }}>
                        {d.deploy_log && (
                          <button
                            className="ep-btn ep-btn-xs ep-btn-outline"
                            onClick={() => setSelectedLog(d)}
                          >
                            Log
                          </button>
                        )}
                        <button
                          className="ep-btn ep-btn-xs ep-btn-danger-outline"
                          onClick={() => handleDelete(d.id)}
                        >
                          Remove
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* ── How it works ──────────────────────────────────────────────── */}
      <div className="ep-card" style={{ padding: "1.25rem 1.5rem" }}>
        <div style={{ fontWeight: 600, marginBottom: "0.75rem" }}>How push-to-deploy works</div>
        <ol style={{ paddingLeft: "1.25rem", display: "flex", flexDirection: "column", gap: "0.4rem", fontSize: "0.85rem", color: "var(--ep-muted)" }}>
          <li>Connect your GitHub account and link a repository to a subscription.</li>
          <li>EuPanel automatically installs a webhook on the repo.</li>
          <li>Every time you <code>git push</code> to the tracked branch, GitHub notifies EuPanel.</li>
          <li>EuPanel verifies the signature and runs <code>git pull</code> on the server.</li>
          <li>Your site updates in seconds — no SSH needed.</li>
        </ol>
      </div>

    </div>
  );
}

// ── Inline GitHub icon ────────────────────────────────────────────────────────

function GithubIcon({ size = 20 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844a9.59 9.59 0 012.504.337c1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" />
    </svg>
  );
}
