/* ============================================================
   QUICKCHAT — chat.js (version sans messages vocaux)
   ============================================================ */

// =========================================================
// ÉDITION DE MESSAGES
// =========================================================
function showEditForm(messageId) {
    var el = document.getElementById('editForm' + messageId);
    if (el) el.style.display = 'block';
}
function hideEditForm(messageId) {
    var el = document.getElementById('editForm' + messageId);
    if (el) el.style.display = 'none';
}

// =========================================================
// SCROLL
// =========================================================
function scrollToBottom() {
    var c = document.getElementById('messagesContainer');
    if (c) c.scrollTop = c.scrollHeight;
}

// =========================================================
// RECHERCHE DANS LA CONVERSATION
// =========================================================
var searchMessages     = [];
var currentSearchIndex = -1;
var searchTerm         = '';

function toggleSearchBar() {
    var bar = document.getElementById('searchBar');
    if (!bar) return;
    if (bar.style.display === 'none' || bar.style.display === '') {
        bar.style.display = 'block';
        var si = document.getElementById('searchInputChat');
        if (si) si.focus();
    } else {
        bar.style.display = 'none';
        clearHighlights();
    }
}

function searchInConversation() {
    var input = document.getElementById('searchInputChat');
    if (!input) return;
    searchTerm = input.value.trim().toLowerCase();
    var messages = document.querySelectorAll('.message');
    searchMessages = [];
    clearHighlights();
    if (searchTerm === '') {
        var rd = document.getElementById('searchResults');
        if (rd) rd.innerHTML = '';
        return;
    }
    messages.forEach(function(msg) {
        var bubble = msg.querySelector('.message-bubble');
        if (!bubble) return;
        var txt = bubble.innerText;
        if (txt.toLowerCase().indexOf(searchTerm) !== -1) {
            searchMessages.push({ element: msg, originalText: txt });
            bubble.innerHTML = highlightText(txt, searchTerm);
        }
    });
    var rd = document.getElementById('searchResults');
    if (rd) {
        if (searchMessages.length > 0) {
            rd.innerHTML = searchMessages.length + ' résultat(s)';
            currentSearchIndex = 0;
            goToResult(0);
        } else {
            rd.innerHTML = 'Aucun résultat';
            currentSearchIndex = -1;
        }
    }
}

function highlightText(text, term) {
    var re = new RegExp('(' + term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ')', 'gi');
    return text.replace(re, '<span class="search-highlight">$1</span>').replace(/\n/g, '<br>');
}

function goToResult(idx) {
    if (!searchMessages.length || idx < 0 || idx >= searchMessages.length) return;
    searchMessages.forEach(function(m) { m.element.classList.remove('current-result'); });
    var cur = searchMessages[idx];
    cur.element.classList.add('current-result');
    cur.element.scrollIntoView({ behavior: 'smooth', block: 'center' });
    var rd = document.getElementById('searchResults');
    if (rd) rd.innerHTML = (idx + 1) + ' / ' + searchMessages.length;
}

function nextResult() {
    if (!searchMessages.length) return;
    currentSearchIndex = (currentSearchIndex + 1) % searchMessages.length;
    goToResult(currentSearchIndex);
}
function prevResult() {
    if (!searchMessages.length) return;
    currentSearchIndex = (currentSearchIndex - 1 + searchMessages.length) % searchMessages.length;
    goToResult(currentSearchIndex);
}

function clearHighlights() {
    document.querySelectorAll('.message').forEach(function(msg) {
        var bubble = msg.querySelector('.message-bubble');
        if (bubble) bubble.innerHTML = bubble.innerText.replace(/\n/g, '<br>');
        msg.classList.remove('current-result');
    });
    searchMessages = [];
    currentSearchIndex = -1;
}

function closeSearch() {
    var bar = document.getElementById('searchBar');
    if (bar) bar.style.display = 'none';
    var si = document.getElementById('searchInputChat');
    if (si) si.value = '';
    clearHighlights();
    var rd = document.getElementById('searchResults');
    if (rd) rd.innerHTML = '';
}

// =========================================================
// RÉACTIONS — délai 800 ms + cancelHide robuste
// =========================================================
var _hideTimeout = null;

function addReaction(messageId, reaction, receiverId) {
    _submitForm('reaction', { messageId: messageId, receiverId: receiverId, reaction: reaction, action: 'add' });
}
function removeReaction(messageId, receiverId) {
    _submitForm('reaction', { messageId: messageId, receiverId: receiverId, action: 'remove' });
}
function toggleReaction(messageId, reaction, receiverId) {
    addReaction(messageId, reaction, receiverId);
}

function showReactionPicker(element) {
    if (_hideTimeout) { clearTimeout(_hideTimeout); _hideTimeout = null; }
    var popup = element.querySelector('.reaction-picker-popup');
    if (popup) popup.style.display = 'flex';
}

function hideReactionPickerDelayed(element) {
    _hideTimeout = setTimeout(function() {
        var popup = element.querySelector('.reaction-picker-popup');
        if (popup) popup.style.display = 'none';
        _hideTimeout = null;
    }, 800);
}

function hideReactionPicker(element) {
    if (_hideTimeout) { clearTimeout(_hideTimeout); _hideTimeout = null; }
    var picker = element.closest ? element.closest('.reaction-picker') : null;
    if (!picker) picker = element.parentElement;
    if (!picker) return;
    var popup = picker.querySelector('.reaction-picker-popup');
    if (popup) popup.style.display = 'none';
}

function cancelHideReactionPicker() {
    if (_hideTimeout) { clearTimeout(_hideTimeout); _hideTimeout = null; }
}

// =========================================================
// MENU PROFIL
// =========================================================
function toggleMenu() {
    var menu = document.getElementById('profileMenu');
    if (menu) menu.style.display = (menu.style.display === 'none' || !menu.style.display) ? 'block' : 'none';
}

// =========================================================
// CHANGER PSEUDO
// =========================================================
function showEditNameModal() {
    var m = document.getElementById('editNameModal');
    if (m) { m.style.display = 'flex'; var i = document.getElementById('newDisplayName'); if (i) i.value = ''; }
}
function closeNameModal() { var m = document.getElementById('editNameModal'); if (m) m.style.display = 'none'; }
function updateDisplayName() {
    var n = document.getElementById('newDisplayName').value;
    if (!n.trim()) { alert('Veuillez entrer un pseudo'); return; }
    _submitForm('updateDisplayName', { displayName: n });
}



