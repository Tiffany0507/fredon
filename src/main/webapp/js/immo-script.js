/**
 * Script pour le module immobilier
 * Gère les interactions utilisateur sur les pages de biens immobiliers
 */

document.addEventListener('DOMContentLoaded', function() {
    
    // ===== INITIALISATION =====
    initFilters();
    initSearchForm();
    initPropertyCards();
    initMobileMenu();
    initSmoothScroll();
    
    console.log('Module immobilier initialisé');
});

// ===== GESTION DES FILTRES =====
function initFilters() {
    const filterSelects = document.querySelectorAll('.filter-select');
    const searchInput = document.querySelector('.search-box input');
    
    filterSelects.forEach(select => {
        select.addEventListener('change', function() {
            applyFilters();
        });
    });
    
    // Appliquer les filtres depuis l'URL au chargement
    applyFiltersFromUrl();
}

function applyFilters() {
    const searchInput = document.querySelector('.search-box input[name="search"]');
    const typeSelect = document.querySelector('.filter-select[name="type"]');
    const priceSelect = document.querySelector('.filter-select[name="price"]');
    const roomsSelect = document.querySelector('.filter-select[name="rooms"]');
    
    const params = new URLSearchParams();
    
    if (searchInput && searchInput.value.trim()) {
        params.set('search', searchInput.value.trim());
    }
    if (typeSelect && typeSelect.value) {
        params.set('type', typeSelect.value);
    }
    if (priceSelect && priceSelect.value) {
        params.set('price', priceSelect.value);
    }
    if (roomsSelect && roomsSelect.value) {
        params.set('rooms', roomsSelect.value);
    }
    
    const url = window.location.pathname + (params.toString() ? '?' + params.toString() : '');
    window.location.href = url;
}

function applyFiltersFromUrl() {
    const params = new URLSearchParams(window.location.search);
    
    const searchInput = document.querySelector('.search-box input[name="search"]');
    const typeSelect = document.querySelector('.filter-select[name="type"]');
    const priceSelect = document.querySelector('.filter-select[name="price"]');
    const roomsSelect = document.querySelector('.filter-select[name="rooms"]');
    
    if (searchInput && params.has('search')) {
        searchInput.value = params.get('search');
    }
    if (typeSelect && params.has('type')) {
        typeSelect.value = params.get('type');
    }
    if (priceSelect && params.has('price')) {
        priceSelect.value = params.get('price');
    }
    if (roomsSelect && params.has('rooms')) {
        roomsSelect.value = params.get('rooms');
    }
}

// ===== GESTION DE LA RECHERCHE =====
function initSearchForm() {
    const searchForm = document.querySelector('.search-box');
    
    if (searchForm) {
        searchForm.addEventListener('submit', function(e) {
            const searchInput = this.querySelector('input[name="search"]');
            if (!searchInput.value.trim()) {
                e.preventDefault();
                searchInput.style.borderColor = '#e74c3c';
                setTimeout(() => {
                    searchInput.style.borderColor = '#e0e0e0';
                }, 2000);
            }
        });
    }
}

// ===== ANIMATION DES CARTES =====
function initPropertyCards() {
    const cards = document.querySelectorAll('.property-card');
    
    cards.forEach((card, index) => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(20px)';
        
        setTimeout(() => {
            card.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
            card.style.opacity = '1';
            card.style.transform = 'translateY(0)';
        }, index * 100);
    });
}

// ===== MENU MOBILE =====
function initMobileMenu() {
    const header = document.querySelector('.header');
    const nav = document.querySelector('.nav');
    
    if (header && nav && window.innerWidth <= 768) {
        if (!document.querySelector('.mobile-menu-toggle')) {
            const toggleBtn = document.createElement('button');
            toggleBtn.className = 'mobile-menu-toggle';
            toggleBtn.innerHTML = '<i class="fas fa-bars"></i>';
            toggleBtn.style.cssText = `
                display: block;
                background: none;
                border: none;
                color: white;
                font-size: 24px;
                cursor: pointer;
            `;
            
            const headerContent = document.querySelector('.header-content');
            headerContent.insertBefore(toggleBtn, nav);
            
            toggleBtn.addEventListener('click', function() {
                nav.classList.toggle('active');
            });
        }
    }
}

// ===== DÉFILEMENT DOUX =====
function initSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            const href = this.getAttribute('href');
            if (href !== '#' && href !== '#contact') {
                const target = document.querySelector(href);
                if (target) {
                    e.preventDefault();
                    target.scrollIntoView({
                        behavior: 'smooth',
                        block: 'start'
                    });
                }
            }
        });
    });
}

// ===== GESTION DES IMAGES (GALERIE) =====
function initGallery() {
    const mainImage = document.querySelector('.main-image img');
    const thumbnails = document.querySelectorAll('.thumbnail');
    
    if (mainImage && thumbnails.length > 0) {
        thumbnails.forEach(thumb => {
            thumb.addEventListener('click', function() {
                const imgSrc = this.querySelector('img').src;
                mainImage.src = imgSrc;
                
                thumbnails.forEach(t => t.classList.remove('active'));
                this.classList.add('active');
            });
        });
    }
}

// ===== GESTION DES RÉACTIONS =====
function initReactions() {
    const reactionBtns = document.querySelectorAll('.reaction-btn');
    
    reactionBtns.forEach(btn => {
        btn.addEventListener('click', function() {
            const propertyId = this.dataset.propertyId;
            const reactionType = this.dataset.reaction;
            
            if (!propertyId || !reactionType) return;
            
            sendReaction(propertyId, reactionType, this);
        });
    });
}

