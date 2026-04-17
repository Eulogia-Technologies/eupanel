"use client";

import { Fragment, useEffect, useMemo, useRef, useState } from "react";
import { ActionButton } from "@/components/websites-domains/action-button";
import {
  AppTemplate,
  DeployRuntime,
  DeploySource,
  DomainRecord,
} from "@/components/websites-domains/types";
import {
  IconGlobe, IconPlus, IconSearch, IconX, IconCheck,
} from "@/components/ui/icons";

// ─── Types ───────────────────────────────────────────────────────────────────

type WebsitesDomainsScreenProps = {
  role: "admin" | "customer" | "reseller";
};

type DashboardUser = { role?: string };

// ─── Static config ────────────────────────────────────────────────────────────

const SITE_STATUS: Record<string, { cls: string; label: string }> = {
  active:    { cls: "ep-badge ep-badge-success", label: "Active" },
  suspended: { cls: "ep-badge ep-badge-warning", label: "Suspended" },
};

const DEPLOY_STATUS: Record<string, { cls: string; label: string }> = {
  "Deployed":     { cls: "ep-badge ep-badge-success", label: "Deployed" },
  "Deploying":    { cls: "ep-badge ep-badge-info",    label: "Deploying…" },
  "Not Deployed": { cls: "ep-badge ep-badge-neutral", label: "Not Deployed" },
};

// Steps shown in the Git deploy workflow explanation
const GIT_WORKFLOW_STEPS = [
  {
    n: "1",
    label: "Connect your repository",
    desc: "Link GitHub, GitLab, Bitbucket, or any Git provider via URL.",
  },
  {
    n: "2",
    label: "Choose a branch",
    desc: "Select the branch to deploy (e.g. main, production).",
  },
  {
    n: "3",
    label: "Push to deploy",
    desc: "Every push to that branch triggers a fresh, controlled deployment.",
  },
];

const DEPLOY_METHODS: {
  id: DeploySource;
  label: string;
  desc: string;
  recommended?: boolean;
}[] = [
  {
    id: "git",
    label: "Git",
    desc: "Connect a repository and deploy from any branch. Best for production — every push deploys safely.",
    recommended: true,
  },
  {
    id: "files",
    label: "Files Upload",
    desc: "Upload a ZIP archive and deploy its contents directly to your domain.",
  },
  {
    id: "app",
    label: "Create App",
    desc: "Scaffold from a framework template — Laravel, Node.js, Flint Dart, or Static.",
  },
];

const APP_TEMPLATES: {
  id: AppTemplate;
  label: string;
  runtime: DeployRuntime | null;
  desc: string;
}[] = [
  { id: "static",     label: "Static Site",   runtime: null,     desc: "HTML + CSS + JS, no server required" },
  { id: "laravel",    label: "Laravel",        runtime: "php",    desc: "Full-stack PHP framework" },
  { id: "nodejs",     label: "Node.js App",    runtime: "nodejs", desc: "Express, Fastify, or any Node framework" },
  { id: "flint-dart", label: "Flint Dart App", runtime: "dart",   desc: "High-performance Dart backend" },
];

const RUNTIMES: { id: DeployRuntime; label: string }[] = [
  { id: "php",    label: "PHP" },
  { id: "nodejs", label: "Node.js" },
  { id: "dart",   label: "Dart" },
  { id: "python", label: "Python" },
  { id: "docker", label: "Docker" },
];

// ─── Component ────────────────────────────────────────────────────────────────