// =========================================================
// ★★★ THÈME — correction principale ★★★
// =========================================================
function showThemeModal() {
    var m = document.getElementById('themeModal');
    if (!m) return;
    m.style.display = 'flex';
    var cur = _getCurrentConversationTheme();
    document.querySelectorAll('.theme-preview-card').forEach(function(c) {
        c.classList.toggle('active', c.getAttribute('data-theme') === cur);
    });
}

function closeThemeModal() {
    var m = document.getElementById('themeModal');
    if (m) m.style.display = 'none';
}

function selectTheme(theme) {
    closeThemeModal();
    document.querySelectorAll('.theme-preview-card').forEach(function(c) {
        c.classList.toggle('active', c.getAttribute('data-theme') === theme);
    });
    _applyThemeToBody(theme);
    initThemeAnimations(theme);
    var hdr = document.querySelector('.chat-header');
    var contactId = hdr ? hdr.getAttribute('data-contact-id') : null;
    if (contactId) {
        fetch('updateTheme', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: 'contactId=' + encodeURIComponent(contactId) + '&theme=' + encodeURIComponent(theme)
        }).catch(function(err) { console.error('Erreur sauvegarde thème :', err); });
    }
}

function applyTheme(theme) { selectTheme(theme); }

function _applyThemeToBody(theme) {
    var body = document.body;
    var kept = body.className.split(/\s+/).filter(function(c) { return !c.startsWith('theme-'); });
    body.className = kept.join(' ').trim();
    if (theme && theme !== 'default') {
        body.classList.add('theme-' + theme);
    }
}

function _getCurrentConversationTheme() {
    var classes = document.body.className.split(' ');
    for (var i = 0; i < classes.length; i++) {
        if (classes[i].startsWith('theme-')) return classes[i].replace('theme-', '');
    }
    return 'default';
}

// =========================================================
// ★★★ ANIMATIONS PAR THÈME ★★★
// =========================================================
var _animIntervals = [];
var _animTimeouts  = [];

function _clearAnimations() {
    _animIntervals.forEach(clearInterval);
    _animIntervals = [];
    _animTimeouts.forEach(clearTimeout);
    _animTimeouts  = [];
    document.querySelectorAll('.qc-anim-container,.aurora-decor-el').forEach(function(el) { if (el && el.remove) el.remove(); });
}

function _makeContainer(fullWidth) {
    var chatArea = document.querySelector('.chat-area');
    if (!chatArea) return null;
    var c = document.createElement('div');
    c.className = 'qc-anim-container' + (fullWidth ? ' full-width' : '');
    c.style.cssText = [
        'position:absolute',
        'top:0', 'left:0',
        'width:' + (fullWidth ? '100%' : '220px'),
        'height:calc(100% - 72px)',
        'pointer-events:none',
        'z-index:0',
        'overflow:hidden'
    ].join(';');
    chatArea.insertBefore(c, chatArea.firstChild);
    return c;
}

function initThemeAnimations(theme) {
    _clearAnimations();
    var map = {
        'ocean':      _anim_ocean,
        'rose':       _anim_rose,
        'forest':     _anim_forest,
        'midnight':   _anim_midnight,
        'sunset':     _anim_sunset,
        'aurora':     _anim_aurora,
        'cherry':     _anim_cherry,
        'cosmic':     _anim_cosmic,
        'golden':     _anim_golden,
        'basketball': _anim_basketball
    };
    if (map[theme]) map[theme]();
}

function _anim_ocean() {
    var c = _makeContainer(false);
    if (!c) return;
    function spawnBubble() {
        var el = document.createElement('div');
        el.className = 'ocean-bubble';
        var sz = 5 + Math.random() * 16;
        var x  = 10 + Math.random() * 180;
        var dur = 7 + Math.random() * 6;
        el.style.cssText = 'position:absolute;width:' + sz + 'px;height:' + sz + 'px;bottom:-30px;left:' + x + 'px;animation:bubbleRise ' + dur + 's ease-out forwards;';
        c.appendChild(el);
        _animTimeouts.push(setTimeout(function() { if (el.parentNode) el.parentNode.removeChild(el); }, (dur + 1) * 1000));
    }
    var fishPool = ['🐠','🐟','🐡','🦈'];
    function spawnFish() {
        var el = document.createElement('div');
        el.className = 'ocean-fish';
        el.textContent = fishPool[Math.floor(Math.random() * fishPool.length)];
        var y   = 20 + Math.random() * 70;
        var dur = 10 + Math.random() * 8;
        var sz  = 16 + Math.random() * 12;
        el.style.cssText = 'position:absolute;font-size:' + sz + 'px;top:' + y + '%;left:-60px;animation:fishSwim ' + dur + 's linear forwards;';
        c.appendChild(el);
        _animTimeouts.push(setTimeout(function() { if (el.parentNode) el.parentNode.removeChild(el); }, (dur + 1) * 1000));
    }
    spawnBubble(); spawnBubble(); spawnBubble(); spawnFish();
    _animIntervals.push(setInterval(spawnBubble, 900));
    _animIntervals.push(setInterval(spawnFish, 8000));
}

function _anim_rose() {
    var c = _makeContainer(false);
    if (!c) return;
    var pool = ['❤️','💕','💖','💗','💓','💝','💞','🩷'];
    function spawnHeart() {
        var el = document.createElement('span');
        el.className = 'rose-heart';
        el.textContent = pool[Math.floor(Math.random() * pool.length)];
        var x   = 10 + Math.random() * 170;
        var dur = 5 + Math.random() * 4;
        var sz  = 18 + Math.random() * 18;
        el.style.cssText = 'position:absolute;bottom:0;left:' + x + 'px;font-size:' + sz + 'px;animation:roseHeartFloat ' + dur + 's ease-out forwards;';
        c.appendChild(el);
        _animTimeouts.push(setTimeout(function() { if (el.parentNode) el.parentNode.removeChild(el); }, (dur + 1) * 1000));
    }
    spawnHeart(); spawnHeart(); spawnHeart();
    _animIntervals.push(setInterval(spawnHeart, 1100));
}

