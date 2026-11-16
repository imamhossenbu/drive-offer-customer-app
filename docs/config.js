// Reads app-config.json (single source of truth shared with the apps) and fills
// any element marked with data-app / data-field. Falls back to the links already
// in the HTML if GitHub is unreachable.
(function () {
  var CONFIG_URL =
    'https://raw.githubusercontent.com/imamhossenbu/drive-offer-customer-app/main/app-config.json';

  var bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  function toBn(s) {
    return String(s).replace(/[0-9]/g, function (d) { return bn[d]; });
  }

  function apply(cfg) {
    document.querySelectorAll('[data-app]').forEach(function (el) {
      var app = cfg[el.getAttribute('data-app')] || {};
      var field = el.getAttribute('data-field');
      if (field === 'downloadUrl' && app.downloadUrl) el.href = app.downloadUrl;
      if (field === 'downloadUrlV7a' && app.downloadUrlV7a) el.href = app.downloadUrlV7a;
      if (field === 'version' && app.latestVersion) el.textContent = 'ভার্সন ' + toBn(app.latestVersion);
      if (field === 'size' && app.sizeMb) el.textContent = toBn(app.sizeMb) + ' MB';
      if (field === 'notes') el.textContent = app.releaseNotes || '';
    });

    var s = cfg.support || {};
    var any = false;
    [['whatsapp', function (v) { return 'https://wa.me/' + v.replace(/\D/g, '').replace(/^0/, '880'); }],
     ['telegram', function (v) { return v.indexOf('http') === 0 ? v : 'https://t.me/' + v.replace(/^@/, ''); }],
     ['phone', function (v) { return 'tel:' + v.replace(/[^\d+]/g, ''); }]
    ].forEach(function (pair) {
      var el = document.getElementById('support-' + pair[0]);
      var v = (s[pair[0]] || '').trim();
      if (el && v) {
        el.href = pair[1](v);
        if (pair[0] === 'phone') el.querySelector('span').textContent = toBn(v);
        el.classList.remove('hidden');
        any = true;
      }
    });
    var box = document.getElementById('support-section');
    if (box && any) box.classList.remove('hidden');
  }

  fetch(CONFIG_URL, { cache: 'no-store' })
    .then(function (r) { return r.ok ? r.json() : null; })
    .then(function (cfg) { if (cfg) apply(cfg); })
    .catch(function () { /* keep the HTML defaults */ });
})();

function copyText(text, btn) {
  function done() {
    var orig = btn.textContent;
    btn.textContent = '✅ কপি হয়েছে';
    setTimeout(function () { btn.textContent = orig; }, 2000);
  }
  if (navigator.clipboard) {
    navigator.clipboard.writeText(text).then(done, function () { window.prompt('লিংকটি কপি করুন:', text); });
  } else {
    window.prompt('লিংকটি কপি করুন:', text);
  }
}
