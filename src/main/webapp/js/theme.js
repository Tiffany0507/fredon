// Ajout des animations pour les nouveaux thèmes
function initThemeAnimations(theme) {
    // Supprimer les éléments d'animation existants
    document.querySelectorAll('.leaf, .cloud, .galaxy, .aurora, .umbrella, .floating-heart, .cherry-blossom, .star, .gold-particle, .lavender-flower, .shooting-star, .wave, .sand, .tree-silhouette, .moon').forEach(el => el.remove());
    
    // Supprimer le conteneur d'animations s'il existe
    const oldContainer = document.querySelector('.animation-container');
    if (oldContainer) oldContainer.remove();
    
    // Créer un conteneur pour les animations
    const animationContainer = document.createElement('div');
    animationContainer.className = 'animation-container';
    const chatArea = document.querySelector('.chat-area');
    if (chatArea) {
        chatArea.appendChild(animationContainer);
    }
    
    if (theme === 'forest-premium') {
        // Ajouter une silhouette d'arbre
        const treeSilhouette = document.createElement('div');
        treeSilhouette.className = 'tree-silhouette';
        animationContainer.appendChild(treeSilhouette);
        
        // Ajouter des feuilles qui tombent
        for (let i = 0; i < 25; i++) {
            const leaf = document.createElement('div');
            leaf.className = 'leaf';
            leaf.style.left = Math.random() * 100 + '%';
            leaf.style.animationDelay = Math.random() * 10 + 's';
            leaf.style.animationDuration = 6 + Math.random() * 5 + 's';
            leaf.style.width = (15 + Math.random() * 15) + 'px';
            leaf.style.height = (15 + Math.random() * 15) + 'px';
            animationContainer.appendChild(leaf);
        }
    }
    
    if (theme === 'sunset-premium') {
        // Ajouter des nuages améliorés
        for (let i = 0; i < 5; i++) {
            const cloud = document.createElement('div');
            cloud.className = 'cloud';
            cloud.style.width = (120 + Math.random() * 150) + 'px';
            cloud.style.height = (50 + Math.random() * 40) + 'px';
            cloud.style.top = (10 + Math.random() * 150) + 'px';
            cloud.style.left = (Math.random() * 100) + '%';
            cloud.style.animationDelay = (i * 3) + 's';
            cloud.style.animationDuration = 20 + Math.random() * 15 + 's';
            animationContainer.appendChild(cloud);
        }
    }
    
    if (theme === 'aurora-premium') {
        // Ajouter l'aurora
        const aurora = document.createElement('div');
        aurora.className = 'aurora';
        animationContainer.appendChild(aurora);
    }
    
    if (theme === 'cosmic') {
        // Ajouter la galaxie
        const galaxy = document.createElement('div');
        galaxy.className = 'galaxy';
        animationContainer.appendChild(galaxy);
        
        // Ajouter des étoiles filantes
        for (let i = 0; i < 3; i++) {
            setTimeout(() => {
                const star = document.createElement('div');
                star.className = 'shooting-star';
                star.style.top = Math.random() * 100 + '%';
                star.style.left = Math.random() * 100 + '%';
                star.style.animationDelay = Math.random() * 5 + 's';
                animationContainer.appendChild(star);
                
                setTimeout(() => star.remove(), 3000);
            }, i * 2000);
        }
    }
    
    if (theme === 'beach') {
        // Ajouter le sable
        const sand = document.createElement('div');
        sand.className = 'sand';
        animationContainer.appendChild(sand);
        
        // Ajouter les vagues
        const wave = document.createElement('div');
        wave.className = 'wave';
        animationContainer.appendChild(wave);
        
        // Ajouter le parasol
        const umbrella = document.createElement('div');
        umbrella.className = 'umbrella';
        umbrella.innerHTML = '🏖️';
        animationContainer.appendChild(umbrella);
    }
    
    if (theme === 'rose') {
        // Ajouter des cœurs flottants pour le thème amour
        for (let i = 0; i < 20; i++) {
            const heart = document.createElement('div');
            heart.className = 'floating-heart';
            heart.innerHTML = ['❤️', '💖', '💗', '💓', '💕'][Math.floor(Math.random() * 5)];
            heart.style.left = Math.random() * 100 + '%';
            heart.style.animationDelay = Math.random() * 10 + 's';
            heart.style.animationDuration = 5 + Math.random() * 5 + 's';
            heart.style.fontSize = (20 + Math.random() * 30) + 'px';
            animationContainer.appendChild(heart);
        }
    }
    
    if (theme === 'midnight-premium') {
        // Ajouter la lune
        const moon = document.createElement('div');
        moon.className = 'moon';
        moon.innerHTML = '🌙';
        animationContainer.appendChild(moon);
        
        // Ajouter des étoiles scintillantes
        for (let i = 0; i < 100; i++) {
            const star = document.createElement('div');
            star.className = 'star';
            star.style.left = Math.random() * 100 + '%';
            star.style.top = Math.random() * 80 + '%';
            star.style.width = (1 + Math.random() * 3) + 'px';
            star.style.height = (1 + Math.random() * 3) + 'px';
            star.style.animationDelay = Math.random() * 3 + 's';
            star.style.animationDuration = 1 + Math.random() * 2 + 's';
            animationContainer.appendChild(star);
        }
    }
    
    if (theme === 'cherry') {
        // Ajouter des fleurs de cerisier
        for (let i = 0; i < 40; i++) {
            const blossom = document.createElement('div');
            blossom.className = 'cherry-blossom';
            blossom.innerHTML = ['🌸', '🌸', '🌸', '🌸', '🌸', '💮'][Math.floor(Math.random() * 6)];
            blossom.style.left = Math.random() * 100 + '%';
            blossom.style.animationDelay = Math.random() * 15 + 's';
            blossom.style.animationDuration = 8 + Math.random() * 7 + 's';
            blossom.style.fontSize = (15 + Math.random() * 20) + 'px';
            animationContainer.appendChild(blossom);
        }
    }
    
    if (theme === 'golden') {
        // Ajouter des particules dorées
        for (let i = 0; i < 50; i++) {
            const particle = document.createElement('div');
            particle.className = 'gold-particle';
            particle.style.left = Math.random() * 100 + '%';
            particle.style.animationDelay = Math.random() * 10 + 's';
            particle.style.animationDuration = 3 + Math.random() * 4 + 's';
            animationContainer.appendChild(particle);
        }
    }
    
    if (theme === 'lavender') {
        // Ajouter des fleurs de lavande
        for (let i = 0; i < 30; i++) {
            const lavender = document.createElement('div');
            lavender.className = 'lavender-flower';
            lavender.innerHTML = ['🌸', '🌿', '🌸', '🌿', '💜'][Math.floor(Math.random() * 5)];
            lavender.style.left = Math.random() * 100 + '%';
            lavender.style.animationDelay = Math.random() * 15 + 's';
            lavender.style.animationDuration = 10 + Math.random() * 8 + 's';
            lavender.style.fontSize = (18 + Math.random() * 22) + 'px';
            animationContainer.appendChild(lavender);
        }
    }
}