function _anim_forest() {
    var c = _makeContainer(false);
    if (!c) return;
    var leaves = ['🍃','🍀','🌿','🍂','🍁'];
    function spawnLeaf() {
        var el = document.createElement('span');
        el.className = 'forest-leaf';
        el.textContent = leaves[Math.floor(Math.random() * leaves.length)];
        var x   = 10 + Math.random() * 180;
        var dur = 8 + Math.random() * 6;
        el.style.cssText = 'position:absolute;top:-40px;left:' + x + 'px;font-size:' + (14 + Math.random() * 14) + 'px;animation:leafFall ' + dur + 's linear forwards;';
        c.appendChild(el);
        _animTimeouts.push(setTimeout(function() { if (el.parentNode) el.parentNode.removeChild(el); }, (dur + 1) * 1000));
    }
    for (var i = 0; i < 8; i++) {
        (function() {
            var fly = document.createElement('div');
            fly.className = 'forest-firefly';
            fly.style.cssText = 'position:absolute;left:' + (15 + Math.random() * 160) + 'px;top:' + (20 + Math.random() * 70) + '%;animation-duration:' + (3 + Math.random() * 4) + 's;animation-delay:' + (-Math.random() * 4) + 's;';
            c.appendChild(fly);
        })();
    }
    spawnLeaf(); spawnLeaf();
    _animIntervals.push(setInterval(spawnLeaf, 1400));
}

function _anim_midnight() {
    var c = _makeContainer(true);
    if (!c) return;
    for (var i = 0; i < 80; i++) {
        var s  = document.createElement('div');
        s.className = 'midnight-star';
        var sz = 0.8 + Math.random() * 2.5;
        s.style.cssText = 'position:absolute;width:' + sz + 'px;height:' + sz + 'px;top:' + (Math.random() * 85) + '%;left:' + (Math.random() * 100) + '%;animation-duration:' + (1.5 + Math.random() * 3) + 's;animation-delay:' + (-Math.random() * 4) + 's;';
        c.appendChild(s);
    }
    function spawnShooting() {
        var el = document.createElement('div');
        el.className = 'shooting-star';
        var tx = Math.random() * 40;
        var ty = Math.random() * 50;
        el.style.cssText = 'position:absolute;top:' + ty + '%;left:' + tx + '%;transform:rotate(-35deg);animation-duration:' + (2 + Math.random()) + 's;';
        c.appendChild(el);
        _animTimeouts.push(setTimeout(function() { if (el.parentNode) el.parentNode.removeChild(el); }, 3500));
    }
    spawnShooting();
    _animIntervals.push(setInterval(spawnShooting, 6000));
}

function _anim_sunset() {
    var c = _makeContainer(true);
    if (!c) return;
    var cloudData = [
        { w: 160, h: 55, top: '12%', dur: 24, delay: 0 },
        { w: 110, h: 40, top: '28%', dur: 32, delay: -10 },
        { w: 190, h: 65, top: '18%', dur: 20, delay: -15 }
    ];
    cloudData.forEach(function(d) {
        var el = document.createElement('div');
        el.className = 'sunset-cloud';
        el.style.cssText = 'position:absolute;top:' + d.top + ';left:-220px;width:' + d.w + 'px;height:' + d.h + 'px;animation:cloudDrift ' + d.dur + 's linear infinite;animation-delay:' + d.delay + 's;';
        c.appendChild(el);
    });
}

function _anim_aurora() {
    var c = _makeContainer(true);
    if (!c) return;
    for (var i = 0; i < 60; i++) {
        var s  = document.createElement('div');
        s.className = 'aurora-star';
        var sz = 0.8 + Math.random() * 2;
        s.style.cssText = 'position:absolute;width:' + sz + 'px;height:' + sz + 'px;top:' + (Math.random() * 70) + '%;left:' + (Math.random() * 100) + '%;animation-duration:' + (2 + Math.random() * 3) + 's;animation-delay:' + (-Math.random() * 5) + 's;';
        c.appendChild(s);
    }
    var decor = document.createElement('div');
    decor.className = 'aurora-decor-el';
    decor.style.cssText = 'position:absolute;bottom:0;left:0;width:200px;height:180px;pointer-events:none;z-index:0;background:url("data:image/svg+xml,%3Csvg xmlns=\'http://www.w3.org/2000/svg\' viewBox=\'0 0 200 180\'%3E%3Cpolygon points=\'0,180 60,60 120,180\' fill=\'%230f172a\' opacity=\'0.7\'/%3E%3Cpolygon points=\'40,180 110,40 180,180\' fill=\'%230f1f3d\' opacity=\'0.6\'/%3E%3Cpolygon points=\'100,180 160,80 200,180\' fill=\'%230a1628\' opacity=\'0.75\'/%3E%3C/svg%3E") no-repeat left bottom / 200px;';
    var chatArea = document.querySelector('.chat-area');
    if (chatArea) chatArea.appendChild(decor);
}

function _anim_cherry() {
    var c = _makeContainer(true);
    if (!c) return;
    var petals = ['🌸','🌺','🌷','🌼'];
    function spawnPetal() {
        var el = document.createElement('span');
        el.className = 'cherry-petal';
        el.textContent = petals[Math.floor(Math.random() * petals.length)];
        var x   = Math.random() * 95;
        var dur = 7 + Math.random() * 7;
        el.style.cssText = 'position:absolute;top:-40px;left:' + x + '%;font-size:' + (14 + Math.random() * 12) + 'px;animation:petalFall ' + dur + 's linear forwards;';
        c.appendChild(el);
        _animTimeouts.push(setTimeout(function() { if (el.parentNode) el.parentNode.removeChild(el); }, (dur + 1) * 1000));
    }
    spawnPetal(); spawnPetal(); spawnPetal(); spawnPetal();
    _animIntervals.push(setInterval(spawnPetal, 800));
}

function _anim_cosmic() {
    var c = _makeContainer(true);
    if (!c) return;
    for (var i = 0; i < 100; i++) {
        var s  = document.createElement('div');
        s.className = 'cosmic-star';
        var sz = 0.7 + Math.random() * 2.5;
        s.style.cssText = 'position:absolute;width:' + sz + 'px;height:' + sz + 'px;top:' + (Math.random() * 100) + '%;left:' + (Math.random() * 100) + '%;animation:starTwinkle ' + (1.5 + Math.random() * 4) + 's ease-in-out infinite;animation-delay:' + (-Math.random() * 5) + 's;';
        c.appendChild(s);
    }
    function spawnShooting() {
        var el = document.createElement('div');
        el.className = 'cosmic-shooting';
        el.style.cssText = 'position:absolute;top:' + (Math.random() * 50) + '%;left:' + (Math.random() * 30) + '%;animation-duration:' + (1.5 + Math.random()) + 's;';
        c.appendChild(el);
        _animTimeouts.push(setTimeout(function() { if (el.parentNode) el.parentNode.removeChild(el); }, 3000));
    }
    spawnShooting();
    _animIntervals.push(setInterval(spawnShooting, 5000));
}

