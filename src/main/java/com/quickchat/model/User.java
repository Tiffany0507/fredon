package com.quickchat.model;

public class User {
    
    private int id;
    private String username;
    private String email;
    private String password;
    private String fullName;
    private String status;
    private String createdAt;
    private String updatedAt;
    private String profilePic;
    private String displayName;
    private String lastSeen;
    private String role;  // ← Ajouté pour la gestion des rôles (admin/user)
    private String phone;  // ← AJOUTÉ : Numéro de téléphone
    private String bio;    // ← AJOUTÉ : Biographie / À propos
    
    // Constructeur par défaut
    public User() {}
    
    // Constructeur avec paramètres principaux
    public User(int id, String username, String email, String displayName) {
        this.id = id;
        this.username = username;
        this.email = email;
        this.displayName = displayName;
    }
    
    // Getters et Setters
    public int getId() { 
        return id; 
    }
    
    public void setId(int id) { 
        this.id = id; 
    }
    
    public String getUsername() { 
        return username; 
    }
    
    public void setUsername(String username) { 
        this.username = username; 
    }
    
    public String getEmail() { 
        return email; 
    }
    
    public void setEmail(String email) { 
        this.email = email; 
    }
    
    public String getPassword() { 
        return password; 
    }
    
    public void setPassword(String password) { 
        this.password = password; 
    }
    
    public String getFullName() { 
        return fullName; 
    }
    
    public void setFullName(String fullName) { 
        this.fullName = fullName; 
    }
    
    public String getStatus() { 
        return status; 
    }
    
    public void setStatus(String status) { 
        this.status = status; 
    }
    
    public String getCreatedAt() { 
        return createdAt; 
    }
    
    public void setCreatedAt(String createdAt) { 
        this.createdAt = createdAt; 
    }
    
    public String getUpdatedAt() { 
        return updatedAt; 
    }
    
    public void setUpdatedAt(String updatedAt) { 
        this.updatedAt = updatedAt; 
    }
    
    public String getProfilePic() { 
        return profilePic; 
    }
    
    public void setProfilePic(String profilePic) { 
        this.profilePic = profilePic; 
    }
    
    public String getDisplayName() { 
        return displayName != null && !displayName.isEmpty() ? displayName : username; 
    }
    
    public void setDisplayName(String displayName) { 
        this.displayName = displayName; 
    }
    
    public String getLastSeen() { 
        return lastSeen; 
    }

    public void setLastSeen(String lastSeen) { 
        this.lastSeen = lastSeen; 
    }
    
    public String getRole() { 
        return role; 
    }
    
    public void setRole(String role) { 
        this.role = role; 
    }
    
    // ========== NOUVEAUX GETTERS ET SETTERS ==========
    
    public String getPhone() {
        return phone;
    }
    
    public void setPhone(String phone) {
        this.phone = phone;
    }
    
    public String getBio() {
        return bio;
    }
    
    public void setBio(String bio) {
        this.bio = bio;
    }
    
    // ========== MÉTHODES UTILITAIRES ==========
    
    // Méthode utilitaire pour vérifier si l'utilisateur est admin
    public boolean isAdmin() {
        return "admin".equals(role) || "admin@fredon.mg".equals(email);
    }
    
    // Méthode utilitaire pour vérifier si l'utilisateur est connecté
    public boolean isLoggedIn() {
        return this.id > 0;
    }
    
    // Méthode pour obtenir l'initiale
    public String getInitial() {
        String name = getDisplayName();
        if (name != null && !name.isEmpty()) {
            return name.substring(0, 1).toUpperCase();
        }
        return "?";
    }
    
    // Méthode pour obtenir le chemin de la photo de profil
    public String getProfilePicPath() {
        if (profilePic != null && !profilePic.isEmpty()) {
            return "uploads/" + profilePic;
        }
        return null;
    }
    
    // Méthode pour vérifier si le téléphone est renseigné
    public boolean hasPhone() {
        return phone != null && !phone.isEmpty();
    }
    
    // Méthode pour vérifier si la bio est renseignée
    public boolean hasBio() {
        return bio != null && !bio.isEmpty();
    }
    
    @Override
    public String toString() {
        return "User{" +
                "id=" + id +
                ", username='" + username + '\'' +
                ", email='" + email + '\'' +
                ", displayName='" + displayName + '\'' +
                ", role='" + role + '\'' +
                ", phone='" + phone + '\'' +
                '}';
    }
}