// Récupérer l'ID du contact actuel
function getCurrentContactId() {
    // Récupérer depuis l'URL
    var urlParams = new URLSearchParams(window.location.search);
    var contactId = urlParams.get('userId');
    
    if (!contactId) {
        // Essayer de récupérer depuis le chat-header
        var header = document.querySelector('.chat-header');
        if (header) {
            contactId = header.getAttribute('data-contact-id');
        }
    }
    
    console.log("DEBUG - Contact ID: " + contactId);
    return contactId;
}

// Appeler initThemeAnimations après l'application du thème
function applyTheme(theme) {
    console.log("DEBUG - Application du thème: " + theme);
    
    // Changer la classe du body
    document.body.className = 'theme-' + theme;
    
    // Initialiser les animations spécifiques
    setTimeout(function() {
        initThemeAnimations(theme);
    }, 100);
    
    // Sauvegarder le thème pour la conversation
    var contactId = getCurrentContactId();
    
    if (contactId) {
        console.log("DEBUG - Sauvegarde du thème pour contact: " + contactId);
        
        // Utiliser le bon nom de servlet : updateTheme (pas updateConversationTheme)
        fetch('updateTheme', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: 'contactId=' + contactId + '&theme=' + theme
        })
        .then(response => {
            console.log("DEBUG - Réponse serveur: " + response.status);
            if (response.ok) {
                console.log("DEBUG - Thème sauvegardé avec succès");
                closeThemeModal();
                // Recharger la page pour appliquer complètement le thème
                setTimeout(function() {
                    window.location.reload();
                }, 500);
            } else {
                console.log("DEBUG - Erreur lors de la sauvegarde");
            }
        })
        .catch(error => {
            console.log("DEBUG - Erreur réseau: " + error);
        });
    } else {
        console.log("DEBUG - Pas de contact ID trouvé");
        closeThemeModal();
    }
}

// Fonction pour sélectionner un thème (appelée depuis le modal)
function selectTheme(theme) {
    console.log("DEBUG - Thème sélectionné: " + theme);
    
    // Mettre à jour l'aperçu visuel
    document.querySelectorAll('.theme-preview-card').forEach(card => {
        if (card.getAttribute('data-theme') === theme) {
            card.classList.add('active');
        } else {
            card.classList.remove('active');
        }
    });
    
    // Stocker le thème temporairement
    window.selectedTheme = theme;
}