function _anim_golden() {
    var c = _makeContainer(false);
    if (!c) return;
    var sparkles = ['✨','⭐','💫','🌟'];
    function spawnParticle() {
        var el = document.createElement('div');
        el.className = 'golden-particle';
        var sz  = 4 + Math.random() * 8;
        var x   = 20 + Math.random() * 160;
        var dur = 4 + Math.random() * 4;
        el.style.cssText = 'position:absolute;bottom:0;left:' + x + 'px;width:' + sz + 'px;height:' + sz + 'px;animation:goldRise ' + dur + 's ease-out forwards;';
        c.appendChild(el);
        _animTimeouts.push(setTimeout(function() { if (el.parentNode) el.parentNode.removeChild(el); }, (dur + 1) * 1000));
    }
    function spawnSparkle() {
        var el = document.createElement('div');
        el.className = 'golden-sparkle';
        el.textContent = sparkles[Math.floor(Math.random() * sparkles.length)];
        var x   = 10 + Math.random() * 170;
        var dur = 3 + Math.random() * 3;
        el.style.cssText = 'position:absolute;bottom:0;left:' + x + 'px;animation:sparkleFloat ' + dur + 's ease-out forwards;';
        c.appendChild(el);
        _animTimeouts.push(setTimeout(function() { if (el.parentNode) el.parentNode.removeChild(el); }, (dur + 1) * 1000));
    }
    spawnParticle(); spawnParticle(); spawnSparkle();
    _animIntervals.push(setInterval(spawnParticle, 600));
    _animIntervals.push(setInterval(spawnSparkle, 2000));
}

function _anim_basketball() {
    var c = _makeContainer(false);
    if (!c) return;
    var ball = document.createElement('div');
    ball.className = 'basketball-ball';
    ball.textContent = '🏀';
    ball.style.cssText = 'position:absolute;bottom:20px;left:80px;animation:ballBounce 1.4s ease-in-out infinite;';
    c.appendChild(ball);
    var shadow = document.createElement('div');
    shadow.className = 'basketball-shadow';
    shadow.style.cssText = 'position:absolute;bottom:18px;left:78px;width:32px;height:10px;animation:ballShadow 1.4s ease-in-out infinite;';
    c.appendChild(shadow);
}

// =========================================================
// BLOQUER / DÉBLOQUER
// =========================================================
function showBlockModal()  { var m = document.getElementById('blockModal');  if (m) m.style.display = 'flex'; }
function closeBlockModal() { var m = document.getElementById('blockModal');  if (m) m.style.display = 'none'; }

function blockContact() {
    var hdr = document.querySelector('.chat-header');
    var id  = hdr ? hdr.getAttribute('data-contact-id') : null;
    if (!id || id === '0') { alert('Erreur : aucun contact sélectionné'); return; }
    _submitForm('blockUser', { contactId: id, action: 'block' });
}
function unblockContact() {
    var hdr = document.querySelector('.chat-header');
    var id  = hdr ? hdr.getAttribute('data-contact-id') : null;
    if (!id || id === '0') { alert('Erreur : aucun contact sélectionné'); return; }
    _submitForm('blockUser', { contactId: id, action: 'unblock' });
}
function deleteConversation() {
    if (confirm('Supprimer cette conversation ?')) window.location.href = 'chat.jsp';
}

// =========================================================
// TRANSFERT
// =========================================================
var _forwardMessageId = null;
function showForwardModal(messageId, content) {
    _forwardMessageId = messageId;
    var m = document.getElementById('forwardModal');
    var p = document.getElementById('forwardMessagePreview');
    if (m && p) { p.innerHTML = content.replace(/\n/g, '<br>'); m.style.display = 'flex'; }
}
function closeForwardModal() { var m = document.getElementById('forwardModal'); if (m) m.style.display = 'none'; _forwardMessageId = null; }
function submitForward() {
    var sel = document.getElementById('forwardContactSelect');
    if (!sel || !sel.value) { alert('Veuillez sélectionner un destinataire'); return; }
    _submitForm('forwardMessage', { messageId: _forwardMessageId, receiverId: sel.value });
}

// =========================================================
// SUPPRESSION
// =========================================================
function toggleDeleteMenu(element) {
    document.querySelectorAll('.delete-menu').forEach(function(m) {
        if (m !== element.nextElementSibling) m.style.display = 'none';
    });
    var menu = element.nextElementSibling;
    if (menu) menu.style.display = menu.style.display === 'block' ? 'none' : 'block';
    return false;
}
function deleteMessage(messageId, receiverId, type) {
    _submitForm('advancedDelete', { messageId: messageId, receiverId: receiverId, type: type });
}
document.addEventListener('click', function(e) {
    if (!(e.target.closest && e.target.closest('.delete-menu-wrapper'))) {
        document.querySelectorAll('.delete-menu').forEach(function(m) { m.style.display = 'none'; });
    }
});

// =========================================================
// LOADING
// =========================================================
function showLoading() { var l = document.getElementById('loadingIndicator'); if (l) l.style.display = 'flex'; }
function hideLoading() { var l = document.getElementById('loadingIndicator'); if (l) l.style.display = 'none'; }

// =========================================================
// IMAGE PLEIN ÉCRAN
// =========================================================
function openImageModal(src) {
    var overlay = document.createElement('div');
    Object.assign(overlay.style, { position:'fixed', inset:'0', background:'rgba(0,0,0,.9)', zIndex:'2000', display:'flex', alignItems:'center', justifyContent:'center', cursor:'zoom-out' });
    var img = document.createElement('img');
    img.src = src;
    Object.assign(img.style, { maxWidth:'90%', maxHeight:'90%', borderRadius:'12px', boxShadow:'0 20px 60px rgba(0,0,0,.6)' });
    overlay.appendChild(img);
    overlay.onclick = function() { document.body.removeChild(overlay); };
    document.body.appendChild(overlay);
}

