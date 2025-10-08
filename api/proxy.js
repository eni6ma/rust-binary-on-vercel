import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

export default async function handler(req, res) {
	try {
		const chunks = [];
		for await (const chunk of req) {
			chunks.push(chunk);
		}
		const bodyBuffer = Buffer.concat(chunks);
		const bodyString = bodyBuffer.toString('utf8');

		const binaryUrl = new URL('./bin/cli', import.meta.url);
		const binaryPath = fileURLToPath(binaryUrl);

		const child = spawn(binaryPath, { stdio: ['pipe', 'pipe', 'pipe'] });

		child.stdin.write(bodyString);
		child.stdin.end();

		let stdout = '';
		let stderr = '';
		child.stdout.on('data', (d) => (stdout += d.toString('utf8')));
		child.stderr.on('data', (d) => (stderr += d.toString('utf8')));

		child.on('close', (code) => {
			if (code !== 0) {
				res.status(500).json({ error: 'rust binary failed', code, stderr });
				return;
			}
			res.setHeader('content-type', 'application/json');
			res.status(200).send(stdout);
		});
	} catch (err) {
		res.status(500).json({ error: 'proxy error', message: String(err) });
	}
}
