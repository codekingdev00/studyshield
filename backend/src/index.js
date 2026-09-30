import { ADMIN_HTML } from './admin_page.js';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, X-Admin-Password',
};

function json(data, init = {}) {
  return new Response(JSON.stringify(data), {
    ...init,
    headers: { 'Content-Type': 'application/json', ...CORS_HEADERS, ...(init.headers || {}) },
  });
}

function requireAuth(request, env) {
  const password = request.headers.get('X-Admin-Password') || '';
  if (!env.ADMIN_PASSWORD || password !== env.ADMIN_PASSWORD) {
    return false;
  }
  return true;
}

function rowToMaterial(row) {
  return {
    id: row.id,
    groupId: row.group_id,
    title: row.title,
    subject: row.subject,
    summary: row.summary,
    content: row.content,
    videoUrl: row.video_url,
    suggestedMinutes: row.suggested_minutes,
    sortOrder: row.sort_order,
  };
}

async function listMaterials(env) {
  const groups = await env.DB.prepare('SELECT * FROM groups').all();
  const materials = await env.DB.prepare(
    'SELECT * FROM materials ORDER BY group_id, sort_order'
  ).all();

  return groups.results.map((g) => ({
    id: g.id,
    name: g.name,
    materials: materials.results
      .filter((m) => m.group_id === g.id)
      .map(rowToMaterial),
  }));
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const { pathname } = url;

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: CORS_HEADERS });
    }

    // Public: serve the admin page itself (auth happens client-side via password calls)
    if (pathname === '/admin' || pathname === '/admin/') {
      return new Response(ADMIN_HTML, {
        headers: { 'Content-Type': 'text/html; charset=utf-8' },
      });
    }

    // Public: fetch study groups + materials for the Flutter app
    if (pathname === '/api/materials' && request.method === 'GET') {
      const groups = await listMaterials(env);
      return json({ groups });
    }

    // Admin: verify password
    if (pathname === '/api/admin/login' && request.method === 'POST') {
      const body = await request.json().catch(() => ({}));
      const ok = !!env.ADMIN_PASSWORD && body.password === env.ADMIN_PASSWORD;
      return json({ ok }, { status: ok ? 200 : 401 });
    }

    // Admin: list materials (same data, but via authenticated route for the admin UI)
    if (pathname === '/api/admin/materials' && request.method === 'GET') {
      if (!requireAuth(request, env)) return json({ error: 'Unauthorized' }, { status: 401 });
      const groups = await listMaterials(env);
      return json({ groups });
    }

    // Admin: create material
    if (pathname === '/api/admin/materials' && request.method === 'POST') {
      if (!requireAuth(request, env)) return json({ error: 'Unauthorized' }, { status: 401 });
      const b = await request.json().catch(() => ({}));
      if (!b.id || !b.groupId || !b.title || !b.subject) {
        return json({ error: 'id, groupId, title and subject are required' }, { status: 400 });
      }
      await env.DB.prepare(
        `INSERT OR REPLACE INTO groups (id, name) VALUES (?, ?)`
      ).bind(b.groupId, b.groupName || b.groupId).run();

      await env.DB.prepare(
        `INSERT INTO materials (id, group_id, title, subject, summary, content, video_url, suggested_minutes, sort_order)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
      ).bind(
        b.id, b.groupId, b.title, b.subject, b.summary || '', b.content || '',
        b.videoUrl || '', b.suggestedMinutes || 10, b.sortOrder || 0
      ).run();

      return json({ ok: true });
    }

    // Admin: update material
    const materialMatch = pathname.match(/^\/api\/admin\/materials\/([^/]+)$/);
    if (materialMatch && request.method === 'PUT') {
      if (!requireAuth(request, env)) return json({ error: 'Unauthorized' }, { status: 401 });
      const id = decodeURIComponent(materialMatch[1]);
      const b = await request.json().catch(() => ({}));

      await env.DB.prepare(
        `UPDATE materials SET title = ?, subject = ?, summary = ?, content = ?,
           video_url = ?, suggested_minutes = ?, sort_order = ?, group_id = ?
         WHERE id = ?`
      ).bind(
        b.title, b.subject, b.summary || '', b.content || '', b.videoUrl || '',
        b.suggestedMinutes || 10, b.sortOrder || 0, b.groupId, id
      ).run();

      return json({ ok: true });
    }

    // Admin: delete material
    if (materialMatch && request.method === 'DELETE') {
      if (!requireAuth(request, env)) return json({ error: 'Unauthorized' }, { status: 401 });
      const id = decodeURIComponent(materialMatch[1]);
      await env.DB.prepare('DELETE FROM materials WHERE id = ?').bind(id).run();
      return json({ ok: true });
    }

    return json({ error: 'Not found' }, { status: 404 });
  },
};
