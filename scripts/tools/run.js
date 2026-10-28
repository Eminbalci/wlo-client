const { spawn } = require('child_process');
const path = require('path');

const projectRoot = path.resolve(__dirname, '../../');
const p = spawn('C:\\Godot\\godot_console.exe', ['--headless', '--path', projectRoot, '-s', 'res://scripts/tools/run_tests.gd']);
p.stdout.on('pipe', data => {});
p.stdout.on('data', d => process.stdout.write(d));
p.stderr.on('data', d => process.stderr.write(d));
p.on('close', code => process.exit(code));

