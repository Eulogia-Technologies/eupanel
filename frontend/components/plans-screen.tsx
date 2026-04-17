"use client";

import { useEffect, useRef, useState } from "react";
import {
  HardDrive, Wifi, Globe, Link2, Database, FolderOpen,
  Cpu, Zap, Plus, Pencil, Trash2, X, CheckCircle2, Circle,
  Layers, ChevronUp, ChevronDown, Sparkles,
} from "lucide-react";
import { cn } from "@/lib/utils";

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
  subdomain_limit: number;
  ram_limit?: number;
  status: "active" | "inactive";
  created_at: string;
}

type PlanForm = Omit<Plan, "id" | "created_at">;

const EMPTY_FORM: PlanForm = {
  name: "",
  description: "",
  disk_limit: 10240,
  bandwidth_limit: 102400,
  ftp_accounts_limit: 1,
  database_limit: 1,
  domain_limit: 1,
  subdomain_limit: 10,
  ram_limit: undefined,
  status: "active",
};

// ── Component ─────────────────────────────────────────────────────────────────

export function PlansScreen() {
  const [plans, setPlans]                 = useState<Plan[]>([]);
  const [loading, setLoading]             = useState(true);
  const [showModal, setShowModal]         = useState(false);
  const [editingPlan, setEditingPlan]     = useState<Plan | null>(null);
  const [form, setForm]                   = useState<PlanForm>(EMPTY_FORM);
  const [saving, setSaving]               = useState(false);
  const [error, setError]                 = useState<string | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState<Plan | null>(null);

  const API = process.env.NEXT_PUBLIC_FRONTEND_API_BASE ?? "/api";

  function authHeaders() {
    const token = typeof window !== "undefined" ? localStorage.getItem("eupanel_token") : "";
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
      name:               plan.name,
      description:        plan.description ?? "",
      disk_limit:         plan.disk_limit,
      bandwidth_limit:    plan.bandwidth_limit,
      ftp_accounts_limit: plan.ftp_accounts_limit,
      database_limit:     plan.database_limit,
      domain_limit:       plan.domain_limit,
      subdomain_limit:    plan.subdomain_limit ?? 10,
      ram_limit:          plan.ram_limit,
      status:             plan.status,
    });
    setError(null);
    setShowModal(true);
  }

  async function savePlan() {
    setSaving(true);
    setError(null);
    try {
      const url    = editingPlan ? `${API}/plans/${editingPlan.id}` : `${API}/plans`;
      const method = editingPlan ? "PUT" : "POST";
      const r = await fetch(url, { method, headers: authHeaders(), body: JSON.stringify(form) });
      const d = await r.json();
      if (!r.ok) { setError(d.message ?? JSON.stringify(d.errors ?? d)); return; }
      setShowModal(false);
      fetchPlans();
    } finally {
      setSaving(false);
    }
  }

  async function deletePlan(plan: Plan) {
    const r = await fetch(`${API}/plans/${plan.id}`, { method: "DELETE", headers: authHeaders() });
    if (r.ok) { setDeleteConfirm(null); fetchPlans(); }
  }

  function field(key: keyof PlanForm, value: unknown) {
    setForm((f) => ({ ...f, [key]: value }));
  }

  // ── Render ──────────────────────────────────────────────────────────────────

  return (
    <div className="relative min-h-screen" style={{ background: "linear-gradient(135deg, #06080f 0%, #080c12 60%, #04070a 100%)" }}>

      {/* Ambient background orbs */}
      <div className="fixed inset-0 pointer-events-none" style={{ zIndex: 0 }}>
        <div style={{
          position: "absolute", width: 700, height: 700, borderRadius: "50%",
          background: "radial-gradient(circle, rgba(16,185,129,0.055) 0%, transparent 70%)",
          top: -200, right: -150,
        }} />
        <div style={{
          position: "absolute", width: 500, height: 500, borderRadius: "50%",
          background: "radial-gradient(circle, rgba(16,185,129,0.035) 0%, transparent 70%)",
          bottom: "10%", left: -100,
        }} />
        {/* Grid overlay */}
        <div style={{
          position: "absolute", inset: 0,
          backgroundImage: "linear-gradient(rgba(255,255,255,0.018) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.018) 1px, transparent 1px)",
          backgroundSize: "48px 48px",
          maskImage: "radial-gradient(ellipse at 50% 0%, black 20%, transparent 80%)",
        }} />
      </div>

      {/* Content */}
      <div className="relative" style={{ zIndex: 1, padding: "2rem 1.75rem", maxWidth: 1320, margin: "0 auto" }}>

        {/* ── Header ── */}
        <div className="flex items-start justify-between gap-4 mb-10">
          <div>
            <div className="flex items-center gap-2 mb-2">
              <div style={{
                display: "inline-flex", alignItems: "center", gap: 6,
                padding: "3px 10px", borderRadius: 999,
                background: "rgba(16,185,129,0.1)", border: "1px solid rgba(16,185,129,0.2)",
                fontSize: "0.7rem", fontWeight: 600, color: "#34d399",
                letterSpacing: "0.08em", textTransform: "uppercase",
              }}>
                <Sparkles size={10} />
                Hosting Plans
              </div>
            </div>
            <h1 style={{
              fontSize: "clamp(1.75rem, 3vw, 2.5rem)", fontWeight: 800,
              letterSpacing: "-0.04em", lineHeight: 1.05,
              background: "linear-gradient(135deg, #f1f5f9 0%, #94a3b8 100%)",
              WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent",
              backgroundClip: "text",
            }}>
              Service Plans
            </h1>
            <p style={{ marginTop: "0.5rem", color: "#475569", fontSize: "0.9375rem" }}>
              Define and manage resource limits for your customers.
            </p>
          </div>

          <button
            onClick={openCreate}
            style={{
              display: "inline-flex", alignItems: "center", gap: 8,
              padding: "0.6rem 1.25rem",
              background: "linear-gradient(135deg, #10b981 0%, #059669 100%)",
              border: "none", borderRadius: 12, color: "#fff",
              fontSize: "0.9rem", fontWeight: 600, cursor: "pointer",
              boxShadow: "0 0 0 1px rgba(16,185,129,0.4), 0 4px 20px rgba(16,185,129,0.28)",
              transition: "all 0.2s ease", whiteSpace: "nowrap",
            }}
            onMouseEnter={(e) => {
              (e.currentTarget as HTMLButtonElement).style.transform = "translateY(-2px)";
              (e.currentTarget as HTMLButtonElement).style.boxShadow = "0 0 0 1px rgba(16,185,129,0.5), 0 8px 32px rgba(16,185,129,0.38)";
            }}
            onMouseLeave={(e) => {
              (e.currentTarget as HTMLButtonElement).style.transform = "";
              (e.currentTarget as HTMLButtonElement).style.boxShadow = "0 0 0 1px rgba(16,185,129,0.4), 0 4px 20px rgba(16,185,129,0.28)";
            }}
          >
            <Plus size={16} />
            New Plan
          </button>
        </div>

        {/* ── Plans Grid ── */}
        {loading ? (
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(320px, 1fr))", gap: "1.25rem" }}>
            {[...Array(3)].map((_, i) => <SkeletonCard key={i} />)}
          </div>
        ) : plans.length === 0 ? (
          <EmptyState onCreate={openCreate} />
        ) : (
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(320px, 1fr))", gap: "1.25rem" }}>
            {plans.map((plan) => (
              <PlanCard key={plan.id} plan={plan} onEdit={() => openEdit(plan)} onDelete={() => setDeleteConfirm(plan)} />
            ))}
          </div>
        )}
      </div>

      {/* ── Create / Edit Modal ── */}
      {showModal && (
        <PlanModal
          editing={editingPlan}
          form={form}
          error={error}
          saving={saving}
          onField={field}
          onSave={savePlan}
          onClose={() => setShowModal(false)}
        />
      )}

      {/* ── Delete Confirm ── */}
      {deleteConfirm && (
        <div
          className="fixed inset-0 flex items-center justify-center p-4"
          style={{ background: "rgba(0,0,0,0.7)", backdropFilter: "blur(8px)", zIndex: 60 }}
          onClick={() => setDeleteConfirm(null)}
        >
          <div
            onClick={(e) => e.stopPropagation()}
            style={{
              width: "min(440px, 95vw)", borderRadius: 20,
              background: "rgba(10,14,20,0.95)", backdropFilter: "blur(24px)",
              border: "1px solid rgba(255,255,255,0.09)",
              boxShadow: "0 32px 80px rgba(0,0,0,0.6), 0 0 0 1px rgba(255,255,255,0.04)",
              animation: "planSlideUp 0.2s ease",
            }}
          >
            <div style={{ padding: "1.5rem", borderBottom: "1px solid rgba(255,255,255,0.06)" }}>
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <div style={{
                  width: 36, height: 36, borderRadius: 10, flexShrink: 0,
                  background: "rgba(239,68,68,0.12)", border: "1px solid rgba(239,68,68,0.2)",
                  display: "flex", alignItems: "center", justifyContent: "center",
                }}>
                  <Trash2 size={16} color="#f87171" />
                </div>
                <h2 style={{ fontSize: "1.0625rem", fontWeight: 700, color: "#f1f5f9", margin: 0 }}>Delete Plan</h2>
              </div>
            </div>
            <div style={{ padding: "1.25rem 1.5rem" }}>
              <p style={{ color: "#64748b", fontSize: "0.9rem", lineHeight: 1.6, margin: 0 }}>
                Are you sure you want to delete{" "}
                <span style={{ color: "#f1f5f9", fontWeight: 600 }}>{deleteConfirm.name}</span>?
                Existing subscriptions will not be affected.
              </p>
            </div>
            <div style={{ padding: "1rem 1.5rem", borderTop: "1px solid rgba(255,255,255,0.06)", display: "flex", justifyContent: "flex-end", gap: 10 }}>
              <GhostBtn onClick={() => setDeleteConfirm(null)}>Cancel</GhostBtn>
              <button
                onClick={() => deletePlan(deleteConfirm)}
                style={{
                  padding: "0.5rem 1.1rem", borderRadius: 10, border: "none", cursor: "pointer",
                  background: "linear-gradient(135deg, #ef4444, #dc2626)",
                  color: "#fff", fontWeight: 600, fontSize: "0.875rem",
                  boxShadow: "0 4px 16px rgba(239,68,68,0.3)",
                }}
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ── Plan Card ─────────────────────────────────────────────────────────────────

function PlanCard({ plan, onEdit, onDelete }: { plan: Plan; onEdit: () => void; onDelete: () => void }) {
  const [hovered, setHovered] = useState(false);

  return (
    <div
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        borderRadius: 20,
        background: "rgba(255,255,255,0.025)",
        border: `1px solid ${hovered ? "rgba(16,185,129,0.35)" : "rgba(255,255,255,0.07)"}`,
        boxShadow: hovered
          ? "0 0 0 1px rgba(16,185,129,0.18), 0 8px 40px rgba(16,185,129,0.10), 0 24px 60px rgba(0,0,0,0.5)"
          : "0 4px 24px rgba(0,0,0,0.4)",
        transform: hovered ? "translateY(-4px)" : "none",
        transition: "all 0.3s cubic-bezier(0.4,0,0.2,1)",
        backdropFilter: "blur(12px)",
        display: "flex", flexDirection: "column", overflow: "hidden",
      }}
    >
      {/* Card top stripe */}
      <div style={{
        height: 3,
        background: plan.status === "active"
          ? "linear-gradient(90deg, #10b981, #34d399, #10b981)"
          : "linear-gradient(90deg, #374151, #4b5563)",
        backgroundSize: "200% 100%",
        animation: plan.status === "active" ? "planGlow 3s ease-in-out infinite" : "none",
      }} />

      {/* Header */}
      <div style={{ padding: "1.25rem 1.25rem 1rem", display: "flex", alignItems: "flex-start", justifyContent: "space-between", gap: 8 }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <div style={{
              width: 32, height: 32, borderRadius: 10, flexShrink: 0,
              background: "linear-gradient(135deg, rgba(16,185,129,0.2), rgba(16,185,129,0.05))",
              border: "1px solid rgba(16,185,129,0.2)",
              display: "flex", alignItems: "center", justifyContent: "center",
            }}>
              <Layers size={15} color="#34d399" />
            </div>
            <h3 style={{ fontSize: "1rem", fontWeight: 700, color: "#f1f5f9", margin: 0, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
              {plan.name}
            </h3>
          </div>
          {plan.description && (
            <p style={{ fontSize: "0.78rem", color: "#475569", marginTop: "0.5rem", lineHeight: 1.5, margin: "0.4rem 0 0" }}>
              {plan.description}
            </p>
          )}
        </div>
        <StatusBadge status={plan.status} />
      </div>

      {/* Divider */}
      <div style={{ height: 1, background: "rgba(255,255,255,0.05)", margin: "0 1.25rem" }} />

      {/* Resources */}
      <div style={{ padding: "1rem 1.25rem", display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0.6rem", flex: 1 }}>
        <Res icon={<HardDrive size={13} />} label="Disk"       value={fmtMB(plan.disk_limit)} color="#818cf8" />
        <Res icon={<Wifi size={13} />}      label="Bandwidth"  value={fmtMB(plan.bandwidth_limit)} color="#38bdf8" />
        <Res icon={<Globe size={13} />}     label="Domains"    value={String(plan.domain_limit)} color="#34d399" />
        <Res icon={<Link2 size={13} />}     label="Subdomains" value={String(plan.subdomain_limit ?? 0)} color="#34d399" />
        <Res icon={<Database size={13} />}  label="Databases"  value={String(plan.database_limit)} color="#fb923c" />
        <Res icon={<FolderOpen size={13} />} label="FTP"       value={String(plan.ftp_accounts_limit)} color="#a78bfa" />
        {plan.ram_limit != null && (
          <Res icon={<Cpu size={13} />}     label="RAM"        value={fmtMB(plan.ram_limit)} color="#f472b6" />
        )}
      </div>

      {/* Footer actions */}
      <div style={{
        padding: "0.875rem 1.25rem",
        borderTop: "1px solid rgba(255,255,255,0.05)",
        display: "flex", gap: 8,
      }}>
        <button
          onClick={onEdit}
          style={{
            flex: 1, display: "flex", alignItems: "center", justifyContent: "center", gap: 6,
            padding: "0.45rem 0", borderRadius: 10, border: "1px solid rgba(255,255,255,0.08)",
            background: "rgba(255,255,255,0.04)", color: "#94a3b8",
            fontSize: "0.8rem", fontWeight: 500, cursor: "pointer",
            transition: "all 0.18s ease",
          }}
          onMouseEnter={(e) => {
            (e.currentTarget as HTMLElement).style.background = "rgba(16,185,129,0.1)";
            (e.currentTarget as HTMLElement).style.borderColor = "rgba(16,185,129,0.3)";
            (e.currentTarget as HTMLElement).style.color = "#34d399";
          }}
          onMouseLeave={(e) => {
            (e.currentTarget as HTMLElement).style.background = "rgba(255,255,255,0.04)";
            (e.currentTarget as HTMLElement).style.borderColor = "rgba(255,255,255,0.08)";
            (e.currentTarget as HTMLElement).style.color = "#94a3b8";
          }}
        >
          <Pencil size={13} /> Edit
        </button>
        <button
          onClick={onDelete}
          style={{
            padding: "0.45rem 0.75rem", borderRadius: 10, border: "1px solid rgba(255,255,255,0.08)",
            background: "rgba(255,255,255,0.04)", color: "#64748b",
            fontSize: "0.8rem", cursor: "pointer", display: "flex", alignItems: "center",
            transition: "all 0.18s ease",
          }}
          onMouseEnter={(e) => {
            (e.currentTarget as HTMLElement).style.background = "rgba(239,68,68,0.1)";
            (e.currentTarget as HTMLElement).style.borderColor = "rgba(239,68,68,0.25)";
            (e.currentTarget as HTMLElement).style.color = "#f87171";
          }}
          onMouseLeave={(e) => {
            (e.currentTarget as HTMLElement).style.background = "rgba(255,255,255,0.04)";
            (e.currentTarget as HTMLElement).style.borderColor = "rgba(255,255,255,0.08)";
            (e.currentTarget as HTMLElement).style.color = "#64748b";
          }}
        >
          <Trash2 size={13} />
        </button>
      </div>
    </div>
  );
}

// ── Plan Modal ────────────────────────────────────────────────────────────────

function PlanModal({
  editing, form, error, saving, onField, onSave, onClose,
}: {
  editing: Plan | null;
  form: PlanForm;
  error: string | null;
  saving: boolean;
  onField: (key: keyof PlanForm, value: unknown) => void;
  onSave: () => void;
  onClose: () => void;
}) {
  const overlayRef = useRef<HTMLDivElement>(null);

  return (
    <div
      ref={overlayRef}
      className="fixed inset-0 flex items-center justify-center p-4"
      style={{ background: "rgba(0,0,0,0.75)", backdropFilter: "blur(10px)", zIndex: 60, overflowY: "auto" }}
      onClick={(e) => { if (e.target === overlayRef.current) onClose(); }}
    >
      <div
        style={{
          width: "min(680px, 95vw)", maxHeight: "calc(100vh - 3rem)", overflowY: "auto",
          borderRadius: 24, background: "rgba(8,12,20,0.97)", backdropFilter: "blur(32px)",
          border: "1px solid rgba(255,255,255,0.09)",
          boxShadow: "0 0 0 1px rgba(16,185,129,0.08), 0 40px 100px rgba(0,0,0,0.7)",
          animation: "planSlideUp 0.22s cubic-bezier(0.4,0,0.2,1)",
          scrollbarWidth: "thin", scrollbarColor: "rgba(255,255,255,0.1) transparent",
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Modal header */}
        <div style={{
          padding: "1.5rem 1.75rem 1.25rem",
          borderBottom: "1px solid rgba(255,255,255,0.06)",
          display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12,
          position: "sticky", top: 0, zIndex: 1,
          background: "rgba(8,12,20,0.98)", backdropFilter: "blur(32px)",
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{
              width: 40, height: 40, borderRadius: 12,
              background: "linear-gradient(135deg, rgba(16,185,129,0.2), rgba(16,185,129,0.05))",
              border: "1px solid rgba(16,185,129,0.25)",
              display: "flex", alignItems: "center", justifyContent: "center",
            }}>
              <Layers size={18} color="#34d399" />
            </div>
            <div>
              <h2 style={{ fontSize: "1.125rem", fontWeight: 700, color: "#f1f5f9", margin: 0 }}>
                {editing ? "Edit Plan" : "New Hosting Plan"}
              </h2>
              <p style={{ fontSize: "0.78rem", color: "#475569", margin: "2px 0 0" }}>
                {editing ? "Update plan configuration" : "Configure resource limits"}
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            style={{
              width: 32, height: 32, borderRadius: 8,
              background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.08)",
              color: "#64748b", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
              transition: "all 0.15s",
            }}
            onMouseEnter={(e) => { (e.currentTarget as HTMLElement).style.background = "rgba(255,255,255,0.1)"; (e.currentTarget as HTMLElement).style.color = "#f1f5f9"; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLElement).style.background = "rgba(255,255,255,0.05)"; (e.currentTarget as HTMLElement).style.color = "#64748b"; }}
          >
            <X size={15} />
          </button>
        </div>

        {/* Modal body */}
        <div style={{ padding: "1.5rem 1.75rem", display: "grid", gap: "1.75rem" }}>
          {/* Error */}
          {error && (
            <div style={{
              padding: "0.75rem 1rem", borderRadius: 10,
              background: "rgba(239,68,68,0.08)", border: "1px solid rgba(239,68,68,0.2)",
              color: "#f87171", fontSize: "0.875rem",
            }}>
              {error}
            </div>
          )}

          {/* Basic Info */}
          <Section label="Basic Info" icon={<Zap size={13} color="#fbbf24" />}>
            <div style={{ display: "grid", gap: "1rem" }}>
              <Field label="Plan Name *">
                <Input
                  value={form.name}
                  onChange={(v) => onField("name", v)}
                  placeholder="e.g. Starter, Pro, Business"
                />
              </Field>
              <Field label="Description">
                <Input
                  value={form.description ?? ""}
                  onChange={(v) => onField("description", v)}
                  placeholder="Short description shown to customers"
                />
              </Field>
              <Field label="Status">
                <Select
                  value={form.status}
                  onChange={(v) => onField("status", v)}
                  options={[{ label: "Active", value: "active" }, { label: "Inactive", value: "inactive" }]}
                />
              </Field>
            </div>
          </Section>

          {/* Storage & Bandwidth */}
          <Section label="Storage & Bandwidth" icon={<HardDrive size={13} color="#818cf8" />}>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1rem" }}>
              <Field label="Disk Limit (MB)" hint={fmtMB(form.disk_limit)}>
                <Input type="number" min={1} value={String(form.disk_limit)} onChange={(v) => onField("disk_limit", +v)} />
              </Field>
              <Field label="Bandwidth / month (MB)" hint={fmtMB(form.bandwidth_limit)}>
                <Input type="number" min={1} value={String(form.bandwidth_limit)} onChange={(v) => onField("bandwidth_limit", +v)} />
              </Field>
              <Field label="RAM Limit (MB)" hint={form.ram_limit ? fmtMB(form.ram_limit) : "Unlimited"}>
                <Input
                  type="number" min={0}
                  value={form.ram_limit != null ? String(form.ram_limit) : ""}
                  onChange={(v) => onField("ram_limit", v ? +v : undefined)}
                  placeholder="Leave empty for unlimited"
                />
              </Field>
            </div>
          </Section>

          {/* Hosting Limits */}
          <Section label="Hosting Limits" icon={<Globe size={13} color="#34d399" />}>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1rem" }}>
              <Field label="Domains">
                <Input type="number" min={0} value={String(form.domain_limit)} onChange={(v) => onField("domain_limit", +v)} />
              </Field>
              <Field label="Subdomains">
                <Input type="number" min={0} value={String(form.subdomain_limit)} onChange={(v) => onField("subdomain_limit", +v)} />
              </Field>
              <Field label="Databases">
                <Input type="number" min={0} value={String(form.database_limit)} onChange={(v) => onField("database_limit", +v)} />
              </Field>
              <Field label="FTP Accounts">
                <Input type="number" min={0} value={String(form.ftp_accounts_limit)} onChange={(v) => onField("ftp_accounts_limit", +v)} />
              </Field>
            </div>
          </Section>
        </div>

        {/* Modal footer */}
        <div style={{
          padding: "1.25rem 1.75rem",
          borderTop: "1px solid rgba(255,255,255,0.06)",
          display: "flex", justifyContent: "flex-end", gap: 10,
          position: "sticky", bottom: 0,
          background: "rgba(8,12,20,0.98)", backdropFilter: "blur(32px)",
        }}>
          <GhostBtn onClick={onClose}>Cancel</GhostBtn>
          <button
            onClick={onSave}
            disabled={saving}
            style={{
              padding: "0.6rem 1.4rem", borderRadius: 10, border: "none", cursor: saving ? "not-allowed" : "pointer",
              background: saving ? "rgba(16,185,129,0.4)" : "linear-gradient(135deg, #10b981, #059669)",
              color: "#fff", fontWeight: 600, fontSize: "0.9rem",
              boxShadow: saving ? "none" : "0 4px 20px rgba(16,185,129,0.3)",
              transition: "all 0.2s ease", opacity: saving ? 0.7 : 1,
              display: "flex", alignItems: "center", gap: 8,
            }}
          >
            {saving && <SpinnerIcon />}
            {saving ? "Saving…" : editing ? "Save Changes" : "Create Plan"}
          </button>
        </div>
      </div>
    </div>
  );
}

// ── Sub-components ─────────────────────────────────────────────────────────────

function StatusBadge({ status }: { status: "active" | "inactive" }) {
  const active = status === "active";
  return (
    <div style={{
      display: "inline-flex", alignItems: "center", gap: 5, padding: "3px 10px",
      borderRadius: 999, flexShrink: 0,
      background: active ? "rgba(16,185,129,0.1)" : "rgba(100,116,139,0.1)",
      border: `1px solid ${active ? "rgba(16,185,129,0.25)" : "rgba(100,116,139,0.2)"}`,
    }}>
      {active ? (
        <span style={{ width: 6, height: 6, borderRadius: "50%", background: "#10b981", display: "block", boxShadow: "0 0 6px rgba(16,185,129,0.7)", animation: "planPulse 2s ease-in-out infinite" }} />
      ) : (
        <span style={{ width: 6, height: 6, borderRadius: "50%", background: "#475569", display: "block" }} />
      )}
      <span style={{ fontSize: "0.7rem", fontWeight: 600, color: active ? "#34d399" : "#64748b", letterSpacing: "0.04em" }}>
        {status}
      </span>
    </div>
  );
}

function Res({ icon, label, value, color }: { icon: React.ReactNode; label: string; value: string; color: string }) {
  return (
    <div style={{
      display: "flex", alignItems: "center", gap: 7,
      padding: "0.45rem 0.65rem", borderRadius: 8,
      background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.05)",
    }}>
      <span style={{ color, opacity: 0.8, display: "flex", flexShrink: 0 }}>{icon}</span>
      <span style={{ fontSize: "0.72rem", color: "#475569", flex: 1, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{label}</span>
      <span style={{ fontSize: "0.78rem", fontWeight: 700, color: "#94a3b8", whiteSpace: "nowrap" }}>{value}</span>
    </div>
  );
}

function Section({ label, icon, children }: { label: string; icon: React.ReactNode; children: React.ReactNode }) {
  return (
    <div>
      <div style={{ display: "flex", alignItems: "center", gap: 7, marginBottom: "0.875rem" }}>
        <div style={{
          width: 22, height: 22, borderRadius: 6,
          background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.07)",
          display: "flex", alignItems: "center", justifyContent: "center",
        }}>{icon}</div>
        <span style={{ fontSize: "0.72rem", fontWeight: 700, textTransform: "uppercase", letterSpacing: "0.08em", color: "#475569" }}>
          {label}
        </span>
        <div style={{ flex: 1, height: 1, background: "rgba(255,255,255,0.05)" }} />
      </div>
      {children}
    </div>
  );
}

function Field({ label, hint, children }: { label: string; hint?: string; children: React.ReactNode }) {
  return (
    <div style={{ display: "grid", gap: "0.4rem" }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <label style={{ fontSize: "0.8rem", fontWeight: 600, color: "#94a3b8" }}>{label}</label>
        {hint && <span style={{ fontSize: "0.72rem", color: "#10b981", fontWeight: 500 }}>{hint}</span>}
      </div>
      {children}
    </div>
  );
}

function Input({ value, onChange, placeholder, type = "text", min }: {
  value: string; onChange: (v: string) => void;
  placeholder?: string; type?: string; min?: number;
}) {
  const [focused, setFocused] = useState(false);
  return (
    <input
      type={type}
      min={min}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      onFocus={() => setFocused(true)}
      onBlur={() => setFocused(false)}
      placeholder={placeholder}
      style={{
        width: "100%", padding: "0.6rem 0.875rem",
        borderRadius: 10, border: `1px solid ${focused ? "rgba(16,185,129,0.5)" : "rgba(255,255,255,0.08)"}`,
        background: focused ? "rgba(16,185,129,0.04)" : "rgba(255,255,255,0.04)",
        color: "#f1f5f9", fontSize: "0.9rem", fontFamily: "inherit", outline: "none",
        boxShadow: focused ? "0 0 0 3px rgba(16,185,129,0.12)" : "none",
        transition: "all 0.18s ease",
      }}
    />
  );
}

function Select({ value, onChange, options }: { value: string; onChange: (v: string) => void; options: { label: string; value: string }[] }) {
  const [focused, setFocused] = useState(false);
  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value)}
      onFocus={() => setFocused(true)}
      onBlur={() => setFocused(false)}
      style={{
        width: "100%", padding: "0.6rem 0.875rem",
        borderRadius: 10, border: `1px solid ${focused ? "rgba(16,185,129,0.5)" : "rgba(255,255,255,0.08)"}`,
        background: "rgba(12,16,24,0.9)",
        color: "#f1f5f9", fontSize: "0.9rem", fontFamily: "inherit", outline: "none",
        boxShadow: focused ? "0 0 0 3px rgba(16,185,129,0.12)" : "none",
        transition: "all 0.18s ease", cursor: "pointer",
      }}
    >
      {options.map((o) => (
        <option key={o.value} value={o.value}>{o.label}</option>
      ))}
    </select>
  );
}

function GhostBtn({ onClick, children }: { onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      onClick={onClick}
      style={{
        padding: "0.6rem 1.25rem", borderRadius: 10,
        border: "1px solid rgba(255,255,255,0.1)", background: "rgba(255,255,255,0.04)",
        color: "#64748b", fontWeight: 500, fontSize: "0.875rem", cursor: "pointer",
        transition: "all 0.18s",
      }}
      onMouseEnter={(e) => { (e.currentTarget as HTMLElement).style.background = "rgba(255,255,255,0.08)"; (e.currentTarget as HTMLElement).style.color = "#f1f5f9"; }}
      onMouseLeave={(e) => { (e.currentTarget as HTMLElement).style.background = "rgba(255,255,255,0.04)"; (e.currentTarget as HTMLElement).style.color = "#64748b"; }}
    >
      {children}
    </button>
  );
}

function SkeletonCard() {
  return (
    <div style={{
      borderRadius: 20, background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.05)",
      overflow: "hidden", height: 340,
    }}>
      <div style={{ height: 3, background: "rgba(255,255,255,0.04)" }} />
      <div style={{ padding: "1.25rem" }}>
        <div style={{ display: "flex", gap: 10, alignItems: "center", marginBottom: "1.25rem" }}>
          <div className="plan-skeleton" style={{ width: 32, height: 32, borderRadius: 10 }} />
          <div className="plan-skeleton" style={{ width: "60%", height: 18, borderRadius: 6 }} />
        </div>
        {[...Array(5)].map((_, i) => (
          <div key={i} className="plan-skeleton" style={{ height: 32, borderRadius: 8, marginBottom: 8 }} />
        ))}
      </div>
    </div>
  );
}

function EmptyState({ onCreate }: { onCreate: () => void }) {
  return (
    <div style={{
      borderRadius: 24, padding: "5rem 2rem", textAlign: "center",
      background: "rgba(255,255,255,0.02)", border: "1px dashed rgba(255,255,255,0.08)",
    }}>
      <div style={{
        width: 56, height: 56, borderRadius: 16, margin: "0 auto 1.25rem",
        background: "rgba(16,185,129,0.1)", border: "1px solid rgba(16,185,129,0.2)",
        display: "flex", alignItems: "center", justifyContent: "center",
      }}>
        <Layers size={24} color="#34d399" />
      </div>
      <h3 style={{ fontSize: "1.1rem", fontWeight: 700, color: "#f1f5f9", margin: "0 0 0.5rem" }}>No plans yet</h3>
      <p style={{ fontSize: "0.875rem", color: "#475569", margin: "0 0 1.5rem" }}>Create your first hosting plan to get started.</p>
      <button
        onClick={onCreate}
        style={{
          padding: "0.65rem 1.5rem", borderRadius: 10, border: "none", cursor: "pointer",
          background: "linear-gradient(135deg, #10b981, #059669)", color: "#fff",
          fontWeight: 600, fontSize: "0.9rem",
          boxShadow: "0 4px 20px rgba(16,185,129,0.3)", display: "inline-flex", alignItems: "center", gap: 8,
        }}
      >
        <Plus size={15} /> Create Plan
      </button>
    </div>
  );
}

function SpinnerIcon() {
  return (
    <span style={{
      width: 14, height: 14, borderRadius: "50%",
      border: "2px solid rgba(255,255,255,0.3)", borderTopColor: "#fff",
      display: "inline-block", animation: "ep-spin 0.6s linear infinite",
    }} />
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function fmtMB(mb: number): string {
  if (mb >= 1024 * 1024) return `${(mb / (1024 * 1024)).toFixed(0)} TB`;
  if (mb >= 1024) return `${(mb / 1024).toFixed(0)} GB`;
  return `${mb} MB`;
}