export function WebsitesDomainsScreen({ role }: WebsitesDomainsScreenProps) {
  const router = useRouter();
  const apiBase = process.env.NEXT_PUBLIC_FRONTEND_API_BASE ?? "/api";

  // Data
  const [loading, setLoading]   = useState(true);
  const [records, setRecords]   = useState<DomainRecord[]>([]);
  const [query, setQuery]       = useState("");
  const [selectedId, setSelectedId]   = useState<string | null>(null);
  const [expandedId, setExpandedId]   = useState<string | null>(null);

  // Add-domain modals
  const [showAddDomain, setShowAddDomain]       = useState(false);
  const [showAddSubdomain, setShowAddSubdomain] = useState(false);
  const [newDomainValue, setNewDomainValue]     = useState("");
  const [subdomainValue, setSubdomainValue]     = useState("");
  const [subdomainParentId, setSubdomainParentId] = useState("");

  // Deploy wizard
  const [deployPromptId, setDeployPromptId]     = useState<string | null>(null);
  const [deployWizardId, setDeployWizardId]     = useState<string | null>(null);
  const [deployStep, setDeployStep]             = useState(1);
  const [deploySource, setDeploySource]         = useState<DeploySource | null>(null);
  const [deployRuntime, setDeployRuntime]       = useState<DeployRuntime | null>(null);
  const [gitConnected, setGitConnected]         = useState(false);
  const [gitRepo, setGitRepo]                   = useState("");
  const [gitBranch, setGitBranch]               = useState("main");
  const [appTemplate, setAppTemplate]           = useState<AppTemplate | null>(null);
  const [uploadFile, setUploadFile]             = useState<File | null>(null);

  // Runtime editor
  const [runtimeDraft, setRuntimeDraft]             = useState<DeployRuntime | "node" | "">("");
  const [runtimeVersionDraft, setRuntimeVersionDraft] = useState("");
  const [runtimeSaving, setRuntimeSaving]           = useState(false);

  const fileInputRef = useRef<HTMLInputElement | null>(null);

  // ── Derived ────────────────────────────────────────────────────────────────

  const filteredRecords = useMemo(() => {
    if (!query.trim()) return records;
    const q = query.toLowerCase();
    return records.filter((r) => r.host.toLowerCase().includes(q));
  }, [records, query]);

  const selectedRecord = useMemo(
    () => records.find((r) => r.id === selectedId) ?? null,
    [records, selectedId],
  );

  const parentDomainOptions = useMemo(
    () => records.filter((r) => r.type === "domain"),
    [records],
  );

  const deployDomain = useMemo(
    () => records.find((r) => r.id === deployWizardId) ?? null,
    [records, deployWizardId],
  );

  const canAdvance = useMemo(() => {
    if (deployStep === 1) return !!deploySource;
    if (deployStep === 2) {
      if (deploySource === "git")   return gitConnected && gitRepo.trim().length > 0;
      if (deploySource === "files") return !!uploadFile;
      if (deploySource === "app")   return !!appTemplate;
    }
    if (deployStep === 3) return !!deployRuntime;
    return true;
  }, [deployStep, deploySource, gitConnected, gitRepo, uploadFile, appTemplate, deployRuntime]);

  // ── Auth + data load ───────────────────────────────────────────────────────

  useEffect(() => {
    const token   = localStorage.getItem("eupanel_token");
    const rawUser = localStorage.getItem("eupanel_user");
    if (!token || !rawUser) { router.replace("/"); return; }

    const parsed   = JSON.parse(rawUser) as DashboardUser;
    const userRole = parsed.role?.toLowerCase();
    if (userRole !== role) {
      router.replace(
        userRole === "admin"    ? "/dashboard/admin" :
        userRole === "reseller" ? "/dashboard/reseller" : "/dashboard",
      );
      return;
    }

    void (async () => {
      try {
        const res    = await fetch(`${apiBase}/sites`, { headers: { Authorization: `Bearer ${token}` } });
        const result = await res.json() as { data?: Array<Record<string, unknown>> };
        if (!res.ok || !result.data) return;

        const mapped: DomainRecord[] = result.data.map((site) => {
          const domain         = String(site.domain ?? "");
          const runtime        = String(site.runtime ?? "php").toLowerCase();
          const runtimeVersion = String(site.runtimeVersion ?? "8.3.30");
          const parent         = domain.split(".").length > 2
            ? domain.split(".").slice(-2).join(".")
            : undefined;
          return {
            id:                   String(site.id),
            host:                 domain,
            type:                 parent ? "subdomain" : "domain",
            parent,
            status:               String(site.status ?? "Active").toLowerCase() === "active" ? "Active" : "Suspended",
            diskMb:               Number(site.diskMb ?? 0),
            trafficMbMonth:       Number(site.trafficMbMonth ?? 0),
            diskQuotaGb:          Number(site.diskQuotaGb ?? 20),
            trafficQuotaGbMonth:  Number(site.trafficQuotaGbMonth ?? 100),
            trafficUsedMbMonth:   Number(site.trafficUsedMbMonth ?? 0),
            ipAddress:            String(site.ipAddress ?? ""),
            systemUser:           String(site.systemUser ?? ""),
            phpVersion:           runtimeVersion,
            sslSecured:           Boolean(site.sslSecured ?? false),
            deploymentStatus:     (site.deploymentStatus as DomainRecord["deploymentStatus"]) ?? "Not Deployed",
            runtime:              runtime === "node" ? "nodejs" : (runtime as DomainRecord["runtime"]),
          };
        });

        if (mapped.length > 0) {
          setRecords(mapped);
          setSelectedId(mapped[0].id);
          setExpandedId(mapped[0].id);
        }
      } catch {
        // API unavailable — empty state handles this gracefully.
      } finally {
        setLoading(false);
      }
    })();
  }, [apiBase, role, router]);

  // Sync runtime editor with selected record
  useEffect(() => {
    if (!selectedRecord) return;
    setRuntimeDraft((selectedRecord.runtime as DeployRuntime) ?? "php");
    setRuntimeVersionDraft(selectedRecord.phpVersion ?? "8.3.30");
  }, [selectedRecord]);

  // ── Actions ────────────────────────────────────────────────────────────────

  function logout() {
    localStorage.removeItem("eupanel_token");
    localStorage.removeItem("eupanel_user");
    router.replace("/");
  }

  function toggleExpand(id: string) {
    setSelectedId(id);
    setExpandedId((prev) => (prev === id ? null : id));
  }

  function addDomain(hostInput?: string) {
    const host   = (hostInput ?? "").trim().toLowerCase() || `domain-${Date.now()}.com`;
    const record: DomainRecord = {
      id: crypto.randomUUID(), host, type: "domain", status: "Active",
      diskMb: 0, trafficMbMonth: 0, diskQuotaGb: 20,
      trafficQuotaGbMonth: 100, trafficUsedMbMonth: 0,
      ipAddress: "", systemUser: host.split(".")[0].slice(0, 10),
      phpVersion: "8.3.30", sslSecured: false, deploymentStatus: "Not Deployed", runtime: "php",
    };

    const token = localStorage.getItem("eupanel_token");
    if (!token) return;

    void (async () => {
      try {
        const res    = await fetch(`${apiBase}/sites`, {
          method: "POST",
          headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
          body: JSON.stringify({
            serverId: "local-server-1", domain: record.host,
            runtime: "php", runtimeVersion: "8.3.30",
            rootPath: `/var/www/${record.host}/public`,
          }),
        });
        const result = await res.json() as { data?: { site?: Record<string, unknown> } };
        const createdId = result.data?.site?.id ? String(result.data.site.id) : record.id;
        const created   = { ...record, id: createdId };
        setRecords((prev) => [created, ...prev]);
        setSelectedId(created.id);
        setExpandedId(created.id);
        setDeployPromptId(created.id);
      } catch {
        setRecords((prev) => [record, ...prev]);
        setSelectedId(record.id);
        setExpandedId(record.id);
        setDeployPromptId(record.id);
      }
    })();
  }

  function addSubdomain(parentId?: string, subLabel?: string) {
    const root = records.find((r) => r.id === parentId && r.type === "domain")
               ?? records.find((r) => r.type === "domain");
    if (!root) return;

    const part   = (subLabel ?? "").trim().toLowerCase() || `sub${Date.now()}`;
    const host   = `${part}.${root.host}`;
    const record: DomainRecord = {
      id: crypto.randomUUID(), host, type: "subdomain", parent: root.host,
      status: "Active", diskMb: 0, trafficMbMonth: 0,
      diskQuotaGb: root.diskQuotaGb, trafficQuotaGbMonth: root.trafficQuotaGbMonth,
      trafficUsedMbMonth: 0, ipAddress: root.ipAddress, systemUser: root.systemUser,
      phpVersion: root.phpVersion, sslSecured: false, deploymentStatus: "Not Deployed",
      runtime: root.runtime,
    };

    const token = localStorage.getItem("eupanel_token");
    if (!token) return;

    void (async () => {
      try {
        const res    = await fetch(`${apiBase}/sites/subdomains`, {
          method: "POST",
          headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
          body: JSON.stringify({
            serverId: "local-server-1", parentDomain: root.host, subdomain: part,
            runtime: "php", runtimeVersion: root.phpVersion,
            rootPath: `/var/www/${host}/public`,
          }),
        });
        const result = await res.json() as { data?: { site?: Record<string, unknown> } };
        const createdId = result.data?.site?.id ? String(result.data.site.id) : record.id;
        const created   = { ...record, id: createdId };
        setRecords((prev) => [created, ...prev]);
        setSelectedId(created.id); setExpandedId(created.id);
      } catch {
        setRecords((prev) => [record, ...prev]);
        setSelectedId(record.id); setExpandedId(record.id);
      }
    })();
  }

  function submitAddDomain() {
    addDomain(newDomainValue);
    setNewDomainValue("");
    setShowAddDomain(false);
  }

  function submitAddSubdomain() {
    addSubdomain(subdomainParentId, subdomainValue);
    setSubdomainValue("");
    setShowAddSubdomain(false);
  }

  function openAddSubdomainModal() {
    setSubdomainParentId(parentDomainOptions[0]?.id ?? "");
    setSubdomainValue("");
    setShowAddSubdomain(true);
  }

  function resetDeployWizard() {
    setDeployStep(1); setDeploySource(null); setDeployRuntime(null);
    setGitConnected(false); setGitRepo(""); setGitBranch("main");
    setAppTemplate(null); setUploadFile(null);
  }

  function openDeployWizard(id: string) {
    setDeployWizardId(id);
    setDeployPromptId(null);
    resetDeployWizard();
  }

  function closeDeployWizard() {
    setDeployWizardId(null);
    resetDeployWizard();
  }

  function handleTemplateSelect(tpl: AppTemplate) {
    setAppTemplate(tpl);
    const found = APP_TEMPLATES.find((t) => t.id === tpl);
    setDeployRuntime(found?.runtime ?? null);
  }

  function deploySelectedDomain() {
    if (!deployWizardId || !deployRuntime || !deploySource) return;
    const targetId = deployWizardId;
    setRecords((prev) => prev.map((r) => r.id === targetId ? { ...r, deploymentStatus: "Deploying" } : r));
    closeDeployWizard();
    setTimeout(() => {
      setRecords((prev) => prev.map((r) => r.id === targetId ? { ...r, deploymentStatus: "Deployed" } : r));
    }, 1200);
  }

  async function saveRuntime() {
    if (!selectedRecord || !runtimeDraft || !runtimeVersionDraft.trim()) return;
    const token = localStorage.getItem("eupanel_token");
    if (!token) return;
    setRuntimeSaving(true);
    try {
      await fetch(`${apiBase}/sites/${selectedRecord.id}/runtime`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
        body: JSON.stringify({
          runtime: runtimeDraft === "node" ? "nodejs" : runtimeDraft,
          runtimeVersion: runtimeVersionDraft.trim(),
        }),
      });
      setRecords((prev) => prev.map((r) => r.id === selectedRecord.id
        ? { ...r,
            runtime: runtimeDraft === "node" ? "nodejs" : (runtimeDraft as DomainRecord["runtime"]),
            phpVersion: runtimeVersionDraft.trim() }
        : r,
      ));
    } finally {
      setRuntimeSaving(false);
    }
  }

  // ── Render ─────────────────────────────────────────────────────────────────

  return (
    <div className="ep-shell">
      <DashboardSidebar role={role} onLogout={logout} />

      <main className="ep-main">

        {/* Topbar */}
        <div className="ep-topbar">
          <div className="ep-topbar-breadcrumb">
            <span>Dashboard</span>
            <span style={{ margin: "0 0.4rem", color: "var(--ep-text-faint)" }}>›</span>
            <strong>Websites &amp; Domains</strong>
          </div>
          <div className="ep-topbar-right">
            {!loading && (
              <>
                <button
                  className="ep-btn ep-btn-ghost ep-btn-sm"
                  onClick={openAddSubdomainModal}
                  disabled={parentDomainOptions.length === 0}
                >
                  <IconPlus size={13} /> Add Subdomain
                </button>
                <button
                  className="ep-btn ep-btn-primary ep-btn-sm"
                  onClick={() => { setNewDomainValue(""); setShowAddDomain(true); }}
                >
                  <IconPlus size={13} /> Add Domain
                </button>
              </>
            )}
          </div>
        </div>

        <div className="ep-content">

          {/* Loading */}
          {loading && (
            <div className="ep-card">
              <div className="ep-skeleton-list">
                {[1, 2, 3, 4].map((i) => <div key={i} className="ep-skeleton ep-skeleton-row" />)}
              </div>
            </div>
          )}

          {/* Empty state */}
          {!loading && records.length === 0 && (
            <div className="ep-card">
              <div className="ep-empty" style={{ padding: "4rem 1rem" }}>
                <div className="ep-empty-icon"><IconGlobe size={22} /></div>
                <div className="ep-empty-title">No domains yet</div>
                <div className="ep-empty-desc">
                  Add your first domain to start hosting sites, configuring DNS, and managing SSL.
                </div>
                <button
                  className="ep-btn ep-btn-primary"
                  style={{ marginTop: "1.25rem" }}
                  onClick={() => { setNewDomainValue(""); setShowAddDomain(true); }}
                >
                  <IconPlus size={15} /> Add your first domain
                </button>
              </div>
            </div>
          )}

          {/* Domain list */}
          {!loading && records.length > 0 && (
            <div className="ep-card">
              <div className="ep-card-header">
                <span className="ep-card-title">
                  {filteredRecords.length} {filteredRecords.length === 1 ? "domain" : "domains"}
                </span>
                <div className="ep-search-wrap" style={{ width: "220px" }}>
                  <IconSearch size={13} className="ep-search-icon" />
                  <input
                    className="ep-search"
                    placeholder="Search domains…"
                    value={query}
                    onChange={(e) => setQuery(e.target.value)}
                  />
                </div>
              </div>

              <div className="ep-table-wrap">
                <table className="ep-table">
                  <thead>
                    <tr>
                      <th>Status</th>
                      <th>Domain</th>
                      <th>Runtime</th>
                      <th>SSL</th>
                      <th>Deployment</th>
                      <th style={{ textAlign: "right" }}>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredRecords.map((record) => {
                      const isExpanded = expandedId === record.id;
                      const isSelected = selectedId === record.id;
                      const siteStatus   = SITE_STATUS[record.status.toLowerCase()];
                      const deployStatus = DEPLOY_STATUS[record.deploymentStatus] ?? DEPLOY_STATUS["Not Deployed"];

                      return (
                        <Fragment key={record.id}>
                          <tr
                            style={{
                              cursor: "pointer",
                              background: isSelected ? "var(--ep-accent-subtle)" : undefined,
                            }}
                            onClick={() => toggleExpand(record.id)}
                          >
                            <td>
                              <span className={siteStatus?.cls ?? "ep-badge ep-badge-neutral"}>
                                {siteStatus?.label ?? record.status}
                              </span>
                            </td>
                            <td>
                              <div style={{ fontWeight: 500, color: "var(--ep-text)" }}>{record.host}</div>
                              {record.type === "subdomain" && record.parent && (
                                <div style={{ fontSize: "0.72rem", color: "var(--ep-text-faint)", marginTop: "0.1rem" }}>
                                  ↳ {record.parent}
                                </div>
                              )}
                            </td>
                            <td>
                              <span className="ep-text-mono" style={{ fontSize: "0.8rem" }}>
                                {record.runtime} {record.phpVersion}
                              </span>
                            </td>
                            <td>
                              <span className={record.sslSecured ? "ep-badge ep-badge-success" : "ep-badge ep-badge-neutral"}>
                                {record.sslSecured ? "Secured" : "None"}
                              </span>
                            </td>
                            <td>
                              <span className={deployStatus.cls}>{deployStatus.label}</span>
                            </td>
                            <td style={{ textAlign: "right" }}>
                              <button
                                className="ep-btn ep-btn-ghost ep-btn-sm"
                                onClick={(e) => { e.stopPropagation(); openDeployWizard(record.id); }}
                              >
                                Deploy
                              </button>
                            </td>
                          </tr>

                          {/* Expand panel */}
                          {isExpanded && (
                            <tr>
                              <td
                                colSpan={6}
                                style={{
                                  padding: "1rem",
                                  background: "var(--ep-surface-alt)",
                                  borderBottom: "1px solid var(--ep-border)",
                                }}
                              >
                                <div style={{ display: "grid", gap: "0.875rem" }}>

                                  {/* Quick info */}
                                  <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(150px, 1fr))", gap: "0.5rem" }}>
                                    {[
                                      { label: "Host",        value: record.host },
                                      { label: "IP Address",  value: record.ipAddress || "—" },
                                      { label: "System User", value: record.systemUser || "—" },
                                      { label: "SSL",         value: record.sslSecured ? "Secured" : "Not secured" },
                                    ].map(({ label, value }) => (
                                      <div
                                        key={label}
                                        style={{
                                          background: "var(--ep-surface)", border: "1px solid var(--ep-border)",
                                          borderRadius: "var(--ep-r-md)", padding: "0.6rem 0.875rem",
                                        }}
                                      >
                                        <div style={{ fontSize: "0.68rem", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.06em", color: "var(--ep-text-muted)", marginBottom: "0.2rem" }}>{label}</div>
                                        <div style={{ fontSize: "0.875rem", fontWeight: 500, color: "var(--ep-text)" }}>{value}</div>
                                      </div>
                                    ))}
                                  </div>

                                  {/* Runtime config */}
                                  <div style={{ background: "var(--ep-surface)", border: "1px solid var(--ep-border)", borderRadius: "var(--ep-r-md)", padding: "0.875rem 1rem" }}>
                                    <div style={{ fontSize: "0.8125rem", fontWeight: 600, marginBottom: "0.65rem" }}>Runtime Configuration</div>
                                    <div style={{ display: "flex", gap: "0.5rem", flexWrap: "wrap", alignItems: "flex-end" }}>
                                      <div className="ep-input-group" style={{ margin: 0 }}>
                                        <select
                                          value={runtimeDraft}
                                          onChange={(e) => setRuntimeDraft(e.target.value as DeployRuntime | "node" | "")}
                                          className="ep-input"
                                          style={{ minWidth: "130px" }}
                                        >
                                          <option value="php">PHP</option>
                                          <option value="nodejs">Node.js</option>
                                          <option value="dart">Dart</option>
                                          <option value="python">Python</option>
                                          <option value="docker">Docker</option>
                                        </select>
                                      </div>
                                      <input
                                        value={runtimeVersionDraft}
                                        onChange={(e) => setRuntimeVersionDraft(e.target.value)}
                                        className="ep-input"
                                        style={{ width: "170px" }}
                                        placeholder="Version (e.g. 8.3.30)"
                                      />
                                      <button
                                        onClick={saveRuntime}
                                        disabled={runtimeSaving || !runtimeDraft || !runtimeVersionDraft.trim()}
                                        className="ep-btn ep-btn-primary ep-btn-sm"
                                      >
                                        {runtimeSaving ? "Saving…" : "Save"}
                                      </button>
                                    </div>
                                  </div>

                                  {/* Tools */}
                                  <div style={{ background: "var(--ep-surface)", border: "1px solid var(--ep-border)", borderRadius: "var(--ep-r-md)", padding: "0.875rem 1rem" }}>
                                    <div style={{ fontSize: "0.8125rem", fontWeight: 600, marginBottom: "0.65rem" }}>Tools</div>
                                    <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(150px, 1fr))", gap: "0.4rem" }}>
                                      {([
                                        { label: "File Manager",   icon: "folder"   },
                                        { label: "Databases",      icon: "database" },
                                        { label: "Mail",           icon: "mail"     },
                                        { label: "DNS & Hosting",  icon: "dns"      },
                                        { label: "Logs",           icon: "logs"     },
                                        { label: "Git",            icon: "git"      },
                                        { label: "Backups",        icon: "backup"   },
                                        { label: "FTP Access",     icon: "ftp"      },
                                        { label: "SSL/TLS",        icon: "rocket"   },
                                        { label: "Performance",    icon: "speed"    },
                                      ] as { label: string; icon: Parameters<typeof ActionButton>[0]["icon"] }[]).map((item) => (
                                        <ActionButton key={item.label} label={item.label} icon={item.icon} />
                                      ))}
                                    </div>
                                  </div>

                                  {/* Security */}
                                  <div style={{ background: "var(--ep-surface)", border: "1px solid var(--ep-border)", borderRadius: "var(--ep-r-md)", padding: "0.875rem 1rem" }}>
                                    <div style={{ fontSize: "0.8125rem", fontWeight: 600, marginBottom: "0.65rem" }}>Security</div>
                                    <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(170px, 1fr))", gap: "0.4rem" }}>
                                      <div style={{
                                        padding: "0.6rem 0.875rem", borderRadius: "var(--ep-r-md)", border: "1px solid",
                                        ...(record.sslSecured
                                          ? { background: "var(--ep-success-bg)", borderColor: "var(--ep-success-border)", color: "var(--ep-success)" }
                                          : { background: "var(--ep-error-bg)",   borderColor: "var(--ep-error-border)",   color: "var(--ep-error)"   }),
                                      }}>
                                        <div style={{ fontWeight: 600, fontSize: "0.8125rem" }}>SSL / TLS</div>
                                        <div style={{ fontSize: "0.75rem", marginTop: "0.1rem", opacity: 0.85 }}>
                                          {record.sslSecured ? "Certificate active" : "No certificate — add one"}
                                        </div>
                                      </div>
                                      {["Firewall (WAF)", "Password-Protected Dirs", "Security Advisor"].map((item) => (
                                        <button key={item} className="ep-btn ep-btn-ghost ep-btn-sm" style={{ justifyContent: "flex-start" }}>
                                          {item}
                                        </button>
                                      ))}
                                    </div>
                                  </div>

                                </div>
                              </td>
                            </tr>
                          )}
                        </Fragment>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* Selected-domain stat cards */}
          {!loading && selectedRecord && (
            <div className="ep-stat-grid">
              <div className="ep-stat-card">
                <div className="ep-stat-label">Disk Used</div>
                <div className="ep-stat-value" style={{ fontSize: "1.5rem" }}>
                  {selectedRecord.diskMb < 1024
                    ? `${selectedRecord.diskMb.toFixed(0)} MB`
                    : `${(selectedRecord.diskMb / 1024).toFixed(2)} GB`}
                </div>
                <div className="ep-stat-sub">of {selectedRecord.diskQuotaGb} GB quota</div>
              </div>
              <div className="ep-stat-card">
                <div className="ep-stat-label">Traffic (month)</div>
                <div className="ep-stat-value" style={{ fontSize: "1.5rem" }}>
                  {selectedRecord.trafficUsedMbMonth < 1024
                    ? `${selectedRecord.trafficUsedMbMonth.toFixed(0)} MB`
                    : `${(selectedRecord.trafficUsedMbMonth / 1024).toFixed(2)} GB`}
                </div>
                <div className="ep-stat-sub">of {selectedRecord.trafficQuotaGbMonth} GB quota</div>
              </div>
              <div className="ep-stat-card">
                <div className="ep-stat-label">IP Address</div>
                <div className="ep-stat-value" style={{ fontSize: "0.95rem", fontFamily: "var(--font-ibm-plex-mono)", letterSpacing: "0" }}>
                  {selectedRecord.ipAddress || "—"}
                </div>
                <div className="ep-stat-sub">{selectedRecord.systemUser ? `User: ${selectedRecord.systemUser}` : "—"}</div>
              </div>
              <div className="ep-stat-card">
                <div className="ep-stat-label">SSL</div>
                <div className="ep-stat-value" style={{ fontSize: "1rem", display: "flex", alignItems: "center", marginTop: "0.35rem" }}>
                  <span className={selectedRecord.sslSecured ? "ep-badge ep-badge-success" : "ep-badge ep-badge-error"}>
                    {selectedRecord.sslSecured ? "Secured" : "Not secured"}
                  </span>
                </div>
                <div className="ep-stat-sub">{selectedRecord.host}</div>
              </div>
            </div>
          )}

        </div>
      </main>

      {/* ════════════════════════════════════════════════
          Modals
      ════════════════════════════════════════════════ */}

      {/* Deploy prompt */}
      {deployPromptId && (
        <div className="ep-modal-overlay">
          <div className="ep-modal">
            <div className="ep-modal-header">
              <span className="ep-modal-title">Deploy this domain?</span>
              <button className="ep-btn-icon" onClick={() => setDeployPromptId(null)}><IconX size={14} /></button>
            </div>
            <div className="ep-modal-body">
              <p style={{ fontSize: "0.875rem", color: "var(--ep-text-muted)" }}>
                Domain added successfully. Set up deployment now to go live.
              </p>
            </div>
            <div className="ep-modal-footer">
              <button className="ep-btn ep-btn-ghost" onClick={() => setDeployPromptId(null)}>Later</button>
              <button className="ep-btn ep-btn-primary" onClick={() => openDeployWizard(deployPromptId)}>
                Set up deployment →
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Add domain */}
      {showAddDomain && (
        <div className="ep-modal-overlay">
          <div className="ep-modal">
            <div className="ep-modal-header">
              <span className="ep-modal-title">Add Domain</span>
              <button className="ep-btn-icon" onClick={() => setShowAddDomain(false)}><IconX size={14} /></button>
            </div>
            <div className="ep-modal-body">
              <div className="ep-input-group">
                <label className="ep-label">Domain name</label>
                <input
                  className="ep-input"
                  value={newDomainValue}
                  onChange={(e) => setNewDomainValue(e.target.value)}
                  placeholder="example.com"
                  onKeyDown={(e) => e.key === "Enter" && submitAddDomain()}
                  autoFocus
                />
              </div>
            </div>
            <div className="ep-modal-footer">
              <button className="ep-btn ep-btn-ghost" onClick={() => setShowAddDomain(false)}>Cancel</button>
              <button className="ep-btn ep-btn-primary" onClick={submitAddDomain}>Add Domain</button>
            </div>
          </div>
        </div>
      )}

      {/* Add subdomain */}
      {showAddSubdomain && (
        <div className="ep-modal-overlay">
          <div className="ep-modal">
            <div className="ep-modal-header">
              <span className="ep-modal-title">Add Subdomain</span>
              <button className="ep-btn-icon" onClick={() => setShowAddSubdomain(false)}><IconX size={14} /></button>
            </div>
            <div className="ep-modal-body">
              <div className="ep-input-group">
                <label className="ep-label">Parent domain</label>
                <select
                  className="ep-input"
                  value={subdomainParentId}
                  onChange={(e) => setSubdomainParentId(e.target.value)}
                >
                  {parentDomainOptions.map((d) => (
                    <option key={d.id} value={d.id}>{d.host}</option>
                  ))}
                </select>
              </div>
              <div className="ep-input-group">
                <label className="ep-label">Subdomain prefix</label>
                <input
                  className="ep-input"
                  value={subdomainValue}
                  onChange={(e) => setSubdomainValue(e.target.value)}
                  placeholder="app"
                  onKeyDown={(e) => e.key === "Enter" && submitAddSubdomain()}
                  autoFocus
                />
                {subdomainParentId && subdomainValue && (
                  <p style={{ fontSize: "0.78rem", color: "var(--ep-text-muted)", marginTop: "0.3rem" }}>
                    → {subdomainValue}.{parentDomainOptions.find((d) => d.id === subdomainParentId)?.host}
                  </p>
                )}
              </div>
            </div>
            <div className="ep-modal-footer">
              <button className="ep-btn ep-btn-ghost" onClick={() => setShowAddSubdomain(false)}>Cancel</button>
              <button className="ep-btn ep-btn-primary" disabled={!subdomainParentId} onClick={submitAddSubdomain}>
                Add Subdomain
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ─── Deploy Wizard ──────────────────────────────────────────────────── */}
      {deployWizardId && deployDomain && (
        <div className="ep-modal-overlay">
          <div className="ep-modal" style={{ width: "min(100%, 640px)" }}>

            {/* Header */}
            <div className="ep-modal-header">
              <div>
                <div style={{ fontSize: "0.68rem", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.07em", color: "var(--ep-text-muted)" }}>
                  Deploy Wizard
                </div>
                <div className="ep-modal-title">{deployDomain.host}</div>
              </div>
              <button className="ep-btn-icon" onClick={closeDeployWizard}><IconX size={14} /></button>
            </div>

            {/* Step indicator */}
            <div style={{ padding: "0.875rem 1.5rem 0", display: "flex", alignItems: "center", gap: "0" }}>
              {[
                { n: 1, label: "Method" },
                { n: 2, label: "Configure" },
                { n: 3, label: "Runtime" },
                { n: 4, label: "Review" },
              ].map(({ n, label }) => (
                <div key={n} style={{ display: "flex", alignItems: "center", flex: n < 4 ? 1 : undefined }}>
                  <div style={{ display: "flex", alignItems: "center", gap: "0.4rem", flexShrink: 0 }}>
                    <div style={{
                      width: "1.5rem", height: "1.5rem", borderRadius: "50%",
                      display: "flex", alignItems: "center", justifyContent: "center",
                      fontSize: "0.7rem", fontWeight: 700,
                      background: deployStep > n ? "var(--ep-success)" : deployStep === n ? "var(--ep-accent)" : "var(--ep-surface-alt)",
                      color: deployStep >= n ? "white" : "var(--ep-text-faint)",
                      border: deployStep >= n ? "none" : "1px solid var(--ep-border)",
                      transition: "background 0.15s",
                    }}>
                      {deployStep > n ? <IconCheck size={9} /> : n}
                    </div>
                    <span style={{
                      fontSize: "0.75rem",
                      fontWeight: deployStep === n ? 600 : 400,
                      color: deployStep === n ? "var(--ep-text)" : "var(--ep-text-faint)",
                    }}>
                      {label}
                    </span>
                  </div>
                  {n < 4 && (
                    <div style={{ flex: 1, height: "1px", margin: "0 0.5rem", background: deployStep > n ? "var(--ep-success)" : "var(--ep-border)", transition: "background 0.15s" }} />
                  )}
                </div>
              ))}
            </div>

            {/* Body */}
            <div className="ep-modal-body" style={{ minHeight: "280px" }}>

              {/* ── Step 1: Method ── */}
              {deployStep === 1 && (
                <div style={{ display: "grid", gap: "0.75rem" }}>
                  <p style={{ fontSize: "0.875rem", color: "var(--ep-text-muted)" }}>
                    Choose how to deploy <strong style={{ color: "var(--ep-text)" }}>{deployDomain.host}</strong>.
                  </p>
                  <div style={{ display: "grid", gap: "0.6rem" }}>
                    {DEPLOY_METHODS.map((method) => (
                      <button
                        key={method.id}
                        onClick={() => setDeploySource(method.id)}
                        style={{
                          display: "flex", alignItems: "flex-start", gap: "0.875rem",
                          padding: "0.875rem 1rem", textAlign: "left", cursor: "pointer",
                          border: `1.5px solid ${deploySource === method.id ? "var(--ep-accent)" : "var(--ep-border)"}`,
                          background: deploySource === method.id ? "var(--ep-accent-subtle)" : "var(--ep-surface)",
                          borderRadius: "var(--ep-r-md)", transition: "all 0.14s",
                        }}
                      >
                        <div style={{ flex: 1 }}>
                          <div style={{ display: "flex", alignItems: "center", gap: "0.5rem", marginBottom: "0.3rem" }}>
                            <span style={{ fontSize: "0.875rem", fontWeight: 600, color: "var(--ep-text)" }}>
                              {method.label}
                            </span>
                            {method.recommended && (
                              <span className="ep-badge ep-badge-accent" style={{ fontSize: "0.65rem" }}>Recommended</span>
                            )}
                          </div>
                          <p style={{ fontSize: "0.8rem", color: "var(--ep-text-muted)", lineHeight: 1.45, margin: 0 }}>
                            {method.desc}
                          </p>
                        </div>
                        {deploySource === method.id && (
                          <div style={{ color: "var(--ep-accent)", flexShrink: 0, marginTop: "0.1rem" }}>
                            <IconCheck size={16} />
                          </div>
                        )}
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {/* ── Step 2: Configure ── */}
              {deployStep === 2 && (
                <div style={{ display: "grid", gap: "1rem" }}>

                  {/* Git configure */}
                  {deploySource === "git" && (
                    <>
                      {/* Git workflow explanation */}
                      <div style={{
                        background: "var(--ep-surface-alt)", border: "1px solid var(--ep-border)",
                        borderRadius: "var(--ep-r-md)", padding: "0.875rem 1rem",
                      }}>
                        <div style={{ fontSize: "0.68rem", fontWeight: 700, textTransform: "uppercase", letterSpacing: "0.08em", color: "var(--ep-text-muted)", marginBottom: "0.75rem" }}>
                          How Git deployment works
                        </div>
                        <div style={{ display: "grid", gap: "0.65rem" }}>
                          {GIT_WORKFLOW_STEPS.map((s) => (
                            <div key={s.n} style={{ display: "flex", gap: "0.75rem", alignItems: "flex-start" }}>
                              <div style={{
                                width: "1.35rem", height: "1.35rem", borderRadius: "50%", flexShrink: 0,
                                background: "var(--ep-accent-subtle)", border: "1px solid rgba(13,153,112,0.22)",
                                display: "flex", alignItems: "center", justifyContent: "center",
                                fontSize: "0.65rem", fontWeight: 700, color: "var(--ep-accent)",
                              }}>{s.n}</div>
                              <div>
                                <div style={{ fontSize: "0.8125rem", fontWeight: 600, color: "var(--ep-text)" }}>{s.label}</div>
                                <div style={{ fontSize: "0.75rem", color: "var(--ep-text-muted)", marginTop: "0.1rem" }}>{s.desc}</div>
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>

                      {/* Connect button */}
                      <button
                        onClick={() => setGitConnected(true)}
                        className={gitConnected ? "ep-btn ep-btn-ghost" : "ep-btn ep-btn-primary"}
                        style={{ width: "100%", justifyContent: "center" }}
                      >
                        {gitConnected
                          ? <><IconCheck size={14} /> Git Provider Connected</>
                          : "Connect Git Provider"}
                      </button>

                      <div className="ep-input-group">
                        <label className="ep-label">Repository URL</label>
                        <input
                          className="ep-input"
                          value={gitRepo}
                          onChange={(e) => setGitRepo(e.target.value)}
                          placeholder="https://github.com/your-org/your-repo"
                          disabled={!gitConnected}
                        />
                      </div>
                      <div className="ep-input-group">
                        <label className="ep-label">Branch to deploy</label>
                        <input
                          className="ep-input"
                          value={gitBranch}
                          onChange={(e) => setGitBranch(e.target.value)}
                          placeholder="main"
                          disabled={!gitConnected}
                        />
                        <p style={{ fontSize: "0.75rem", color: "var(--ep-text-faint)", marginTop: "0.3rem" }}>
                          Every push to this branch will trigger a controlled deployment.
                        </p>
                      </div>
                    </>
                  )}

                  {/* Files upload configure */}
                  {deploySource === "files" && (
                    <>
                      <p style={{ fontSize: "0.875rem", color: "var(--ep-text-muted)" }}>
                        Upload a ZIP archive. It will be extracted and deployed to your domain root.
                      </p>
                      <button
                        onClick={() => fileInputRef.current?.click()}
                        style={{
                          padding: "2.25rem 1rem", border: "2px dashed var(--ep-border)",
                          borderRadius: "var(--ep-r-lg)", cursor: "pointer",
                          display: "flex", flexDirection: "column", alignItems: "center", gap: "0.5rem",
                          background: uploadFile ? "var(--ep-accent-subtle)" : "var(--ep-surface-alt)",
                          color: uploadFile ? "var(--ep-accent)" : "var(--ep-text-faint)",
                          transition: "all 0.14s",
                        }}
                      >
                        {uploadFile ? (
                          <>
                            <IconCheck size={24} />
                            <span style={{ fontSize: "0.875rem", fontWeight: 600 }}>{uploadFile.name}</span>
                            <span style={{ fontSize: "0.75rem", opacity: 0.7 }}>Click to change</span>
                          </>
                        ) : (
                          <>
                            <span style={{ fontSize: "1.75rem", lineHeight: 1 }}>↑</span>
                            <span style={{ fontSize: "0.875rem", fontWeight: 600 }}>Click to choose file</span>
                            <span style={{ fontSize: "0.75rem" }}>Supports .zip, .tar.gz and most archive types</span>
                          </>
                        )}
                      </button>
                      <input
                        ref={fileInputRef}
                        type="file"
                        accept=".zip,.rar,.7z,.tar,.gz,.tgz,*/*"
                        style={{ display: "none" }}
                        onChange={(e) => setUploadFile(e.target.files?.[0] ?? null)}
                      />
                    </>
                  )}

                  {/* App template configure */}
                  {deploySource === "app" && (
                    <>
                      <p style={{ fontSize: "0.875rem", color: "var(--ep-text-muted)" }}>
                        Choose a framework template to scaffold your application.
                      </p>
                      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0.6rem" }}>
                        {APP_TEMPLATES.map((tpl) => (
                          <button
                            key={tpl.id}
                            onClick={() => handleTemplateSelect(tpl.id)}
                            style={{
                              padding: "0.875rem", textAlign: "left", cursor: "pointer",
                              border: `1.5px solid ${appTemplate === tpl.id ? "var(--ep-accent)" : "var(--ep-border)"}`,
                              background: appTemplate === tpl.id ? "var(--ep-accent-subtle)" : "var(--ep-surface)",
                              borderRadius: "var(--ep-r-md)", transition: "all 0.14s",
                            }}
                          >
                            <div style={{ fontSize: "0.875rem", fontWeight: 600, color: "var(--ep-text)", marginBottom: "0.25rem" }}>{tpl.label}</div>
                            <div style={{ fontSize: "0.75rem", color: "var(--ep-text-muted)", lineHeight: 1.35 }}>{tpl.desc}</div>
                            {tpl.runtime && (
                              <div style={{ marginTop: "0.4rem" }}>
                                <span className="ep-badge ep-badge-neutral" style={{ fontSize: "0.65rem" }}>{tpl.runtime}</span>
                              </div>
                            )}
                          </button>
                        ))}
                      </div>
                    </>
                  )}
                </div>
              )}

              {/* ── Step 3: Runtime ── */}
              {deployStep === 3 && (
                <div style={{ display: "grid", gap: "0.75rem" }}>
                  {/* Auto-selected from app template */}
                  {deploySource === "app" && appTemplate && APP_TEMPLATES.find((t) => t.id === appTemplate)?.runtime ? (
                    <div style={{
                      padding: "1rem", borderRadius: "var(--ep-r-md)",
                      background: "var(--ep-accent-subtle)", border: "1px solid rgba(13,153,112,0.2)",
                    }}>
                      <div style={{ fontSize: "0.8125rem", fontWeight: 600, color: "var(--ep-text)", marginBottom: "0.25rem" }}>
                        Runtime auto-selected
                      </div>
                      <div style={{ fontSize: "0.875rem", color: "var(--ep-text-muted)" }}>
                        The <strong>{APP_TEMPLATES.find((t) => t.id === appTemplate)?.label}</strong> template uses{" "}
                        <span className="ep-badge ep-badge-accent">{deployRuntime}</span>
                      </div>
                    </div>
                  ) : (
                    <>
                      <p style={{ fontSize: "0.875rem", color: "var(--ep-text-muted)" }}>
                        Select the runtime environment for your deployment.
                      </p>
                      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(100px, 1fr))", gap: "0.5rem" }}>
                        {RUNTIMES.map((rt) => (
                          <button
                            key={rt.id}
                            onClick={() => setDeployRuntime(rt.id)}
                            style={{
                              padding: "0.75rem 0.5rem", textAlign: "center", cursor: "pointer",
                              border: `1.5px solid ${deployRuntime === rt.id ? "var(--ep-accent)" : "var(--ep-border)"}`,
                              background: deployRuntime === rt.id ? "var(--ep-accent-subtle)" : "var(--ep-surface)",
                              borderRadius: "var(--ep-r-md)", transition: "all 0.14s",
                              fontWeight: 500, fontSize: "0.875rem",
                              color: deployRuntime === rt.id ? "var(--ep-accent)" : "var(--ep-text)",
                            }}
                          >
                            {rt.label}
                          </button>
                        ))}
                      </div>
                    </>
                  )}
                </div>
              )}

              {/* ── Step 4: Review ── */}
              {deployStep === 4 && (
                <div style={{ display: "grid", gap: "0.75rem" }}>
                  <p style={{ fontSize: "0.875rem", color: "var(--ep-text-muted)" }}>
                    Review before deploying.
                  </p>
                  <div style={{
                    background: "var(--ep-surface-alt)", border: "1px solid var(--ep-border)",
                    borderRadius: "var(--ep-r-md)", padding: "1rem", display: "grid", gap: "0.6rem",
                  }}>
                    {([
                      { label: "Domain",  value: deployDomain.host },
                      { label: "Method",  value: deploySource ?? "—" },
                      { label: "Runtime", value: deployRuntime ?? "—" },
                      ...(deploySource === "git"
                        ? [{ label: "Repository", value: gitRepo || "—" }, { label: "Branch", value: gitBranch || "—" }]
                        : []),
                      ...(deploySource === "app"   ? [{ label: "Template", value: appTemplate ?? "—" }] : []),
                      ...(deploySource === "files" ? [{ label: "File",     value: uploadFile?.name ?? "—" }] : []),
                    ]).map(({ label, value }) => (
                      <div key={label} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", fontSize: "0.875rem" }}>
                        <span style={{ color: "var(--ep-text-muted)" }}>{label}</span>
                        <span style={{ fontWeight: 500, color: "var(--ep-text)", fontFamily: label === "Repository" || label === "Domain" ? "var(--font-ibm-plex-mono)" : undefined, fontSize: label === "Repository" ? "0.8rem" : undefined }}>{String(value)}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

            </div>

            {/* Footer */}
            <div className="ep-modal-footer">
              <button
                className="ep-btn ep-btn-ghost"
                onClick={() => deployStep === 1 ? closeDeployWizard() : setDeployStep((s) => s - 1)}
              >
                {deployStep === 1 ? "Cancel" : "← Back"}
              </button>
              {deployStep < 4 ? (
                <button
                  className="ep-btn ep-btn-primary"
                  disabled={!canAdvance}
                  onClick={() => setDeployStep((s) => s + 1)}
                >
                  Continue →
                </button>
              ) : (
                <button className="ep-btn ep-btn-primary" onClick={deploySelectedDomain}>
                  Deploy {deployDomain.host} →
                </button>
              )}
            </div>

          </div>
        </div>
      )}

    </div>
  );
}
