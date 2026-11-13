import esbuild from 'esbuild';
import fs from 'fs';

const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
const external = [
  ...Object.keys(pkg.dependencies || {}),
  ...Object.keys(pkg.dependencies || {}).map((dep) => `${dep}/*`),
];

await esbuild.build({
  entryPoints: ['src/index.ts'],
  bundle: true,
  platform: 'node',
  target: 'node22',
  format: 'esm',
  external,
  outfile: 'dist/index.js',
  tsconfig: 'tsconfig.json',
});

if (fs.existsSync('src/scripts/populate/index.ts')) {
  await esbuild.build({
    entryPoints: ['src/scripts/populate/index.ts'],
    bundle: true,
    platform: 'node',
    target: 'node22',
    format: 'esm',
    external,
    outfile: 'dist/scripts/populate.js',
    tsconfig: 'tsconfig.json',
  });
}
