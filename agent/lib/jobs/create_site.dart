import 'base_job.dart';
import '../api_client.dart';
import '../nginx/nginx_template.dart';

class CreateSiteJob extends BaseJob {
  CreateSiteJob(ApiClient api, String jobId, Map<String, dynamic> payload)
      : super(api, jobId, payload);

  @override
  Future<void> run() async {
    final domain = payload['domain'] as String?;
    final runtime = (payload['runtime'] as String? ?? 'php').toLowerCase();
    final runtimeVersion = payload['runtimeVersion'] as String? ?? '8.3';
    final rootPath = payload['rootPath'] as String? ?? '/var/www/$domain/public';
    final port = (payload['port'] as num?)?.toInt() ?? 80;

    if (domain == null) {
      await api.failJob(jobId, log: 'Missing domain in payload');
      return;
    }

    try {
      // 1. Create web root directories
      await shell('mkdir -p $rootPath');
      await shell('mkdir -p /var/www/$domain/logs');
      await shell('mkdir -p /var/www/$domain/storage');

      // 2. Set ownership to www-data
      await shell('chown -R www-data:www-data /var/www/$domain');

      // 3. Drop a default index file if none exists
      await shell(
          'test -f $rootPath/index.php || '
          'echo "<?php phpinfo();" > $rootPath/index.php');

      // 4. Write Nginx config
      final configPath = '/etc/nginx/sites-available/$domain.conf';
      final String nginxConfig;

      switch (runtime) {
        case 'php':
          nginxConfig = NginxTemplate.php(domain, rootPath, runtimeVersion);
        case 'nodejs':
        case 'node':
        case 'dart':
        case 'python':
        case 'docker':
          nginxConfig = NginxTemplate.reverseProxy(domain, port);
        default:
          nginxConfig = NginxTemplate.staticSite(domain, rootPath);
      }

      await writeFile(configPath, nginxConfig);

      // 5. Enable the site
      final enabledPath = '/etc/nginx/sites-enabled/$domain.conf';
      await shell('ln -sf $configPath $enabledPath');

      // 6. Test and reload Nginx
      await shell('nginx -t');
      await shell('systemctl reload nginx');

      await api.completeJob(jobId, log: 'Site $domain created successfully');
    } catch (e) {
      await api.failJob(jobId, log: e.toString());
    }
  }
}