function sendReaction(propertyId, reactionType, button) {
    const formData = new FormData();
    formData.append('propertyId', propertyId);
    formData.append('reactionType', reactionType);
    
    fetch('/quickchat/add-reaction', {
        method: 'POST',
        body: formData
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            updateReactionCounts(data);
            
            // Mettre à jour l'état actif
            document.querySelectorAll('.reaction-btn').forEach(btn => {
                btn.classList.remove('active');
            });
            button.classList.add('active');
        }
    })
    .catch(error => {
        console.error('Erreur:', error);
    });
}

function updateReactionCounts(data) {
    const likeCount = document.querySelector('.reaction-like .reaction-count');
    const loveCount = document.querySelector('.reaction-love .reaction-count');
    const interestedCount = document.querySelector('.reaction-interested .reaction-count');
    
    if (likeCount) likeCount.textContent = data.likes;
    if (loveCount) loveCount.textContent = data.loves;
    if (interestedCount) interestedCount.textContent = data.interested;
}

// ===== GESTION DES COMMENTAIRES =====
function initCommentForm() {
    const commentForm = document.querySelector('.comment-form');
    
    if (commentForm) {
        commentForm.addEventListener('submit', function(e) {
            const nameInput = this.querySelector('input[name="visitorName"]');
            const emailInput = this.querySelector('input[name="visitorEmail"]');
            const contentInput = this.querySelector('textarea[name="content"]');
            
            let isValid = true;
            
            if (!nameInput.value.trim()) {
                showError(nameInput, 'Le nom est requis');
                isValid = false;
            }
            
            if (emailInput.value.trim() && !isValidEmail(emailInput.value.trim())) {
                showError(emailInput, 'Email invalide');
                isValid = false;
            }
            
            if (!contentInput.value.trim()) {
                showError(contentInput, 'Le commentaire ne peut pas être vide');
                isValid = false;
            }
            
            if (!isValid) {
                e.preventDefault();
            }
        });
    }
}

function isValidEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function showError(input, message) {
    input.style.borderColor = '#e74c3c';
    
    const errorSpan = document.createElement('span');
    errorSpan.className = 'error-message';
    errorSpan.style.cssText = `
        color: #e74c3c;
        font-size: 12px;
        margin-top: 5px;
        display: block;
    `;
    errorSpan.textContent = message;
    
    const existingError = input.parentNode.querySelector('.error-message');
    if (existingError) {
        existingError.remove();
    }
    
    input.parentNode.appendChild(errorSpan);
    
    setTimeout(() => {
        input.style.borderColor = '#e0e0e0';
        const error = input.parentNode.querySelector('.error-message');
        if (error) error.remove();
    }, 3000);
}

// ===== GESTION DU FORMULAIRE DE CONTACT =====
function initContactForm() {
    const contactForm = document.querySelector('.contact-form');
    
    if (contactForm) {
        contactForm.addEventListener('submit', function(e) {
            const nameInput = this.querySelector('input[name="visitorName"]');
            const emailInput = this.querySelector('input[name="visitorEmail"]');
            const phoneInput = this.querySelector('input[name="visitorPhone"]');
            const messageInput = this.querySelector('textarea[name="message"]');
            
            let isValid = true;
            
            if (!nameInput.value.trim()) {
                showError(nameInput, 'Le nom est requis');
                isValid = false;
            }
            
            if (!emailInput.value.trim()) {
                showError(emailInput, 'L\'email est requis');
                isValid = false;
            } else if (!isValidEmail(emailInput.value.trim())) {
                showError(emailInput, 'Email invalide');
                isValid = false;
            }
            
            if (!messageInput.value.trim()) {
                showError(messageInput, 'Le message est requis');
                isValid = false;
            }
            
            if (!isValid) {
                e.preventDefault();
            } else {
                // Afficher un loader
                const submitBtn = this.querySelector('button[type="submit"]');
                submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Envoi en cours...';
                submitBtn.disabled = true;
            }
        });
    }
}

// ===== UTILITAIRES =====
function showNotification(message, type = 'success') {
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 15px 25px;
        background: ${type === 'success' ? '#27ae60' : '#e74c3c'};
        color: white;
        border-radius: 8px;
        box-shadow: 0 5px 15px rgba(0,0,0,0.2);
        z-index: 9999;
        animation: slideIn 0.3s ease;
    `;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

// Animation CSS pour les notifications
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    
    @keyframes slideOut {
        from {
            transform: translateX(0);
            opacity: 1;
        }
        to {
            transform: translateX(100%);
            opacity: 0;
        }
    }
    
    .nav.active {
        display: flex !important;
        flex-direction: column;
        position: absolute;
        top: 100%;
        left: 0;
        right: 0;
        background: #2c3e50;
        padding: 20px;
        z-index: 1000;
    }
    
    .nav.active a {
        margin: 10px 0;
    }
    
    .mobile-menu-toggle {
        display: none;
    }
    
    @media (max-width: 768px) {
        .nav {
            display: none;
        }
        
        .mobile-menu-toggle {
            display: block !important;
        }
    }
`;
document.head.appendChild(style);

// ===== EXPOSER LES FONCTIONS GLOBALEMENT =====
window.initGallery = initGallery;
window.initReactions = initReactions;
window.initCommentForm = initCommentForm;
window.initContactForm = initContactForm;
window.showNotification = showNotification;