// =========================================================
// EMOJI PICKER
// =========================================================
var EMOJI_DATA = {
    smileys:  { label:'😀 Smileys',    icon:'😀', emojis:['😀','😃','😄','😁','😆','😅','🤣','😂','🙂','🙃','😉','😊','😇','🥰','😍','🤩','😘','😗','☺️','😚','😙','🥲','😋','😛','😜','🤪','😝','🤑','🤗','🤭','🤫','🤔','🤐','🤨','😐','😑','😶','😏','😒','🙄','😬','🤥','😌','😔','😪','🤤','😴','😷','🤒','🤕','🤢','🤮','🤧','🥵','🥶','🥴','😵','🤯','🤠','🥳','🥸','😎','🤓','🧐','😕','😟','🙁','☹️','😮','😯','😲','😳','🥺','😦','😧','😨','😰','😥','😢','😭','😱','😖','😣','😞','😓','😩','😫','🥱','😤','😡','😠','🤬','😈','👿','💀','☠️','💩','🤡','👹','👺'] },
    gestures: { label:'👋 Gestes',      icon:'👋', emojis:['👋','🤚','🖐️','✋','🖖','👌','🤌','🤏','✌️','🤞','🤟','🤘','🤙','👈','👉','👆','🖕','👇','☝️','👍','👎','✊','👊','🤛','🤜','👏','🙌','👐','🤲','🤝','🙏','✍️','💅','🤳','💪','🦾'] },
    hearts:   { label:'❤️ Cœurs',       icon:'❤️', emojis:['❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','❤️‍🔥','❤️‍🩹','💕','💞','💓','💗','💖','💘','💝','💟','☮️','💯','💢','💥','💫','💦','💨','🕳️','💬','💭','💤'] },
    nature:   { label:'🌿 Nature',       icon:'🌿', emojis:['🌸','🌺','🌻','🌹','🌷','🌼','💐','🍀','🌿','🍃','🍂','🍁','🌾','🌵','🌴','🌳','🌲','🎋','🎍','🍄','🌰','🦔','🦁','🐯','🐻','🐼','🦊','🐱','🐶','🦄','🦋','🐝','🐞','🦟','🐬','🦈','🐳','🐧','🦅','🦜'] },
    food:     { label:'🍕 Nourriture',   icon:'🍕', emojis:['🍕','🍔','🌮','🌯','🥙','🥚','🍳','🥘','🍲','🥗','🍿','🥞','🍖','🍗','🌭','🥪','🧀','🍣','🍱','🍜','🍛','🍝','🍦','🍩','🍪','🎂','🍰','🧁','🍫','🍬','🍭','🍵','☕','🧃','🥤','🧋','🍺','🍻','🥂','🍷'] },
    travel:   { label:'✈️ Voyages',      icon:'✈️', emojis:['✈️','🚀','🛸','🚁','🚗','🚕','🚙','🚌','🏎️','🚓','🚑','🚒','🛻','🚂','🚆','🚇','⛵','🚢','🚤','🗺️','🗼','🗽','🗿','🏰','🏯','🏟️','🎡','🎢','⛲','🏖️','🏝️','🌋','🏔️','⛺','🌅','🌄','🌠','🎇','🎆'] },
    objects:  { label:'💡 Objets',       icon:'💡', emojis:['💡','🔦','🕯️','💰','💳','💎','⚖️','🔧','🔨','⚙️','🔩','🧲','🧺','🚿','🛁','🧴','🧹','🧼','🧸','🎭','🎨','🖼️','🎤','🎧','🎷','🎸','🎹','🎺','🎻','🥁','🎲','♟️','🎯','🎳','🎮','🕹️','📱','💻','🖥️','📷','📹','📺'] },
    symbols:  { label:'✨ Symboles',     icon:'✨', emojis:['✨','⭐','🌟','💫','⚡','🔥','🌈','☀️','🌙','❄️','💧','🌊','🎵','🎶','🔔','📣','📢','💬','💭','📌','📍','🏷️','✅','❎','⛔','🚫','❌','⭕','🔴','🟠','🟡','🟢','🔵','🟣','⚫','⚪','🟤','♻️','⚜️'] }
};

var _emojiPickerOpen = false;
var _recentEmojis    = [];
var MAX_RECENTS      = 16;

