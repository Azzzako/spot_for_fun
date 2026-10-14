// Spot4Fun share links. See wrangler.toml for what this Worker does.

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// Mirrors lib/domain/enums.dart.
const TYPE_LABELS = {
  street: 'Stairs',
  park: 'Grind',
  bowl: 'Bowl',
  plaza: 'Bank',
  diy: 'DIY',
  skateshop: 'Skateshop',
  skatepark: 'Skatepark',
  gap: 'Gap',
};
const LEVEL_LABELS = {
  beginner: 'Principiante',
  intermediate: 'Intermedio',
  advanced: 'Avanzado',
};

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === '/.well-known/assetlinks.json') {
      return json(assetLinks(env));
    }

    const match = url.pathname.match(/^\/s\/([^/]+)\/?$/);
    if (match && UUID.test(match[1])) {
      return spotPage(match[1].toLowerCase(), url, env);
    }

    if (url.pathname === '/') {
      return html(page({ origin: url.origin, env }), 200);
    }

    // Static files in ./public (og-default.jpg, …).
    return env.ASSETS.fetch(request);
  },
};

function assetLinks(env) {
  const fingerprints = (env.ANDROID_SHA256 || '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  return [
    {
      relation: ['delegate_permission/common.handle_all_urls'],
      target: {
        namespace: 'android_app',
        package_name: env.ANDROID_PACKAGE,
        sha256_cert_fingerprints: fingerprints,
      },
    },
  ];
}

async function spotPage(id, url, env) {
  const spot = await fetchSpot(id, env);
  if (!spot) {
    return html(
      page({
        origin: url.origin,
        env,
        title: 'Spot no disponible',
        body: 'Este spot ya no existe o todavía no ha sido aprobado.',
      }),
      404,
    );
  }

  const photo = await fetchPhoto(id, env);
  const image = photo ?? `${url.origin}/og-default.jpg`;
  const type = TYPE_LABELS[spot.type] ?? spot.type;
  const level = LEVEL_LABELS[spot.difficulty] ?? spot.difficulty;
  const rating =
    spot.ratings_count > 0 ? ` · ★ ${Number(spot.avg_rating).toFixed(1)}` : '';
  const summary = `${type} · ${level}${rating}`;
  const description = spot.description?.trim()
    ? truncate(spot.description.trim(), 180)
    : `${summary}. Ábrelo en Spot4Fun.`;

  return html(
    page({
      origin: url.origin,
      env,
      canonical: url.origin + url.pathname,
      spotId: id,
      title: spot.name,
      summary,
      body: description,
      image,
      tags: [type, level],
    }),
    200,
  );
}

async function fetchSpot(id, env) {
  const q =
    `${env.SUPABASE_URL}/rest/v1/spots` +
    `?select=id,name,type,difficulty,avg_rating,ratings_count,description` +
    `&id=eq.${id}&status=eq.approved&limit=1`;
  const res = await fetch(q, { headers: { apikey: env.SUPABASE_PUBLISHABLE_KEY } });
  if (!res.ok) return null;
  const rows = await res.json();
  return rows[0] ?? null;
}

