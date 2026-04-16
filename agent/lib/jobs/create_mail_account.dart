import 'dart:io';
import 'base_job.dart';
import '../api_client.dart';

/// Creates a mail account using Postfix + Dovecot (standard Ubuntu mail stack).
/// Assumes virtual mailboxes are configured with a password file at
/// /etc/dovecot/virtual_passwd (managed with doveadm).
///
/// For a full mail stack consider integrating with iRedMail, Mailcow, or Mailu.
class CreateMailAccountJob extends BaseJob {
  CreateMailAccountJob(ApiClient api, String jobId, Map<String, dynamic> payload)
      : super(api, jobId, payload);

  @override
  Future<void> run() async {
    final email = payload['email'] as String?;
    final domain = payload['domain'] as String?;
    final password = payload['password'] as String?;

    if (email == null || domain == null || password == null) {
      await api.failJob(jobId, log: 'Missing email, domain, or password');
      return;
    }

    try {
      final localPart = email.split('@').first;

      // Create mailbox directories
      final mailboxPath = '/var/mail/vhosts/$domain/$localPart';
      await shell('mkdir -p $mailboxPath/{cur,new,tmp}');
      await shell('chown -R vmail:vmail /var/mail/vhosts/$domain');

      // Hash password with doveadm
      final hashedPassword =
          await _capture('doveadm pw -s SHA512-CRYPT -p $password');

      // Append to Dovecot virtual passwd file
      final passwdFile = '/etc/dovecot/virtual_passwd';
      await shell(
          'grep -qF "$email:" $passwdFile 2>/dev/null || '
          'echo "$email:$hashedPassword" >> $passwdFile');

      // Add to Postfix virtual mailbox map
      final vmailboxFile = '/etc/postfix/vmailbox';
      await shell(
          'grep -qF "$email " $vmailboxFile 2>/dev/null || '
          'echo "$email $domain/$localPart/" >> $vmailboxFile');
      await shell('postmap $vmailboxFile');

      // Ensure domain is in virtual_domains
      final vdomainFile = '/etc/postfix/virtual_domains';
      await shell(
          'grep -qxF "$domain" $vdomainFile 2>/dev/null || '
          'echo "$domain" >> $vdomainFile');

      await shell('systemctl reload postfix dovecot');

      await api.completeJob(jobId,
          log: 'Mail account $email created on $domain');
    } catch (e) {
      await api.failJob(jobId, log: e.toString());
    }
  }

  Future<String> _capture(String command) async {
    final result =
        await Process.run('bash', ['-c', command], runInShell: false);
    if (result.exitCode != 0) {
      throw Exception('Command failed: $command — ${result.stderr}');
    }
    return result.stdout.toString().trim();
  }
}