function _loadRecentEmojis() {
    try { _recentEmojis = JSON.parse(sessionStorage.getItem('qc_recent_emojis') || '[]'); } catch(e) { _recentEmojis = []; }
}
function _saveRecentEmojis() {
    try { sessionStorage.setItem('qc_recent_emojis', JSON.stringify(_recentEmojis)); } catch(e) {}
}
function _addToRecents(emoji) {
    _recentEmojis = _recentEmojis.filter(function(e) { return e !== emoji; });
    _recentEmojis.unshift(emoji);
    if (_recentEmojis.length > MAX_RECENTS) _recentEmojis = _recentEmojis.slice(0, MAX_RECENTS);
    _saveRecentEmojis();
    _renderRecentEmojis();
}
function insertEmoji(emoji) {
    var input = document.querySelector('.message-input-area input[name="content"]') || document.getElementById('messageInput');
    if (!input) return;
    var s = input.selectionStart, e = input.selectionEnd;
    input.value = input.value.slice(0, s) + emoji + input.value.slice(e);
    input.selectionStart = input.selectionEnd = s + emoji.length;
    input.focus();
    _addToRecents(emoji);
}
function _renderRecentEmojis() {
    var el = document.getElementById('emojiRecents');
    if (!el) return;
    if (!_recentEmojis.length) { el.innerHTML = '<span style="font-size:11px;color:var(--text-muted);">Aucun récent</span>'; return; }
    el.innerHTML = _recentEmojis.map(function(e) {
        return '<button class="emoji-btn" onclick="insertEmoji(\'' + e + '\')">' + e + '</button>';
    }).join('');
}
function buildEmojiPicker() {
    var panel = document.getElementById('emojiPickerPanel');
    if (!panel) return;
    var catHtml = '', gridHtml = '';
    var keys = Object.keys(EMOJI_DATA);
    keys.forEach(function(key, idx) {
        var cat = EMOJI_DATA[key];
        catHtml += '<button class="emoji-cat-btn' + (idx===0?' active':'') + '" onclick="switchEmojiCategory(\'' + key + '\',this)" title="' + cat.label + '">' + cat.icon + '</button>';
    });
    keys.forEach(function(key, idx) {
        var cat = EMOJI_DATA[key];
        var emojisHtml = cat.emojis.map(function(e) { return '<button class="emoji-btn" onclick="insertEmoji(\'' + e + '\')">' + e + '</button>'; }).join('');
        gridHtml += '<div class="emoji-category-section" id="cat-' + key + '" style="' + (idx!==0?'display:none':'') + '">'
            + '<span class="emoji-category-label">' + cat.label + '</span>'
            + '<div class="emoji-grid">' + emojisHtml + '</div></div>';
    });
    panel.innerHTML = '<div class="emoji-picker-header"><div class="emoji-search-box"><i class="fas fa-search"></i><input type="text" placeholder="Rechercher…" id="emojiSearchInput" oninput="searchEmojis(this.value)"></div></div>'
        + '<div class="emoji-categories">' + catHtml + '</div>'
        + '<div class="emoji-grid-container" id="emojiGridContainer">'
        + '<div id="emojiSearchResults" style="display:none"><span class="emoji-category-label">Résultats</span><div class="emoji-grid" id="emojiSearchGrid"></div></div>'
        + gridHtml + '</div>'
        + '<div class="emoji-picker-footer"><span class="emoji-footer-label">Récents</span><div class="emoji-recents" id="emojiRecents"></div></div>';
    _renderRecentEmojis();
}
function switchEmojiCategory(key, btn) {
    var si = document.getElementById('emojiSearchInput'); if (si) si.value = '';
    var sr = document.getElementById('emojiSearchResults'); if (sr) sr.style.display = 'none';
    document.querySelectorAll('.emoji-category-section').forEach(function(s) { s.style.display = 'none'; });
    var t = document.getElementById('cat-' + key); if (t) t.style.display = 'block';
    document.querySelectorAll('.emoji-cat-btn').forEach(function(b) { b.classList.remove('active'); });
    if (btn) btn.classList.add('active');
    var gc = document.getElementById('emojiGridContainer'); if (gc) gc.scrollTop = 0;
}
function searchEmojis(term) {
    var sr = document.getElementById('emojiSearchResults'), sg = document.getElementById('emojiSearchGrid');
    document.querySelectorAll('.emoji-category-section').forEach(function(s) { s.style.display = 'none'; });
    if (!term || !term.trim()) {
        if (sr) sr.style.display = 'none';
        var active = document.querySelector('.emoji-cat-btn.active');
        if (active) {
            var idx = Array.from(document.querySelectorAll('.emoji-cat-btn')).indexOf(active);
            var key = Object.keys(EMOJI_DATA)[idx];
            var sec = key ? document.getElementById('cat-' + key) : null;
            if (sec) sec.style.display = 'block';
        }
        return;
    }
    var lower = term.toLowerCase(), results = [];
    Object.keys(EMOJI_DATA).forEach(function(k) {
        if (EMOJI_DATA[k].label.toLowerCase().indexOf(lower) !== -1)
            results = results.concat(EMOJI_DATA[k].emojis.slice(0, 20));
    });
    if (sg) sg.innerHTML = !results.length
        ? '<span style="font-size:12px;color:var(--text-muted);">Aucun résultat</span>'
        : results.slice(0, 64).map(function(e) { return '<button class="emoji-btn" onclick="insertEmoji(\'' + e + '\')">' + e + '</button>'; }).join('');
    if (sr) sr.style.display = 'block';
}
function toggleEmojiPicker() {
    var panel = document.getElementById('emojiPickerPanel'), btn = document.getElementById('emojiTriggerBtn');
    if (!panel) return;
    _emojiPickerOpen = !_emojiPickerOpen;
    if (_emojiPickerOpen) {
        panel.classList.add('open'); if (btn) btn.classList.add('active');
        _renderRecentEmojis();
        setTimeout(function() { var si = document.getElementById('emojiSearchInput'); if (si) si.focus(); }, 120);
    } else { closeEmojiPicker(); }
}
function closeEmojiPicker() {
    var panel = document.getElementById('emojiPickerPanel'), btn = document.getElementById('emojiTriggerBtn');
    if (panel) panel.classList.remove('open'); if (btn) btn.classList.remove('active');
    _emojiPickerOpen = false;
}

// =========================================================
// MODE SOMBRE / CLAIR
// =========================================================
function initDarkMode() {
    var saved = localStorage.getItem('darkMode');
    var prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    var isDark = saved === 'dark' || (saved === null && prefersDark);
    document.body.classList.toggle('dark',  isDark);
    document.body.classList.toggle('light', !isDark);
    var icon = document.getElementById('themeToggle');
    if (icon) icon.className = isDark ? 'fas fa-sun' : 'fas fa-moon';
}
function toggleDarkMode() {
    var isDark = document.body.classList.toggle('dark');
    document.body.classList.toggle('light', !isDark);
    localStorage.setItem('darkMode', isDark ? 'dark' : 'light');
    var icon = document.getElementById('themeToggle');
    if (icon) icon.className = isDark ? 'fas fa-sun' : 'fas fa-moon';
}

// =========================================================
// GIF PICKER
// =========================================================
var gifPickerOpen = false;
var gifApiKey = 'tQcwxW98yKeti6Wq5b5Zc2WEHtPeoequ';

