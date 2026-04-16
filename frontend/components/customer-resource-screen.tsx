"use client";

import { FormEvent, useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { DashboardSidebar } from "@/components/dashboard-sidebar";
import { DashboardRole } from "@/lib/dashboard-nav";
import {
  IconPlus, IconX, IconSearch, IconRefresh, IconTrash,
} from "@/components/ui/icons";

// ── Types ─────────────────────────────────────────────────────────────────

export type ResourceColumn = { key: string; label: string; mono?: boolean };
export type ResourceField   = { key: string; label: string; placeholder?: string; type?: string; required?: boolean };

type Props = {
  title: string;
  endpoint: string;
  createEndpoint?: string;
  expectedRole?: DashboardRole;
  columns: ResourceColumn[];
  createFields?: ResourceField[];
};

// ── Status Badge ─────────────────────────────────────────────────────────

const STATUS_MAP: Record<string, string> = {
  active:        "ep-badge ep-badge-success",
  success:       "ep-badge ep-badge-success",
  running:       "ep-badge ep-badge-info",
  provisioning:  "ep-badge ep-badge-warning",
  pending:       "ep-badge ep-badge-pending",
  failed:        "ep-badge ep-badge-error",
  inactive:      "ep-badge ep-badge-neutral",
  deleted:       "ep-badge ep-badge-error",
  letsencrypt:   "ep-badge ep-badge-accent",
  mysql:         "ep-badge ep-badge-info",
  postgres:      "ep-badge ep-badge-info",
  postgresql:    "ep-badge ep-badge-info",
  mariadb:       "ep-badge ep-badge-info",
  php:           "ep-badge ep-badge-accent",
  nodejs:        "ep-badge ep-badge-success",
  dart:          "ep-badge ep-badge-accent",
  python:        "ep-badge ep-badge-warning",
  docker:        "ep-badge ep-badge-info",
};

function CellValue({ col, value }: { col: ResourceColumn; value: unknown }) {
  const str = value == null || value === "" ? "—" : String(value);
  const badgeCls = STATUS_MAP[str.toLowerCase()];

  if (badgeCls) {
    return <span className={badgeCls}>{str}</span>;
  }
  if (col.mono || col.key === "id") {
    return (
      <span className="ep-text-mono" style={{ color: "var(--ep-text-muted)" }}>
        {str.length > 18 ? str.slice(0, 16) + "…" : str}
      </span>
    );
  }
  return <>{str}</>;
}

// ── Modal ────────────────────────────────────────────────────────────────

function Modal({
  title,
  fields,
  onClose,
  onSubmit,
  submitting,
  error,
}: {
  title: string;
  fields: ResourceField[];
  onClose: () => void;
  onSubmit: (data: Record<string, string>) => Promise<void>;
  submitting: boolean;
  error: string;
}) {
  const [form, setForm] = useState<Record<string, string>>({});
  const firstRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    firstRef.current?.focus();
    function onKey(e: KeyboardEvent) { if (e.key === "Escape") onClose(); }
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [onClose]);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    await onSubmit(form);
  }

  return (
    <div className="ep-modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}>
      <div className="ep-modal" role="dialog" aria-modal aria-label={title}>
        <div className="ep-modal-header">
          <h2 className="ep-modal-title">Create {title}</h2>
          <button className="ep-btn-icon" onClick={onClose} aria-label="Close">
            <IconX size={14} />
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="ep-modal-body">
            {error && (
              <div className="ep-alert ep-alert-error">{error}</div>
            )}
            {fields.map((field, i) => (
              <div key={field.key} className="ep-input-group">
                <label className="ep-label" htmlFor={`field-${field.key}`}>
                  {field.label}
                  {field.required !== false && (
                    <span style={{ color: "var(--ep-error)", marginLeft: "0.2rem" }}>*</span>
                  )}
                </label>
                <input
                  id={`field-${field.key}`}
                  ref={i === 0 ? firstRef : undefined}
                  className="ep-input"
                  type={field.type ?? (field.key.includes("password") ? "password" : "text")}
                  value={form[field.key] ?? ""}
                  onChange={(e) => setForm((prev) => ({ ...prev, [field.key]: e.target.value }))}
                  placeholder={field.placeholder ?? field.label}
                />
              </div>
            ))}
          </div>

          <div className="ep-modal-footer">
            <button type="button" className="ep-btn ep-btn-ghost" onClick={onClose} disabled={submitting}>
              Cancel
            </button>
            <button type="submit" className="ep-btn ep-btn-primary" disabled={submitting}>
              {submitting ? (
                <>
                  <svg className="ep-spin" width="14" height="14" viewBox="0 0 14 14" fill="none">
                    <circle cx="7" cy="7" r="5.5" stroke="currentColor" strokeWidth="1.5" strokeDasharray="26" strokeDashoffset="10" />
                  </svg>
                  Creating…
                </>
              ) : (
                <>
                  <IconPlus size={13} />
                  Create
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// ── Main Component ────────────────────────────────────────────────────────

export function CustomerResourceScreen({
  title,
  endpoint,
  createEndpoint,
  expectedRole = "customer",
  columns,
  createFields = [],
}: Props) {
  const router = useRouter();
  const apiBase = useMemo(() => process.env.NEXT_PUBLIC_FRONTEND_API_BASE ?? "/api", []);

  const [rows, setRows]           = useState<Array<Record<string, unknown>>>([]);
  const [loading, setLoading]     = useState(true);
  const [error, setError]         = useState("");
  const [search, setSearch]       = useState("");
  const [showModal, setShowModal] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [createError, setCreateError] = useState("");
  const [deletingId, setDeletingId]   = useState<string | null>(null);

  const loadRows = useCallback(async (token: string) => {
    setLoading(true);
    setError("");
    try {
      const res = await fetch(`${apiBase}${endpoint}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const body = (await res.json()) as { data?: Array<Record<string, unknown>>; message?: string };
      if (!res.ok) throw new Error(body.message ?? "Failed to load.");
      setRows(body.data ?? []);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load data.");
    } finally {
      setLoading(false);
    }
  }, [apiBase, endpoint]);

  useEffect(() => {
    const token = localStorage.getItem("eupanel_token");
    const raw   = localStorage.getItem("eupanel_user");
    if (!token || !raw) { router.replace("/"); return; }
    const role = (JSON.parse(raw) as { role?: string }).role?.toLowerCase();
    if (role !== expectedRole) {
      router.replace(role === "admin" ? "/dashboard/admin" : role === "reseller" ? "/dashboard/reseller" : "/dashboard");
      return;
    }
    void loadRows(token);
  }, [expectedRole, loadRows, router]);

  function logout() {
    localStorage.removeItem("eupanel_token");
    localStorage.removeItem("eupanel_user");
    router.replace("/");
  }

  async function handleCreate(data: Record<string, string>) {
    const token = localStorage.getItem("eupanel_token");
    if (!token) return;
    setSubmitting(true);
    setCreateError("");
    try {
      const res = await fetch(`${apiBase}${createEndpoint ?? endpoint}`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
        body: JSON.stringify(data),
      });
      if (!res.ok) {
        const b = (await res.json()) as { message?: string };
        throw new Error(b.message ?? "Failed to create.");
      }
      setShowModal(false);
      await loadRows(token);
    } catch (e) {
      setCreateError(e instanceof Error ? e.message : "Failed to create.");
    } finally {
      setSubmitting(false);
    }
  }

  async function handleDelete(id: string) {
    const token = localStorage.getItem("eupanel_token");
    if (!token) return;
    setDeletingId(id);
    try {
      await fetch(`${apiBase}${endpoint}/${id}`, {
        method: "DELETE",
        headers: { Authorization: `Bearer ${token}` },
      });
      await loadRows(token);
    } catch { /* silent */ } finally {
      setDeletingId(null);
    }
  }

  const filtered = useMemo(() => {
    if (!search.trim()) return rows;
    const q = search.toLowerCase();
    return rows.filter((row) =>
      Object.values(row).some((v) => String(v ?? "").toLowerCase().includes(q))
    );
  }, [rows, search]);

  const showDelete = columns.some((c) => c.key === "id") || rows[0]?.id !== undefined;

  return (
    <div className="ep-shell">
      <DashboardSidebar role={expectedRole} onLogout={logout} />

      <main className="ep-main">
        {/* Top bar */}
        <div className="ep-topbar">
          <div className="ep-topbar-breadcrumb">
            <span style={{ color: "var(--ep-text-faint)" }}>Dashboard</span>
            <span style={{ margin: "0 0.35rem", color: "var(--ep-text-faint)" }}>/</span>
            <strong>{title}</strong>
          </div>
          <div style={{ display: "flex", gap: "0.5rem", alignItems: "center" }}>
            <button
              className="ep-btn-icon"
              onClick={() => { const t = localStorage.getItem("eupanel_token"); if (t) void loadRows(t); }}
              title="Refresh"
            >
              <IconRefresh size={14} />
            </button>
            {createFields.length > 0 && (
              <button className="ep-btn ep-btn-primary ep-btn-sm" onClick={() => { setCreateError(""); setShowModal(true); }}>
                <IconPlus size={13} />
                New {title.replace(/s$/, "")}
              </button>
            )}
          </div>
        </div>

        <div className="ep-content">
          {/* Page header */}
          <div style={{ display: "flex", alignItems: "flex-end", justifyContent: "space-between", gap: "1rem", flexWrap: "wrap" }}>
            <div>
              <h1 style={{ fontSize: "1.375rem", fontWeight: 700, letterSpacing: "-0.02em" }}>{title}</h1>
              <p style={{ fontSize: "0.84rem", color: "var(--ep-text-muted)", marginTop: "0.2rem" }}>
                {loading ? "Loading…" : `${filtered.length} of ${rows.length} record${rows.length !== 1 ? "s" : ""}`}
              </p>
            </div>
          </div>

          {/* Table Card */}
          <div className="ep-card">
            {/* Search bar */}
            <div style={{ padding: "0.875rem 1.25rem", borderBottom: "1px solid var(--ep-border)", display: "flex", alignItems: "center", gap: "0.75rem" }}>
              <div className="ep-search-wrap" style={{ flex: 1, maxWidth: 320 }}>
                <IconSearch size={14} className="ep-search-icon" />
                <input
                  className="ep-search"
                  placeholder={`Search ${title.toLowerCase()}…`}
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                />
              </div>
              <span className="ep-badge ep-badge-neutral" style={{ flexShrink: 0 }}>
                {rows.length} total
              </span>
            </div>

            {/* Error */}
            {error && (
              <div style={{ padding: "0.75rem 1.25rem" }}>
                <div className="ep-alert ep-alert-error">{error}</div>
              </div>
            )}

            {/* Table */}
            <div className="ep-table-wrap">
              {loading ? (
                <div style={{ padding: "1.25rem", display: "grid", gap: "0.6rem" }}>
                  {[1, 2, 3, 4].map((i) => (
                    <div key={i} className="ep-skeleton" style={{ height: "2.75rem", borderRadius: "var(--ep-r-md)" }} />
                  ))}
                </div>
              ) : filtered.length === 0 ? (
                <div className="ep-empty">
                  <div className="ep-empty-icon">
                    <IconSearch size={18} />
                  </div>
                  <div className="ep-empty-title">
                    {search ? "No matches found" : `No ${title.toLowerCase()} yet`}
                  </div>
                  <div className="ep-empty-desc">
                    {search
                      ? `Try a different search term.`
                      : createFields.length > 0
                        ? `Click "New ${title.replace(/s$/, "")}" to get started.`
                        : "Records will appear here once they are created."}
                  </div>
                  {!search && createFields.length > 0 && (
                    <button className="ep-btn ep-btn-primary ep-btn-sm" style={{ marginTop: "0.5rem" }} onClick={() => setShowModal(true)}>
                      <IconPlus size={13} />
                      New {title.replace(/s$/, "")}
                    </button>
                  )}
                </div>
              ) : (
                <table className="ep-table">
                  <thead>
                    <tr>
                      {columns.map((col) => (
                        <th key={col.key}>{col.label}</th>
                      ))}
                      {showDelete && <th style={{ width: "3rem" }} />}
                    </tr>
                  </thead>
                  <tbody>
                    {filtered.map((row, idx) => {
                      const rowId = String(row.id ?? idx);
                      return (
                        <tr key={rowId}>
                          {columns.map((col) => (
                            <td key={col.key}>
                              <CellValue col={col} value={row[col.key]} />
                            </td>
                          ))}
                          {showDelete && (
                            <td>
                              <button
                                className="ep-btn-icon"
                                title="Delete"
                                disabled={deletingId === rowId}
                                onClick={() => {
                                  if (confirm(`Delete this ${title.replace(/s$/, "").toLowerCase()}?`)) {
                                    void handleDelete(rowId);
                                  }
                                }}
                                style={{ color: "var(--ep-error)" }}
                              >
                                {deletingId === rowId ? (
                                  <svg className="ep-spin" width="12" height="12" viewBox="0 0 14 14" fill="none">
                                    <circle cx="7" cy="7" r="5.5" stroke="currentColor" strokeWidth="1.5" strokeDasharray="26" strokeDashoffset="10" />
                                  </svg>
                                ) : (
                                  <IconTrash size={13} />
                                )}
                              </button>
                            </td>
                          )}
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              )}
            </div>
          </div>
        </div>
      </main>

      {/* Create Modal */}
      {showModal && (
        <Modal
          title={title.replace(/s$/, "")}
          fields={createFields}
          onClose={() => setShowModal(false)}
          onSubmit={handleCreate}
          submitting={submitting}
          error={createError}
        />
      )}
    </div>
  );
}
