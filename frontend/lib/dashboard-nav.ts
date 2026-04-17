export type DashboardRole = "admin" | "customer";

export type SidebarItem = {
  label: string;
  href: string;
  count?: number;
};

export type SidebarGroup = {
  title?: string;
  items: SidebarItem[];
};

const adminGroups: SidebarGroup[] = [
  {
    items: [
      { label: "Home", href: "/dashboard/admin" },
    ],
  },
  {
    title: "Hosting Services",
    items: [
      { label: "Websites & Domains", href: "/dashboard/admin/websites-domains" },
      { label: "Mail", href: "/dashboard/admin/mail" },
      { label: "Databases", href: "/dashboard/admin/databases" },
      { label: "DNS Settings", href: "/dashboard/admin/dns-settings" },
      { label: "SSL/TLS Certificates", href: "/dashboard/admin/ssl-certificates" },
      { label: "Customers", href: "/dashboard/admin/customers", count: 16 },
      { label: "Resellers", href: "/dashboard/admin/resellers" },
      { label: "Domains", href: "/dashboard/admin/domains", count: 36 },
      { label: "Subscriptions", href: "/dashboard/admin/subscriptions", count: 19 },
      { label: "Service Plans", href: "/dashboard/admin/service-plans", count: 8 },
    ],
  },
  {
    title: "Links to Additional Services",
    items: [
      { label: "SEO", href: "/dashboard/admin/seo" },
      { label: "Process List", href: "/dashboard/admin/process-list" },
      { label: "Imunify", href: "/dashboard/admin/imunify" },
    ],
  },
  {
    title: "Server Management",
    items: [
      { label: "Servers", href: "/dashboard/admin/servers" },
      { label: "Runtimes", href: "/dashboard/admin/runtimes" },
      { label: "Jobs", href: "/dashboard/admin/jobs" },
      { label: "Backups", href: "/dashboard/admin/backups" },
      { label: "Tools & Settings", href: "/dashboard/admin/tools-settings" },
      { label: "Statistics", href: "/dashboard/admin/statistics" },
      { label: "Extensions", href: "/dashboard/admin/extensions" },
      { label: "Monitoring", href: "/dashboard/admin/monitoring" },
    ],
  },
];

const customerGroups: SidebarGroup[] = [
  {
    items: [
      { label: "Home", href: "/dashboard" },
    ],
  },
  {
    title: "Hosting",
    items: [
      { label: "Websites & Domains", href: "/dashboard/websites-domains" },
      { label: "Mail", href: "/dashboard/mail" },
      { label: "Databases", href: "/dashboard/databases" },
      { label: "DNS Settings", href: "/dashboard/dns-settings" },
      { label: "SSL/TLS Certificates", href: "/dashboard/ssl-certificates" },
      { label: "File Manager", href: "/dashboard/file-manager" },
    ],
  },
  {
    title: "Operations",
    items: [
      { label: "Backups", href: "/dashboard/backups" },
      { label: "Scheduled Tasks", href: "/dashboard/scheduled-tasks" },
      { label: "Jobs Queue", href: "/dashboard/jobs-queue" },
      { label: "Monitoring", href: "/dashboard/monitoring" },
    ],
  },
];

const sections: Record<DashboardRole, Record<string, string>> = {
  admin: {
    mail: "Mail",
    databases: "Databases",
    "dns-settings": "DNS Settings",
    "ssl-certificates": "SSL/TLS Certificates",
    customers: "Customers",
    resellers: "Resellers",
    domains: "Domains",
    subscriptions: "Subscriptions",
    "service-plans": "Service Plans",
    seo: "SEO",
    "process-list": "Process List",
    imunify: "Imunify",
    servers: "Servers",
    runtimes: "Runtimes",
    jobs: "Jobs",
    backups: "Backups",
    "tools-settings": "Tools & Settings",
    statistics: "Statistics",
    extensions: "Extensions",
    monitoring: "Monitoring",
    profile: "My Profile",
  },
  customer: {
    "websites-domains": "Websites & Domains",
    mail: "Mail",
    databases: "Databases",
    "dns-settings": "DNS Settings",
    "ssl-certificates": "SSL/TLS Certificates",
    "file-manager": "File Manager",
    backups: "Backups",
    "scheduled-tasks": "Scheduled Tasks",
    "jobs-queue": "Jobs Queue",
    monitoring: "Monitoring",
    profile: "My Profile",
  },
};

export const sidebarByRole: Record<DashboardRole, SidebarGroup[]> = {
  admin: adminGroups,
  customer: customerGroups,
};

export function getSectionTitle(role: DashboardRole, section: string): string {
  return sections[role][section] ?? section.replace(/-/g, " ");
}