function getCurrentContactId() {
    var hdr = document.querySelector('.chat-header');
    return hdr ? hdr.getAttribute('data-contact-id') : '';
}
function toggleGifPicker() {
    var panel = document.getElementById('gifPickerPanel'), btn = document.getElementById('gifTriggerBtn');
    if (!panel) return;
    gifPickerOpen = !gifPickerOpen;
    if (gifPickerOpen) { panel.style.display = 'block'; if (btn) btn.classList.add('active'); loadTrendingGifs(); }
    else { panel.style.display = 'none'; if (btn) btn.classList.remove('active'); }
}
function loadTrendingGifs() {
    var div = document.getElementById('gifResults');
    if (!div) return;
    div.innerHTML = '<div style="text-align:center;padding:20px"><i class="fas fa-spinner fa-spin"></i> Chargement…</div>';
    fetch('https://api.giphy.com/v1/gifs/trending?api_key=' + gifApiKey + '&limit=20&rating=g')
        .then(function(r){ return r.json(); })
        .then(function(d){ d.data && d.data.length ? displayGifs(d.data) : (div.innerHTML = '<div style="text-align:center;padding:20px;color:var(--text-muted)">Aucun GIF</div>'); })
        .catch(function(){ div.innerHTML = '<div style="text-align:center;padding:20px;color:var(--text-muted)">⚠️ Erreur de chargement</div>'; });
}
function searchGifs() {
    var si = document.getElementById('gifSearchInput'), div = document.getElementById('gifResults');
    var kw = si ? si.value.trim() : '';
    if (!kw) { loadTrendingGifs(); return; }
    div.innerHTML = '<div style="text-align:center;padding:20px"><i class="fas fa-spinner fa-spin"></i> Recherche…</div>';
    fetch('https://api.giphy.com/v1/gifs/search?api_key=' + gifApiKey + '&q=' + encodeURIComponent(kw) + '&limit=20&rating=g')
        .then(function(r){ return r.json(); })
        .then(function(d){ d.data && d.data.length ? displayGifs(d.data) : (div.innerHTML = '<div style="text-align:center;padding:20px;color:var(--text-muted)">Aucun GIF pour "' + kw + '"</div>'); })
        .catch(function(){ div.innerHTML = '<div style="text-align:center;padding:20px;color:var(--text-muted)">Erreur de recherche</div>'; });
}
function displayGifs(gifs) {
    var div = document.getElementById('gifResults');
    if (!div) return;
    div.innerHTML = gifs.map(function(g) {
        var url = g.images.fixed_height_small.url;
        return '<div class="gif-result-item" onclick="sendGif(\'' + url.replace(/'/g, "\\'") + '\')">'
            + '<img src="' + url + '" alt="GIF" loading="lazy"></div>';
    }).join('');
}
function sendGif(gifUrl) {
    var rid = getCurrentContactId();
    if (!rid) { alert('Erreur : destinataire non trouvé'); return; }
    _submitForm('sendMessage', { receiverId: rid, content: '[GIF]', gifUrl: gifUrl });
}

// =========================================================
// HELPER POST FORM
// =========================================================
function _submitForm(action, data) {
    var form = document.createElement('form');
    form.method = 'POST'; form.action = action;
    Object.keys(data).forEach(function(k) {
        var i = document.createElement('input');
        i.type = 'hidden'; i.name = k; i.value = data[k];
        form.appendChild(i);
    });
    document.body.appendChild(form);
    form.submit();
}

// =========================================================
// ARCHIVER / DÉSARCHIVER UNE CONVERSATION
// =========================================================
function archiveConversation() {
    var hdr = document.querySelector('.chat-header');
    var contactId = hdr ? hdr.getAttribute('data-contact-id') : null;
    if (!contactId) return;
    if (confirm("Archiver cette conversation ? Elle sera déplacée dans la section 'Archivées'.")) {
        var form = document.createElement('form');
        form.method = 'POST';
        form.action = 'archiveConversation';
        var input = document.createElement('input');
        input.type = 'hidden'; input.name = 'contactId'; input.value = contactId;
        form.appendChild(input);
        var archivedInput = document.createElement('input');
        archivedInput.type = 'hidden'; archivedInput.name = 'archived'; archivedInput.value = 'true';
        form.appendChild(archivedInput);
        document.body.appendChild(form);
        form.submit();
    }
}

function unarchiveConversation(contactId) {
    var form = document.createElement('form');
    form.method = 'POST';
    form.action = 'archiveConversation';
    var input = document.createElement('input');
    input.type = 'hidden'; input.name = 'contactId'; input.value = contactId;
    form.appendChild(input);
    var archivedInput = document.createElement('input');
    archivedInput.type = 'hidden'; archivedInput.name = 'archived'; archivedInput.value = 'false';
    form.appendChild(archivedInput);
    document.body.appendChild(form);
    form.submit();
}

// =========================================================
// SUPPRIMER UNE CONVERSATION
// =========================================================
function showDeleteConvModal() {
    var m = document.getElementById('deleteConversationModal');
    if (m) m.style.display = 'flex';
}

function closeDeleteConvModal() {
    var m = document.getElementById('deleteConversationModal');
    if (m) m.style.display = 'none';
}

function confirmDeleteConversation() {
    var hdr = document.querySelector('.chat-header');
    var contactId = hdr ? hdr.getAttribute('data-contact-id') : null;
    if (!contactId) return;
    var form = document.createElement('form');
    form.method = 'POST';
    form.action = 'deleteConversation';
    var input = document.createElement('input');
    input.type = 'hidden'; input.name = 'contactId'; input.value = contactId;
    form.appendChild(input);
    document.body.appendChild(form);
    form.submit();
}

// =========================================================
// DOM READY
// =========================================================
document.addEventListener('DOMContentLoaded', function() {
    hideLoading();
    initDarkMode();
    scrollToBottom();
    _loadRecentEmojis();
    buildEmojiPicker();
    initThemeAnimations(_getCurrentConversationTheme());

    var themeToggleBtn = document.getElementById('themeToggle');
    if (themeToggleBtn) themeToggleBtn.addEventListener('click', function(e) { e.stopPropagation(); toggleDarkMode(); });

    var emojiBtn = document.getElementById('emojiTriggerBtn');
    if (emojiBtn) emojiBtn.addEventListener('click', function(e) { e.stopPropagation(); toggleEmojiPicker(); });

    var gifBtn = document.getElementById('gifTriggerBtn');
    if (gifBtn) gifBtn.addEventListener('click', function(e) { e.stopPropagation(); toggleGifPicker(); });

    var searchGifBtn = document.getElementById('searchGifBtn');
    if (searchGifBtn) searchGifBtn.addEventListener('click', searchGifs);
    var gifSearchInput = document.getElementById('gifSearchInput');
    if (gifSearchInput) gifSearchInput.addEventListener('keypress', function(e) { if (e.key === 'Enter') { e.preventDefault(); searchGifs(); } });

    document.addEventListener('click', function(e) {
        var ew = document.querySelector('.emoji-picker-wrapper');
        if (ew && !ew.contains(e.target)) closeEmojiPicker();
        var gw = document.querySelector('.gif-picker-wrapper');
        if (gw && !gw.contains(e.target) && gifPickerOpen) {
            var gp = document.getElementById('gifPickerPanel');
            if (gp) gp.style.display = 'none';
            gifPickerOpen = false;
            var gb = document.getElementById('gifTriggerBtn');
            if (gb) gb.classList.remove('active');
        }
        var pm = document.getElementById('profileMenu');
        var pic = document.querySelector('.profile-pic');
        if (pm && pic && !pic.contains(e.target) && !pm.contains(e.target)) pm.style.display = 'none';
    });

    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') { closeEmojiPicker(); closeSearch(); }
    });

    var sideSearch = document.getElementById('searchInput');
    if (sideSearch) {
        sideSearch.addEventListener('keyup', function() {
            var v = this.value.toLowerCase();
            document.querySelectorAll('.contact-item').forEach(function(c) {
                var n = c.getAttribute('data-name') || '';
                c.style.display = n.indexOf(v) !== -1 ? 'flex' : 'none';
            });
        });
    }

    var searchIcon = document.getElementById('searchIcon');
    if (searchIcon) searchIcon.addEventListener('click', toggleSearchBar);
    var closeSearchBtn = document.getElementById('closeSearch');
    if (closeSearchBtn) closeSearchBtn.addEventListener('click', closeSearch);
    var searchChat = document.getElementById('searchInputChat');
    if (searchChat) {
        searchChat.addEventListener('keyup', function(e) {
            searchInConversation();
            if (e.key === 'Enter' && searchMessages.length) nextResult();
        });
    }
    var prevBtn = document.getElementById('prevResult');
    if (prevBtn) prevBtn.addEventListener('click', prevResult);
    var nextBtn = document.getElementById('nextResult');
    if (nextBtn) nextBtn.addEventListener('click', nextResult);

    var msgInput = document.querySelector('.message-input-area input[name="content"]') || document.getElementById('messageInput');
    if (msgInput) {
        msgInput.addEventListener('keydown', function(e) {
            if (e.key === 'Enter' && !e.shiftKey) {
                var f = this.closest('form');
                if (f) { e.preventDefault(); f.submit(); }
            }
        });
    }

    var photoInput = document.getElementById('photoInput');
    if (photoInput) {
        photoInput.addEventListener('change', function(e) {
            var file = e.target.files[0];
            if (!file) return;
            var rid = document.querySelector('input[name="receiverId"]');
            var cap = document.getElementById('messageInput');
            var prId = document.getElementById('photoReceiverId');
            var pcap = document.getElementById('photoCaption');
            var pfi = document.getElementById('photoFileInput');
            var pf = document.getElementById('photoUploadForm');
            if (!rid || !prId || !pfi || !pf) return;
            prId.value = rid.value;
            if (pcap && cap) pcap.value = cap.value;
            try { var dt = new DataTransfer(); dt.items.add(file); pfi.files = dt.files; } catch(ex) {}
            showLoading();
            pf.submit();
        });
    }

    document.addEventListener('submit', function(e) {
        if (e.target.id === 'messageForm' || e.target.id === 'photoUploadForm') showLoading();
    });
});
// ========== GESTION DES ARCHIVES ==========
let archivesOpen = false;

