export type DomainRecord = {
  id: string;
  host: string;
  type: "domain" | "subdomain";
  parent?: string;
  status: "Active" | "Suspended";
  diskMb: number;
  trafficMbMonth: number;
  diskQuotaGb: number;
  trafficQuotaGbMonth: number;
  trafficUsedMbMonth: number;
  ipAddress: string;
  systemUser: string;
  phpVersion: string;
  sslSecured: boolean;
  deploymentStatus: "Not Deployed" | "Deploying" | "Deployed";
  runtime: "dart" | "nodejs" | "php" | "python" | "docker";
};

export type ActionIconName =
  | "dashboard"
  | "dns"
  | "mail"
  | "rocket"
  | "folder"
  | "database"
  | "ftp"
  | "backup"
  | "copy"
  | "logs"
  | "git"
  | "wordpress"
  | "composer"
  | "seo"
  | "import"
  | "speed"
  | "insights"
  | "php"
  | "deploy";

export type DeploySource = "git" | "files" | "app";
export type DeployRuntime = "dart" | "nodejs" | "php" | "python" | "docker";
export type AppTemplate = "static" | "laravel" | "nodejs" | "flint-dart";
