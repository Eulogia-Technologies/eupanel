"use client";

import { useEffect, useState } from "react";

// ── Types ─────────────────────────────────────────────────────────────────────

interface Plan {
  id: string;
  name: string;
  description?: string;
  disk_limit: number;
  bandwidth_limit: number;
  ftp_accounts_limit: number;
  database_limit: number;
  domain_limit: number;
  price?: number;
  status: "active" | "inactive";
  created_at: string;
}

type PlanForm = Omit<Plan, "id" | "created_at">;

const EMPTY_FORM: PlanForm = {
  name: "",
  description: "",
  disk_limit: 1024,
  bandwidth_limit: 10240,
  ftp_accounts_limit: 1,
  database_limit: 1,
  domain_limit: 1,
  price: undefined,
  status: "active",
};

// ── Component ─────────────────────────────────────────────────────────────────

export function PlansScreen() {
  const [plans, setPlans] = useState<Plan[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingPlan, setEditingPlan] = useState<Plan | null>(null);
  const [form, setForm] = useState<PlanForm>(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);

  const API = process.env.NEXT_PUBLIC_FRONTEND_API_BASE ?? "/api";

  function authHeaders() {
    const token = localStorage.getItem("eupanel_token");
    return { "Content-Type": "application/json", Authorization: `Bearer ${token}` };
  }

  async function fetchPlans() {
    setLoading(true);
    try {
      const r = await fetch(`${API}/plans`, { headers: authHeaders() });
      const d = await r.json();
      setPlans(d.data ?? []);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { fetchPlans(); }, []);

  function openCreate() {
    setEditingPlan(null);
    setForm(EMPTY_FORM);
    setError(null);
    setShowModal(true);
  }

  function openEdit(plan: Plan) {
    setEditingPlan(plan);
    setForm({
      name: plan.name,
      description: plan.description ?? "",
      disk_limit: plan.disk_limit,
      bandwidth_limit: plan.bandwidth_limit,
      ftp_accounts_limit: plan.ftp_accounts_limit,
      database_limit: plan.database_limit,
      domain_limit: plan.domain_limit,
      price: plan.price,
      status: plan.status,
    });
    setError(null);
    setShowModal(true);
  }

  async function savePlan() {
    setSaving(true);
    setError(null);
    try {
      const url = editingPlan ? `${API}/plans/${editingPlan.id}` : `${API}/plans`;
      const method = editingPlan ? "PUT" : "POST";
      const r = await fetch(url, {
        method,
        headers: authHeaders(),
        body: JSON.stringify(form),
      });
      const d = await r.json();
      if (!r.ok) {
        setError(d.message ?? JSON.stringify(d.errors ?? d));
        return;
      }
      setShowModal(false);
      fetchPlans();
    } finally {
      setSaving(false);
    }
  }

  async function deletePlan(id: string) {
    const r = await fetch(`${API}/plans/${id}`, {
      method: "DELETE",
      headers: authHeaders(),
    });
    if (r.ok) {
      setDeleteConfirm(null);
      fetchPlans();
    }
  }

  function field(key: keyof PlanForm, value: unknown) {
    setForm((f) => ({ ...f, [key]: value }));
  }

  // ── Render ──────────────────────────────────────────────────────────────────

  return (
    <div className="ep-content">
      {/* Header */}
      <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", marginBottom: "2rem", gap: "1rem" }}>
        <div>
          <h1 style={{ fontSize: "1.375rem", fontWeight: 700, letterSpacing: "-0.02em", margin: 0 }}>
            Hosting Plans
          </h1>
          <p style={{ margin: "0.35rem 0 0", color: "var(--ep-text-muted)", fontSize: "0.875rem" }}>
            Define the resource limits customers can subscribe to.
          </p>
        </div>
        <button className="ep-btn ep-btn-primary ep-btn-sm" onClick={openCreate}>
          + New Plan
        </button>
      </div>

      {/* Plans table */}
      <div className="ep-card" style={{ padding: 0 }}>
        {loading ? (
          <div className="ep-skeleton-list">
            {[...Array(4)].map((_, i) => (
              <div key={i} className="ep-skeleton ep-skeleton-row" />
            ))}
          </div>
        ) : plans.length === 0 ? (
          <div style={{ padding: "4rem 2rem", textAlign: "center" }}>
            <p style={{ fontSize: "0.875rem", color: "var(--ep-text-muted)" }}>
              No plans yet. Create your first hosting plan.
            </p>
            <button className="ep-btn ep-btn-primary ep-btn-sm" style={{ marginTop: "1rem" }} onClick={openCreate}>
              Create Plan
            </button>
          </div>
        ) : (
          <table className="ep-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Disk</th>
                <th>Bandwidth</th>
                <th>Domains</th>
                <th>DBs</th>
                <th>FTP</th>
                <th>Price</th>
                <th>Status</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {plans.map((plan) => (
                <tr key={plan.id}>
                  <td>
                    <span style={{ fontWeight: 500 }}>{plan.name}</span>
                    {plan.description && (
                      <span style={{ display: "block", fontSize: "0.78rem", color: "var(--ep-text-muted)" }}>
                        {plan.description}
                      </span>
                    )}
                  </td>
                  <td className="ep-table-muted">{fmtMB(plan.disk_limit)}</td>
                  <td className="ep-table-muted">{fmtMB(plan.bandwidth_limit)}</td>
                  <td className="ep-table-muted">{plan.domain_limit}</td>
                  <td className="ep-table-muted">{plan.database_limit}</td>
                  <td className="ep-table-muted">{plan.ftp_accounts_limit}</td>
                  <td className="ep-table-muted">
                    {plan.price != null ? `$${Number(plan.price).toFixed(2)}/mo` : "—"}
                  </td>
                  <td>
                    <span className={`ep-badge ${plan.status === "active" ? "ep-badge-success" : "ep-badge-neutral"}`}>
                      {plan.status}
                    </span>
                  </td>
                  <td>
                    <div style={{ display: "flex", gap: "0.5rem", justifyContent: "flex-end" }}>
                      <button className="ep-btn ep-btn-ghost ep-btn-xs" onClick={() => openEdit(plan)}>
                        Edit
                      </button>
                      <button
                        className="ep-btn ep-btn-ghost ep-btn-xs"
                        style={{ color: "var(--ep-danger)" }}
                        onClick={() => setDeleteConfirm(plan.id)}
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Create/Edit Modal */}
      {showModal && (
        <div className="ep-modal-overlay" onClick={() => setShowModal(false)}>
          <div className="ep-modal" style={{ width: "min(600px, 95vw)" }} onClick={(e) => e.stopPropagation()}>
            <div className="ep-modal-header">
              <h2>{editingPlan ? "Edit Plan" : "New Hosting Plan"}</h2>
              <button className="ep-btn ep-btn-ghost ep-btn-xs" onClick={() => setShowModal(false)}>✕</button>
            </div>

            <div className="ep-modal-body" style={{ display: "grid", gap: "1rem" }}>
              {error && (
                <div className="ep-badge ep-badge-danger" style={{ padding: "0.6rem 0.75rem", borderRadius: "var(--ep-r-md)", fontSize: "0.84rem" }}>
                  {error}
                </div>
              )}

              <div className="ep-form-group">
                <label className="ep-label">Plan Name</label>
                <input className="ep-input" value={form.name} onChange={(e) => field("name", e.target.value)} placeholder="e.g. Starter, Pro, Business" />
              </div>

              <div className="ep-form-group">
                <label className="ep-label">Description</label>
                <input className="ep-input" value={form.description} onChange={(e) => field("description", e.target.value)} placeholder="Optional description" />
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0.75rem" }}>
                <div className="ep-form-group">
                  <label className="ep-label">Disk Limit (MB)</label>
                  <input className="ep-input" type="number" value={form.disk_limit} onChange={(e) => field("disk_limit", +e.target.value)} />
                </div>
                <div className="ep-form-group">
                  <label className="ep-label">Bandwidth (MB)</label>
                  <input className="ep-input" type="number" value={form.bandwidth_limit} onChange={(e) => field("bandwidth_limit", +e.target.value)} />
                </div>
                <div className="ep-form-group">
                  <label className="ep-label">Domain Limit</label>
                  <input className="ep-input" type="number" value={form.domain_limit} onChange={(e) => field("domain_limit", +e.target.value)} />
                </div>
                <div className="ep-form-group">
                  <label className="ep-label">Database Limit</label>
                  <input className="ep-input" type="number" value={form.database_limit} onChange={(e) => field("database_limit", +e.target.value)} />
                </div>
                <div className="ep-form-group">
                  <label className="ep-label">FTP Accounts</label>
                  <input className="ep-input" type="number" value={form.ftp_accounts_limit} onChange={(e) => field("ftp_accounts_limit", +e.target.value)} />
                </div>
                <div className="ep-form-group">
                  <label className="ep-label">Price / month (USD)</label>
                  <input className="ep-input" type="number" step="0.01" value={form.price ?? ""} onChange={(e) => field("price", e.target.value ? +e.target.value : undefined)} placeholder="Optional" />
                </div>
              </div>

              <div className="ep-form-group">
                <label className="ep-label">Status</label>
                <select className="ep-input" value={form.status} onChange={(e) => field("status", e.target.value)}>
                  <option value="active">Active</option>
                  <option value="inactive">Inactive</option>
                </select>
              </div>
            </div>

            <div className="ep-modal-footer">
              <button className="ep-btn ep-btn-ghost ep-btn-sm" onClick={() => setShowModal(false)}>Cancel</button>
              <button className="ep-btn ep-btn-primary ep-btn-sm" onClick={savePlan} disabled={saving}>
                {saving ? "Saving…" : editingPlan ? "Save Changes" : "Create Plan"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delete confirm */}
      {deleteConfirm && (
        <div className="ep-modal-overlay" onClick={() => setDeleteConfirm(null)}>
          <div className="ep-modal" style={{ width: "min(420px, 95vw)" }} onClick={(e) => e.stopPropagation()}>
            <div className="ep-modal-header">
              <h2>Delete Plan</h2>
              <button className="ep-btn ep-btn-ghost ep-btn-xs" onClick={() => setDeleteConfirm(null)}>✕</button>
            </div>
            <div className="ep-modal-body">
              <p style={{ color: "var(--ep-text-muted)", fontSize: "0.875rem" }}>
                This will permanently delete the plan. Existing subscriptions will not be affected.
              </p>
            </div>
            <div className="ep-modal-footer">
              <button className="ep-btn ep-btn-ghost ep-btn-sm" onClick={() => setDeleteConfirm(null)}>Cancel</button>
              <button className="ep-btn ep-btn-sm" style={{ background: "var(--ep-danger)", color: "#fff" }} onClick={() => deletePlan(deleteConfirm)}>
                Delete
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function fmtMB(mb: number): string {
  if (mb >= 1024 * 1024) return `${(mb / (1024 * 1024)).toFixed(0)} TB`;
  if (mb >= 1024) return `${(mb / 1024).toFixed(0)} GB`;
  return `${mb} MB`;
}
