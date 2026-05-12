<%-- theme.jsp - Gestion du thème --%>
<script>
// Version simplifiée qui ne plante pas
(function() {
    var theme = 'light';
    
    // Essayer de lire le localStorage (si Edge le permet)
    try {
        var saved = localStorage.getItem('fredon_theme');
        if (saved) theme = saved;
    } catch(e) {
        // Si bloqué, on reste sur 'light'
        console.log('localStorage bloqué par le navigateur');
    }
    
    // Appliquer le thème
    if (document.body) {
        if (theme === 'dark') {
            document.body.classList.add('dark-theme', 'dm');
        } else {
            document.body.classList.add('light-theme');
        }
    } else {
        document.addEventListener('DOMContentLoaded', function() {
            if (theme === 'dark') {
                document.body.classList.add('dark-theme', 'dm');
            } else {
                document.body.classList.add('light-theme');
            }
        });
    }
    
    // Fonction pour changer de thème
    window.toggleTheme = function() {
        var isDark = document.body.classList.contains('dark-theme');
        var newTheme = isDark ? 'light' : 'dark';
        
        document.body.classList.remove('light-theme', 'dark-theme', 'dm');
        if (newTheme === 'dark') {
            document.body.classList.add('dark-theme', 'dm');
        } else {
            document.body.classList.add('light-theme');
        }
        
        try {
            localStorage.setItem('fredon_theme', newTheme);
        } catch(e) {}
    };
})();
</script>

<style>
/* Mode sombre */
body.dark-theme, body.dm {
    --bg: #060c1a;
    --bg2: #0d1626;
    --white: #0d1626;
    --dark: #e0e8ff;
    --mid: #6070a0;
    --soft: #2a3555;
}
body.dark-theme, body.dm {
    background: #060c1a;
    color: #e0e8ff;
}
body.dark-theme .form-card,
body.dark-theme .s-card,
body.dark-theme .stat-card {
    background: #0d1626;
}
body.dark-theme .field input,
body.dark-theme .field select,
body.dark-theme .field textarea {
    background: #111e36;
    color: #e0e8ff;
}
body.dark-theme .page-title h1 {
    color: #e0e8ff;
}
body.dark-theme .upload-box {
    background: #111e36;
}
body.dark-theme .breadcrumb,
body.dark-theme .breadcrumb a {
    color: #6070a0;
}
</style>