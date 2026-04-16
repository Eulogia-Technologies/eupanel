/// Generates Nginx server block configurations for each runtime type.
class NginxTemplate {
  /// PHP site — Nginx + PHP-FPM
  static String php(String domain, String rootPath, String phpVersion) => '''
server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;

    root $rootPath;
    index index.php index.html;

    access_log /var/log/nginx/${domain}_access.log;
    error_log  /var/log/nginx/${domain}_error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${phpVersion}-fpm.sock;
    }

    location ~ /\\.ht {
        deny all;
    }
}
''';

  /// Node.js / Dart / Python app — Nginx reverse proxy
  static String reverseProxy(String domain, int port) => '''
server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;

    access_log /var/log/nginx/${domain}_access.log;
    error_log  /var/log/nginx/${domain}_error.log;

    location / {
        proxy_pass         http://127.0.0.1:$port;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade \$http_upgrade;
        proxy_set_header   Connection keep-alive;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
''';

  /// Static HTML site
  static String staticSite(String domain, String rootPath) => '''
server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;

    root $rootPath;
    index index.html;

    access_log /var/log/nginx/${domain}_access.log;
    error_log  /var/log/nginx/${domain}_error.log;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
''';
}
