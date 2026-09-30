export const ADMIN_HTML = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>StudyFocus Admin</title>
<style>
  :root { color-scheme: dark; }
  * { box-sizing: border-box; }
  body {
    margin: 0; padding: 0; background: #101418; color: #e8eef2;
    font-family: -apple-system, Segoe UI, Roboto, sans-serif;
  }
  .wrap { max-width: 760px; margin: 0 auto; padding: 24px 20px 80px; }
  h1 { font-size: 22px; display: flex; align-items: center; gap: 10px; }
  h1 span.dot { width: 10px; height: 10px; border-radius: 50%; background: #2dd4bf; display: inline-block; }
  .card {
    background: #1b2127; border-radius: 14px; padding: 18px; margin-bottom: 16px;
    border: 1px solid #262d35;
  }
  label { display: block; font-size: 12px; color: #9aa7b0; margin: 10px 0 4px; }
  input, textarea, select {
    width: 100%; background: #10151a; border: 1px solid #2c343c; color: #e8eef2;
    border-radius: 8px; padding: 10px; font-size: 14px; font-family: inherit;
  }
  textarea { min-height: 140px; resize: vertical; }
  button {
    background: #2dd4bf; color: #06201c; border: none; border-radius: 8px;
    padding: 10px 16px; font-weight: 600; cursor: pointer; font-size: 14px;
  }
  button.secondary { background: #2c343c; color: #e8eef2; }
  button.danger { background: #ef4444; color: white; }
  button:disabled { opacity: 0.5; cursor: not-allowed; }
  .row { display: flex; gap: 10px; flex-wrap: wrap; }
  .row > * { flex: 1; min-width: 140px; }
  .material-item {
    display: flex; justify-content: space-between; align-items: center;
    padding: 12px; border-bottom: 1px solid #262d35;
  }
  .material-item:last-child { border-bottom: none; }
  .material-title { font-weight: 600; }
  .material-sub { font-size: 12px; color: #9aa7b0; }
  .actions { display: flex; gap: 8px; }
  .error { color: #f87171; font-size: 13px; margin-top: 8px; }
  .hint { color: #9aa7b0; font-size: 12px; }
  #loginScreen { max-width: 360px; margin: 80px auto; }
</style>
</head>
<body>
<div class="wrap">

  <div id="loginScreen">
    <h1><span class="dot"></span> StudyFocus Admin</h1>
    <div class="card">
      <label>Admin password</label>
      <input type="password" id="passwordInput" placeholder="Enter admin password" />
      <div style="margin-top:14px;">
        <button onclick="login()">Log in</button>
      </div>
      <div class="error" id="loginError"></div>
    </div>
  </div>

  <div id="adminScreen" style="display:none;">
    <h1><span class="dot"></span> StudyFocus Admin
      <button class="secondary" style="margin-left:auto;font-size:12px;" onclick="logout()">Log out</button>
    </h1>

    <div class="card">
      <div style="display:flex;justify-content:space-between;align-items:center;">
        <strong>Study materials</strong>
        <button onclick="newMaterial()">+ Add subject/lesson</button>
      </div>
      <div id="materialsList"></div>
    </div>

    <div class="card" id="editCard" style="display:none;">
      <strong id="editTitle">New material</strong>

      <label>Study group</label>
      <input id="f_groupId" placeholder="e.g. grade10" />
      <label>Group display name</label>
      <input id="f_groupName" placeholder="e.g. Grade 10 Study Group" />

      <div class="row">
        <div>
          <label>Subject</label>
          <input id="f_subject" placeholder="e.g. Physics" />
        </div>
        <div>
          <label>Suggested minutes</label>
          <input id="f_minutes" type="number" min="1" placeholder="10" />
        </div>
      </div>

      <label>Lesson title</label>
      <input id="f_title" placeholder="e.g. Newton's Laws of Motion" />

      <label>Short summary</label>
      <input id="f_summary" placeholder="One line shown on the lesson card" />

      <label>Lesson note</label>
      <textarea id="f_content" placeholder="Full lesson text shown while studying"></textarea>

      <label>YouTube video link</label>
      <input id="f_video" placeholder="https://www.youtube.com/watch?v=..." />
      <div class="hint">Shown in-app; requires internet to play.</div>

      <div style="margin-top:16px;" class="row">
        <button onclick="saveMaterial()">Save</button>
        <button class="secondary" onclick="cancelEdit()">Cancel</button>
        <button class="danger" id="deleteBtn" style="display:none;" onclick="deleteMaterial()">Delete</button>
      </div>
      <div class="error" id="saveError"></div>
    </div>
  </div>
</div>

<script>
let PASSWORD = localStorage.getItem('sf_admin_password') || '';
let materials = [];
let editingId = null;

function headers(json) {
  const h = { 'X-Admin-Password': PASSWORD };
  if (json) h['Content-Type'] = 'application/json';
  return h;
}

async function login() {
  const pw = document.getElementById('passwordInput').value;
  const res = await fetch('/api/admin/login', {
    method: 'POST', headers: headers(true), body: JSON.stringify({ password: pw }),
  });
  const data = await res.json();
  if (data.ok) {
    PASSWORD = pw;
    localStorage.setItem('sf_admin_password', pw);
    showAdmin();
  } else {
    document.getElementById('loginError').textContent = 'Incorrect password.';
  }
}

function logout() {
  PASSWORD = '';
  localStorage.removeItem('sf_admin_password');
  document.getElementById('adminScreen').style.display = 'none';
  document.getElementById('loginScreen').style.display = 'block';
}

async function showAdmin() {
  document.getElementById('loginScreen').style.display = 'none';
  document.getElementById('adminScreen').style.display = 'block';
  await loadMaterials();
}

async function loadMaterials() {
  const res = await fetch('/api/admin/materials', { headers: headers(false) });
  if (res.status === 401) { logout(); return; }
  const data = await res.json();
  materials = [];
  (data.groups || []).forEach((g) => {
    g.materials.forEach((m) => materials.push({ ...m, groupName: g.name }));
  });
  renderList();
}

function renderList() {
  const el = document.getElementById('materialsList');
  if (materials.length === 0) {
    el.innerHTML = '<p class="hint">No materials yet. Add one above.</p>';
    return;
  }
  el.innerHTML = materials.map((m) => \`
    <div class="material-item">
      <div>
        <div class="material-title">\${escapeHtml(m.title)}</div>
        <div class="material-sub">\${escapeHtml(m.subject)} · \${escapeHtml(m.groupName)} · \${m.suggestedMinutes} min\${m.videoUrl ? ' · has video' : ''}</div>
      </div>
      <div class="actions">
        <button class="secondary" onclick="editMaterial('\${m.id}')">Edit</button>
      </div>
    </div>
  \`).join('');
}

function escapeHtml(s) {
  return String(s || '').replace(/[&<>"']/g, (c) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}

function newMaterial() {
  editingId = null;
  document.getElementById('editTitle').textContent = 'New material';
  document.getElementById('deleteBtn').style.display = 'none';
  ['f_groupId','f_groupName','f_subject','f_title','f_summary','f_content','f_video'].forEach((id) => document.getElementById(id).value = '');
  document.getElementById('f_minutes').value = 10;
  document.getElementById('saveError').textContent = '';
  document.getElementById('editCard').style.display = 'block';
  document.getElementById('editCard').scrollIntoView({ behavior: 'smooth' });
}

function editMaterial(id) {
  const m = materials.find((x) => x.id === id);
  if (!m) return;
  editingId = id;
  document.getElementById('editTitle').textContent = 'Edit: ' + m.title;
  document.getElementById('deleteBtn').style.display = 'inline-block';
  document.getElementById('f_groupId').value = m.groupId;
  document.getElementById('f_groupName').value = m.groupName;
  document.getElementById('f_subject').value = m.subject;
  document.getElementById('f_minutes').value = m.suggestedMinutes;
  document.getElementById('f_title').value = m.title;
  document.getElementById('f_summary').value = m.summary;
  document.getElementById('f_content').value = m.content;
  document.getElementById('f_video').value = m.videoUrl;
  document.getElementById('saveError').textContent = '';
  document.getElementById('editCard').style.display = 'block';
  document.getElementById('editCard').scrollIntoView({ behavior: 'smooth' });
}

function cancelEdit() {
  document.getElementById('editCard').style.display = 'none';
}

function slugify(s) {
  return String(s).toLowerCase().trim().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
}

async function saveMaterial() {
  const groupId = document.getElementById('f_groupId').value.trim();
  const groupName = document.getElementById('f_groupName').value.trim();
  const subject = document.getElementById('f_subject').value.trim();
  const title = document.getElementById('f_title').value.trim();
  const summary = document.getElementById('f_summary').value.trim();
  const content = document.getElementById('f_content').value;
  const videoUrl = document.getElementById('f_video').value.trim();
  const suggestedMinutes = parseInt(document.getElementById('f_minutes').value, 10) || 10;

  if (!groupId || !subject || !title) {
    document.getElementById('saveError').textContent = 'Study group, subject and title are required.';
    return;
  }

  const id = editingId || (slugify(subject) + '-' + slugify(title));
  const body = { id, groupId, groupName, subject, title, summary, content, videoUrl, suggestedMinutes, sortOrder: 0 };

  const res = await fetch(editingId ? '/api/admin/materials/' + encodeURIComponent(id) : '/api/admin/materials', {
    method: editingId ? 'PUT' : 'POST',
    headers: headers(true),
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    document.getElementById('saveError').textContent = data.error || 'Save failed.';
    return;
  }

  document.getElementById('editCard').style.display = 'none';
  await loadMaterials();
}

async function deleteMaterial() {
  if (!editingId) return;
  if (!confirm('Delete this lesson? This cannot be undone.')) return;
  await fetch('/api/admin/materials/' + encodeURIComponent(editingId), {
    method: 'DELETE', headers: headers(false),
  });
  document.getElementById('editCard').style.display = 'none';
  await loadMaterials();
}

if (PASSWORD) {
  showAdmin().catch(() => logout());
}
</script>
</body>
</html>
`;
