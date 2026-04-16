package nginx

import "fmt"

func buildVhost(cfg VhostConfig) string {
	if cfg.SSL {
		return buildSSLVhost(cfg)
	}
	return buildHTTPVhost(cfg)
}

func buildHTTPVhost(cfg VhostConfig) string {
	return fmt.Sprintf(`server {
    listen 80;
    listen [::]:80;
    server_name %s www.%s;

    root %s;
    index index.php index.html;

    access_log /var/log/nginx/%s.access.log;
    error_log  /var/log/nginx/%s.error.log;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php%s-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
`, cfg.Domain, cfg.Domain, cfg.WebRoot, cfg.Domain, cfg.Domain, cfg.PHPVersion)
}

func buildSSLVhost(cfg VhostConfig) string {
	return fmt.Sprintf(`server {
    listen 80;
    listen [::]:80;
    server_name %s www.%s;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name %s www.%s;

    root %s;
    index index.php index.html;

    ssl_certificate     /etc/letsencrypt/live/%s/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/%s/privkey.pem;
    include             /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam         /etc/letsencrypt/ssl-dhparams.pem;

    access_log /var/log/nginx/%s.access.log;
    error_log  /var/log/nginx/%s.error.log;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php%s-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
`, cfg.Domain, cfg.Domain,
		cfg.Domain, cfg.Domain,
		cfg.WebRoot,
		cfg.Domain, cfg.Domain,
		cfg.Domain, cfg.Domain,
		cfg.PHPVersion)
}
