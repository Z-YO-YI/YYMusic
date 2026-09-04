import { spawnSync } from 'node:child_process';
import {
  existsSync,
  mkdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from 'node:fs';
import { resolve } from 'node:path';

const repositoryRoot = resolve(import.meta.dirname, '..');
const outputDirectory = resolve(repositoryRoot, 'build', 'native-audio-poc');
const configPath = resolve(outputDirectory, 'openssl.cnf');
const certificatePath = resolve(outputDirectory, 'loopback-cert.pem');
const privateKeyPath = resolve(outputDirectory, 'loopback-key.pem');
const definesPath = resolve(outputDirectory, 'tls-defines.json');

if (process.argv.length !== 2) {
  throw new Error('This tool accepts no arguments');
}

mkdirSync(outputDirectory, { recursive: true });
writeFileSync(
  configPath,
  `[req]
distinguished_name = distinguished_name
x509_extensions = extensions
prompt = no

[distinguished_name]
CN = localhost

[extensions]
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @subject_alt_names

[subject_alt_names]
DNS.1 = localhost
IP.1 = 127.0.0.1
`,
  { encoding: 'utf8', mode: 0o600 },
);

try {
  const openssl = findOpenSsl();
  const generated = spawnSync(
    openssl,
    [
      'req',
      '-x509',
      '-newkey',
      'rsa:2048',
      '-nodes',
      '-sha256',
      '-days',
      '1',
      '-keyout',
      privateKeyPath,
      '-out',
      certificatePath,
      '-config',
      configPath,
    ],
    { encoding: 'utf8' },
  );
  if (generated.error || generated.status !== 0) {
    throw new Error('OpenSSL could not generate the ephemeral loopback TLS fixture');
  }

  const certificate = readFileSync(certificatePath);
  const privateKey = readFileSync(privateKeyPath);
  writeFileSync(
    definesPath,
    `${JSON.stringify({
      YYMUSIC_POC_TLS_CERT_B64: certificate.toString('base64'),
      YYMUSIC_POC_TLS_KEY_B64: privateKey.toString('base64'),
    })}\n`,
    { encoding: 'utf8', mode: 0o600 },
  );
} finally {
  rmSync(configPath, { force: true });
  rmSync(certificatePath, { force: true });
  rmSync(privateKeyPath, { force: true });
}

console.log('Generated ephemeral loopback TLS defines in ignored build output.');

function findOpenSsl() {
  const direct = spawnSync('openssl', ['version'], { encoding: 'utf8' });
  if (!direct.error && direct.status === 0) return 'openssl';
  if (process.platform !== 'win32') {
    throw new Error('OpenSSL is unavailable');
  }
  const gitExecPath = spawnSync('git', ['--exec-path'], { encoding: 'utf8' });
  if (gitExecPath.error || gitExecPath.status !== 0) {
    throw new Error('OpenSSL is unavailable');
  }
  const gitRoot = resolve(gitExecPath.stdout.trim(), '..', '..', '..');
  for (const candidate of [
    resolve(gitRoot, 'usr', 'bin', 'openssl.exe'),
    resolve(gitRoot, 'mingw64', 'bin', 'openssl.exe'),
  ]) {
    if (existsSync(candidate)) return candidate;
  }
  throw new Error('OpenSSL is unavailable');
}