// Fonction pour fermer le modal
function closeThemeModal() {
    var modal = document.getElementById('themeModal');
    if (modal) {
        modal.style.display = 'none';
    }
}

// Fonction pour ouvrir le modal
function showThemeModal() {
    var modal = document.getElementById('themeModal');
    if (modal) {
        modal.style.display = 'flex';
        
        // Récupérer le thème actuel
        var currentTheme = document.body.className.replace('theme-', '');
        
        // Mettre en surbrillance le thème actif
        document.querySelectorAll('.theme-preview-card').forEach(card => {
            if (card.getAttribute('data-theme') === currentTheme) {
                card.classList.add('active');
            } else {
                card.classList.remove('active');
            }
        });
    }
}

// Fonction pour appliquer un thème sans recharger la page (pour l'aperçu)
function previewTheme(theme) {
    console.log("DEBUG - Aperçu du thème: " + theme);
    
    // Changer temporairement la classe du body pour l'aperçu
    document.body.className = 'theme-' + theme;
    
    // Initialiser les animations d'aperçu
    setTimeout(function() {
        initThemeAnimations(theme);
    }, 100);
    
    // Stocker le thème sélectionné
    window.selectedTheme = theme;
}

// Initialiser au chargement de la page
document.addEventListener('DOMContentLoaded', function() {
    // Récupérer le thème actuel
    var currentTheme = document.body.className.replace('theme-', '');
    console.log("DEBUG - Thème chargé: " + currentTheme);
    
    // Initialiser les animations
    initThemeAnimations(currentTheme);
    
    // Ajouter le listener pour le bouton de thème
    var themeIcon = document.getElementById('themeIcon');
    if (themeIcon) {
        themeIcon.addEventListener('click', showThemeModal);
    }
    
    // Ajouter les listeners pour les options de thème dans le modal
    document.querySelectorAll('.theme-option').forEach(option => {
        option.addEventListener('click', function() {
            const theme = this.getAttribute('data-theme');
            if (theme) {
                previewTheme(theme);
            }
        });
    });
    
    // Ajouter le listener pour le bouton d'application
    const applyButton = document.getElementById('applyTheme');
    if (applyButton) {
        applyButton.addEventListener('click', function() {
            if (window.selectedTheme) {
                applyTheme(window.selectedTheme);
            }
        });
    }
    
    // Ajouter le listener pour le bouton d'annulation
    const cancelButton = document.getElementById('cancelTheme');
    if (cancelButton) {
        cancelButton.addEventListener('click', closeThemeModal);
    }
});
// Appliquer un thème de conversation (sans écraser le mode sombre)
function applyConversationTheme(theme) {
    console.log("DEBUG - Application du thème de conversation: " + theme);
    
    // Sauvegarder le mode actuel (light ou dark)
    const isDarkMode = document.body.classList.contains('dark');
    const isLightMode = document.body.classList.contains('light');
    
    // Supprimer tous les thèmes de conversation existants
    const classes = document.body.className.split(' ');
    for (let cls of classes) {
        if (cls.startsWith('theme-')) {
            document.body.classList.remove(cls);
        }
    }
    
    // Ajouter le nouveau thème de conversation
    document.body.classList.add('theme-' + theme);
    
    // Restaurer le mode sombre/clair
    if (isDarkMode) {
        document.body.classList.add('dark');
        document.body.classList.remove('light');
    } else if (isLightMode) {
        document.body.classList.add('light');
        document.body.classList.remove('dark');
    } else {
        // Par défaut en mode clair
        document.body.classList.add('light');
    }
    
    // Initialiser les animations spécifiques
    setTimeout(function() {
        initThemeAnimations(theme);
    }, 100);
    
    // Sauvegarder le thème pour la conversation
    var contactId = getCurrentContactId();
    
    if (contactId) {
        fetch('updateTheme', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: 'contactId=' + contactId + '&theme=' + theme
        })
        .then(response => {
            if (response.ok) {
                console.log("DEBUG - Thème sauvegardé avec succès");
                closeThemeModal();
            } else {
                console.log("DEBUG - Erreur lors de la sauvegarde");
            }
        })
        .catch(error => {
            console.log("DEBUG - Erreur réseau: " + error);
        });
    } else {
        console.log("DEBUG - Pas de contact ID trouvé");
        closeThemeModal();
    }
}

// Surcharger la fonction applyTheme existante
window.applyTheme = applyConversationTheme;