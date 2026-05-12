package com.immobilier.model;

import java.sql.Timestamp;

public class Terrain {
    private int id;
    private String titre;
    private String description;
    private double superficie;
    private double prix;
    private String localisation;
    private String statut;
    private int adminId;
    private Timestamp createdAt;
    
    public Terrain() {}
    
    public Terrain(String titre, String description, double superficie, 
                   double prix, String localisation, int adminId) {
        this.titre = titre;
        this.description = description;
        this.superficie = superficie;
        this.prix = prix;
        this.localisation = localisation;
        this.adminId = adminId;
    }
    
    // Getters et Setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    
    public String getTitre() { return titre; }
    public void setTitre(String titre) { this.titre = titre; }
    
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    
    public double getSuperficie() { return superficie; }
    public void setSuperficie(double superficie) { this.superficie = superficie; }
    
    public double getPrix() { return prix; }
    public void setPrix(double prix) { this.prix = prix; }
    
    public String getLocalisation() { return localisation; }
    public void setLocalisation(String localisation) { this.localisation = localisation; }
    
    public String getStatut() { return statut; }
    public void setStatut(String statut) { this.statut = statut; }
    
    public int getAdminId() { return adminId; }
    public void setAdminId(int adminId) { this.adminId = adminId; }
    
    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }
}