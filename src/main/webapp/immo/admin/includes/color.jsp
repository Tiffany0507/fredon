<script>
// Forcer la sidebar immédiatement
var savedColor = localStorage.getItem('fredon_primary_color');
if (savedColor) {
    var colorValue = '';
    switch(savedColor) {
        case 'gold': colorValue = '#c8860a'; break;
        case 'blue': colorValue = '#1f52d4'; break;
        case 'green': colorValue = '#10b981'; break;
        case 'purple': colorValue = '#7c3aed'; break;
        case 'rose': colorValue = '#e03060'; break;
        case 'teal': colorValue = '#0e9e8a'; break;
        default: colorValue = '#c8860a';
    }
    var sidebar = document.querySelector('.sidebar');
    if (sidebar) {
        sidebar.style.background = 'linear-gradient(160deg, #0d1f5e 0%, ' + colorValue + ' 45%, #0e2d82 75%, #0a1d58 100%)';
    }
}
</script>