/// First approved spot photo (not a review photo). Prefers the small
/// thumb_<name>.jpg the app uploads next to it: WhatsApp drops preview
/// images much bigger than ~300 KB.
async function fetchPhoto(id, env) {
  const q =
    `${env.SUPABASE_URL}/rest/v1/spot_photos?select=url` +
    `&spot_id=eq.${id}&photo_status=eq.approved&review_id=is.null` +
    `&order=position.asc&limit=1`;
  const res = await fetch(q, { headers: { apikey: env.SUPABASE_PUBLISHABLE_KEY } });
  if (!res.ok) return null;
  const rows = await res.json();
  const full = rows[0]?.url;
  if (!full) return null;

  const thumb = full.replace(/\/([^/?#]+)\.[a-z0-9]+$/i, '/thumb_$1.jpg');
  if (thumb !== full) {
    const head = await fetch(thumb, { method: 'HEAD' });
    if (head.ok) return thumb;
  }
  return full;
}

function page({ origin, env, canonical, spotId, title, summary, body, image, tags = [] }) {
  const pageTitle = title ? `${title} · Spot4Fun` : 'Spot4Fun';
  const desc = body ?? 'Encuentra. Explora. Patina.';
  const img = image ?? `${origin}/og-default.jpg`;
  const appLink = spotId
    ? `intent://${new URL(origin).host}/s/${spotId}#Intent;scheme=https;package=${env.ANDROID_PACKAGE};end`
    : null;
  const live = env.PLAY_STORE_LIVE === 'true';
  const store = `https://play.google.com/store/apps/details?id=${env.ANDROID_PACKAGE}`;

  return `<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(pageTitle)}</title>
<meta name="description" content="${esc(desc)}">
<meta property="og:type" content="website">
<meta property="og:site_name" content="Spot4Fun">
<meta property="og:title" content="${esc(title ?? 'Spot4Fun')}">
<meta property="og:description" content="${esc(summary ? `${summary} — ${desc}` : desc)}">
<meta property="og:image" content="${esc(img)}">
${canonical ? `<meta property="og:url" content="${esc(canonical)}">` : ''}
<meta name="twitter:card" content="summary_large_image">
<meta name="theme-color" content="#111111">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Anton&family=Archivo:wght@400;600;800&display=swap">
<style>
  :root { color-scheme: dark; }
  * { box-sizing: border-box; }
  body { margin: 0; background: #111111; color: #F1EFE8; font-family: 'Archivo', system-ui, sans-serif; }
  main { max-width: 520px; margin: 0 auto; padding: 0 0 40px; }
  .photo { width: 100%; aspect-ratio: 4 / 3; object-fit: cover; display: block; background: #1C1C1C; }
  .content { padding: 0 20px; }
  .tags { display: flex; gap: 8px; margin: -16px 0 18px; position: relative; }
  .tape { background: #F2C14E; color: #111111; font-weight: 800; font-size: 12px; letter-spacing: 1.2px; text-transform: uppercase; padding: 5px 10px; transform: rotate(-3deg); }
  .tape.bone { background: #F1EFE8; transform: rotate(2deg); }
  h1 { font-family: 'Anton', sans-serif; font-weight: 400; font-size: 44px; line-height: 1; text-transform: uppercase; margin: 0 0 8px; }
  .meta { color: #A3A39B; font-size: 12px; font-weight: 800; letter-spacing: 1.2px; text-transform: uppercase; margin: 0 0 16px; }
  p { font-size: 16px; line-height: 1.5; margin: 0 0 24px; }
  .brand { font-family: 'Anton', sans-serif; font-size: 28px; padding: 20px; }
  .brand b { color: #F2C14E; font-weight: 400; }
  .btn { display: block; text-align: center; text-decoration: none; padding: 16px; border-radius: 4px; font-weight: 800; letter-spacing: 1.2px; text-transform: uppercase; font-size: 15px; margin-bottom: 10px; }
  .primary { background: #F2C14E; color: #111111; }
  .secondary { border: 1.5px solid #3A3A3A; color: #F1EFE8; }
  .soon { color: #A3A39B; font-size: 13px; text-align: center; }
</style>
</head>
<body>
<main>
  ${image ? `<img class="photo" src="${esc(img)}" alt="">` : `<div class="brand">SPOT<b>4</b>FUN</div>`}
  <div class="content">
    ${tags.length ? `<div class="tags">${tags.map((t, i) => `<span class="tape${i ? ' bone' : ''}">${esc(t)}</span>`).join('')}</div>` : ''}
    <h1>${esc(title ?? 'Spot4Fun')}</h1>
    ${summary ? `<div class="meta">${esc(summary)}</div>` : ''}
    <p>${esc(desc)}</p>
    ${appLink ? `<a class="btn primary" href="${esc(appLink)}">Abrir en Spot4Fun</a>` : ''}
    ${live
      ? `<a class="btn secondary" href="${esc(store)}">Descargar en Google Play</a>`
      : `<div class="soon">Spot4Fun llega muy pronto a Google Play.</div>`}
  </div>
</main>
</body>
</html>`;
}

function truncate(text, max) {
  return text.length <= max ? text : `${text.slice(0, max - 1).trimEnd()}…`;
}

function esc(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function html(body, status) {
  return new Response(body, {
    status,
    headers: {
      'content-type': 'text/html; charset=utf-8',
      'cache-control': 'public, max-age=300',
    },
  });
}

function json(data) {
  return new Response(JSON.stringify(data), {
    headers: {
      'content-type': 'application/json',
      'cache-control': 'public, max-age=3600',
    },
  });
}
