// Mounted by ConfigMap; dependencies come from the existing auth-service image.
const { createRequire } = require('node:module');
const appRequire = createRequire('/app/package.json');
const { Client } = appRequire('pg');
const bcrypt = appRequire('bcrypt');
const assert = require('node:assert/strict');
const id = n => `d3e00000-0000-4000-8000-${String(n).padStart(12, '0')}`;
const building = id(1), group = id(2), area = id(3);
// Deliberately public credentials for local fictitious accounts only.
const password = 'HiveDemo@123';
const people = [
  { role: 'admin', name: 'Administrador Demo', permissions: ['@core:admin'] },
  { role: 'portaria', name: 'Portaria Demo', permissions: ['@delivery:create', '@delivery:view:building', '@visitor:create', '@visitor:view'] },
  { role: 'morador', name: 'Morador Demo', permissions: ['@reservation:create', '@reservation:view:residency', '@visitor:create', '@visitor:view', '@delivery:view:residency', '@complaint:create', '@complaint:view:residency', '@complaint:respond:residency'] },
].map((p, i) => ({ ...p, account: id(10 + i), user: id(20 + i), residence: id(30 + i), email: `${p.role}@demo.hiveapp.test` }));
const connections = new Map();
async function db(name) {
  if (!connections.has(name)) {
    const url = new URL(process.env.DATABASE_URL); url.pathname = `/${name}Db`;
    const client = new Client({ connectionString: url.toString(), connectionTimeoutMillis: 5000, query_timeout: 10000 });
    await client.connect(); connections.set(name, client);
  }
  return connections.get(name);
}
async function rows(name, sql, args = []) { return (await (await db(name)).query(sql, args)).rows; }
// Only internal constant identifiers are passed here, never input from the network.
async function ensure(name, table, record) {
  const keys = Object.keys(record), columns = keys.map(k => `"${k}"`).join(',');
  await rows(name, `INSERT INTO ${table} (${columns}) VALUES (${keys.map((_, i) => '$' + (i + 1)).join(',')}) ON CONFLICT DO NOTHING`, Object.values(record));
  const [existing] = await rows(name, `SELECT ${columns} FROM ${table} WHERE id=$1`, [record.id]);
  assert(existing, `Demo identity collision in ${table}; existing records were preserved`);
  for (const key of keys) {
    if (key === 'password') assert(await bcrypt.compare(password, existing.password), 'Demo password was changed; it will not be reset');
    else assert.deepEqual(existing[key], record[key], `Demo record changed: ${table}.${key}; it will not be overwritten`);
  }
}
async function bootstrap() {
  const hash = await bcrypt.hash(password, 10);
  for (const p of people) await ensure('auth', 'accounts', { id: p.account, name: p.name, email: p.email, password: hash, active: true });
  await ensure('core', 'buildings', { id: building, name: 'Condomínio Demonstração Kubernetes', active: true });
  await ensure('core', 'groups', { id: group, building, name: 'Torre Demo' });
  for (const [i, p] of people.entries()) {
    await ensure('core', 'residencies', { id: p.residence, groupId: group, code: `DEMO-${101 + i}`, name: `Apartamento Demo ${101 + i}` });
    await ensure('core', 'users', { id: p.user, accountId: p.account, residencyId: p.residence, buildingId: building, name: p.name, permissions: p.permissions, active: true });
  }
  // Last record signals that the dependency chain is ready for the scenarios Job.
  await ensure('reservation', 'common_areas', { id: area, building_id: building, name: 'Salão Demo Kubernetes', limit: 30 });
  console.log('Bootstrap complete: 3 accounts, 1 condominium, 3 residences, 1 common area.');
}
const ports = { auth: 8001, core: 8000, delivery: 8002, visitor: 8003, reservation: 8005, communication: 8006, complaint: 8007, 'event-bus': 8004 };
async function api(service, path, token, body, method = body ? 'POST' : 'GET') {
  const host = service === 'event-bus' ? service : `${service}-service`;
  const response = await fetch(`http://${host}:${ports[service]}${path}`, {
    method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    ...(body ? { body: JSON.stringify(body) } : {}), signal: AbortSignal.timeout(10000),
  });
  // Never log bodies, tokens, connection strings or passwords.
  assert(response.ok, `${service} ${path}: HTTP ${response.status}`);
  return response.json();
}
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
async function waitReady() {
  for (let attempt = 0; attempt < 60; attempt++) {
    try {
      assert((await rows('reservation', 'SELECT id FROM common_areas WHERE id=$1', [area])).length === 1);
      for (const service of Object.keys(ports)) await api(service, ['complaint', 'event-bus'].includes(service) ? '/health' : '/health/ready');
      return;
    } catch { await delay(3000); }
  }
  throw new Error('Dependencies unavailable: check populate-demo-bootstrap and API readiness');
}
function future(days) { const date = new Date(); date.setUTCDate(date.getUTCDate() + days); return date; }
async function scenarios() {
  const tokens = [];
  for (const p of people) {
    const login = await api('auth', '/auth/login', null, { email: p.email, password });
    tokens.push((await api('core', `/auth?userId=${p.user}`, login.token)).token);
  }
  const [admin, porter, resident] = tokens, p = people[2];
  // Check semantic identity, not today's date: reruns retain the original dates.
  if (!(await rows('reservation', 'SELECT id FROM reservations WHERE building_id=$1 AND common_area_id=$2 AND user_id=$3', [building, area, p.user])).length)
    await api('reservation', '/reservations', resident, { commonAreaId: area, commonAreaName: 'Salão Demo Kubernetes', reservationDate: future(3).toISOString().slice(0, 10) });
  if (!(await rows('visitor', 'SELECT id FROM visitor_accesses WHERE building_id=$1 AND residency_id=$2 AND rg=$3', [building, p.residence, 'DEMO-K8S-001'])).length)
    await api('visitor', '/access/register', resident, { name: 'Visitante Fictício Kubernetes', rg: 'DEMO-K8S-001', cpf: '00000000000', entryAt: new Date().toISOString() });
  const title = '[Demo K8s] Limpeza do salão';
  let [complaint] = await rows('complaint', 'SELECT id FROM complaints WHERE building_id=$1 AND resident_user_id=$2 AND title=$3', [building, p.user, title]);
  if (!complaint) complaint = await api('complaint', '/complaints', resident, { title, category: 'limpeza', description: 'Exemplo fictício para acompanhamento da administração.' });
  const message = '[Demo K8s] Solicitação recebida pela administração.';
  if (!(await rows('complaint', 'SELECT id FROM complaint_responses WHERE complaint_id=$1 AND message=$2', [complaint.id, message])).length)
    await api('complaint', `/complaints/${complaint.id}/responses`, admin, { message });
  const postTitle = '[Demo K8s] Assembleia de demonstração';
  if (!(await rows('communication', 'SELECT id FROM posts WHERE building_id=$1 AND title=$2', [building, postTitle])).length)
    await api('communication', '/posts', admin, { title: postTitle, description: 'Evento fictício para testar o calendário.', eventAt: future(7).toISOString(), recipientUserIds: people.map(p => p.user) });
  const description = '[Demo K8s] Encomenda do apartamento 103';
  let [parcel] = await rows('delivery', 'SELECT id FROM packages WHERE building_id=$1 AND residency_id=$2 AND description=$3', [building, p.residence, description]);
  if (!parcel) parcel = await api('delivery', '/packages', porter, { residencyId: p.residence, description });
  // Repair a lost event after a partial run, without creating another parcel.
  for (let attempt = 0; attempt < 12; attempt++) {
    const posts = await api('communication', '/posts', resident);
    if (posts.some(post => post.description.includes(parcel.id))) {
      console.log('Scenarios complete: reservation, visitor, complaint/response, calendar, parcel and recipient notification.');
      return;
    }
    await api('event-bus', '/events/PACKAGE_ARRIVED/publish', null, { eventId: parcel.id, data: { packageId: parcel.id, buildingId: building, residencyId: p.residence, description, authorUserId: people[1].user } });
    await delay(3000);
  }
  throw new Error('Parcel exists but notification was not received; check event-bus/communication and rerun');
}
async function main() {
  const stage = process.argv[2];
  assert(['bootstrap', 'scenarios'].includes(stage), 'Expected bootstrap or scenarios');
  if (stage === 'scenarios') await waitReady();
  // Serializes all demo writers. APIs do not acquire this lock: manual edits remain possible.
  await rows('auth', "SET lock_timeout = '120s'");
  await rows('auth', 'SELECT pg_advisory_lock(51625211)');
  if (stage === 'bootstrap') await bootstrap(); else await scenarios();
}
main().catch(error => {
  const databaseCode = /^[0-9A-Z]{5}$/.test(error.code ?? '');
  console.error(databaseCode ? `Demo failed (database code ${error.code}); inspect dependencies or identity collisions.` : error.message.split('\n')[0]);
  process.exitCode = 1;
}).finally(async () => { await Promise.allSettled([...connections.values()].map(client => client.end())); });