document.addEventListener('DOMContentLoaded', function() {
    const archiveBtn = document.getElementById('archivedToggleBtn');
    const archivedContainer = document.getElementById('archivedContainer');
    
    if (archiveBtn) {
        archiveBtn.addEventListener('click', function() {
            if (!archivesOpen) {
                loadArchivedConversations();
                archivedContainer.style.display = 'block';
                archivesOpen = true;
                archiveBtn.style.background = 'var(--violet)';
                archiveBtn.style.color = 'white';
            } else {
                archivedContainer.style.display = 'none';
                archivesOpen = false;
                archiveBtn.style.background = 'var(--bg-input-msg)';
                archiveBtn.style.color = 'var(--text-primary)';
            }
        });
    }
});

function loadArchivedConversations() {
    const archivedList = document.getElementById('archivedList');
    if (!archivedList) return;
    
    archivedList.innerHTML = '<div style="font-size: 12px; color: var(--text-muted); padding: 8px 0; text-align: center;"><i class="fas fa-spinner fa-spin"></i> Chargement...</div>';
    
    fetch('getArchivedConversations')
        .then(response => response.json())
        .then(data => {
            const badge = document.getElementById('archivedBadge');
            if (badge) {
                if (data.length > 0) {
                    badge.style.display = 'inline-block';
                    badge.textContent = data.length;
                } else {
                    badge.style.display = 'none';
                }
            }
            
            if (data.length === 0) {
                archivedList.innerHTML = '<div style="font-size: 12px; color: var(--text-muted); padding: 8px 0; text-align: center;">📭 Aucune conversation archivée</div>';
                return;
            }
            
            let html = '';
            for (let i = 0; i < data.length; i++) {
                const item = data[i];
                if (item.type === 'group') {
                    html += `
                        <a href="${item.link}" class="archived-contact" style="display: flex; align-items: center; gap: 12px; padding: 10px 0; text-decoration: none; color: var(--text-primary); border-bottom: 1px solid var(--border);">
                            <div style="width: 40px; height: 40px; border-radius: 50%; background: var(--grad-brand); display: flex; align-items: center; justify-content: center; color: white;">
                                <i class="fas fa-users"></i>
                            </div>
                            <div style="flex: 1;">
                                <div style="font-weight: 500;">
                                    <i class="fas fa-users" style="font-size: 12px; margin-right: 5px; color: var(--text-muted);"></i>
                                    ${item.name}
                                </div>
                                <div style="font-size: 11px; color: var(--text-muted);">Groupe archivé</div>
                            </div>
                            <i class="fas fa-archive" style="color: var(--text-muted); font-size: 12px;"></i>
                        </a>
                    `;
                } else {
                    html += `
                        <a href="${item.link}" class="archived-contact" style="display: flex; align-items: center; gap: 12px; padding: 10px 0; text-decoration: none; color: var(--text-primary); border-bottom: 1px solid var(--border);">
                            <div style="width: 40px; height: 40px; border-radius: 50%; background: var(--grad-brand); display: flex; align-items: center; justify-content: center; color: white; font-weight: bold;">
                                ${item.name ? item.name.charAt(0).toUpperCase() : '?'}
                            </div>
                            <div style="flex: 1;">
                                <div style="font-weight: 500;">${item.name}</div>
                                <div style="font-size: 11px; color: var(--text-muted);">Conversation archivée</div>
                            </div>
                            <i class="fas fa-user" style="color: var(--text-muted); font-size: 12px;"></i>
                        </a>
                    `;
                }
            }
            archivedList.innerHTML = html;
        })
        .catch(error => {
            console.error('Erreur:', error);
            archivedList.innerHTML = '<div style="font-size: 12px; color: red; padding: 8px 0; text-align: center;">❌ Erreur de chargement</div>';
        });
}

// ========== MODALE CRÉER UN GROUPE ==========
function openCreateGroupModal() {
    var modal = document.getElementById('createGroupModal');
    if (modal) {
        modal.style.display = 'flex';
    }
}

function closeCreateGroupModal() {
    var modal = document.getElementById('createGroupModal');
    if (modal) {
        modal.style.display = 'none';
    }
}

// Fermer la modale en cliquant en dehors
document.addEventListener('click', function(e) {
    var modal = document.getElementById('createGroupModal');
    if (modal && modal.style.display === 'flex') {
        var modalContent = modal.querySelector('div');
        if (modalContent && !modalContent.contains(e.target)) {
            closeCreateGroupModal();
        }
    }
});

// Empêcher la propagation du clic à l'intérieur de la modale
var createGroupModalElement = document.getElementById('createGroupModal');
if (createGroupModalElement) {
    createGroupModalElement.addEventListener('click', function(e) {
        e.stopPropagation();
    });
}
