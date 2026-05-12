package com.quickchat.model;

public class Group {
    
    private int id;
    private String name;
    private String description;
    private int createdBy;
    private String createdAt;
    private String updatedAt;
    private String theme;  // Nouvelle propriété pour le thème du groupe
    
    // Constructeurs
    public Group() {}
    
    public Group(String name, String description, int createdBy) {
        this.name = name;
        this.description = description;
        this.createdBy = createdBy;
        this.theme = "default";  // Thème par défaut
    }
    
    // Getters et Setters
    public int getId() { 
        return id; 
    }
    
    public void setId(int id) { 
        this.id = id; 
    }
    
    public String getName() { 
        return name; 
    }
    
    public void setName(String name) { 
        this.name = name; 
    }
    
    public String getDescription() { 
        return description; 
    }
    
    public void setDescription(String description) { 
        this.description = description; 
    }
    
    public int getCreatedBy() { 
        return createdBy; 
    }
    
    public void setCreatedBy(int createdBy) { 
        this.createdBy = createdBy; 
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
    
    public String getTheme() { 
        return theme; 
    }
    
    public void setTheme(String theme) { 
        this.theme = theme != null ? theme : "default"; 
    }
}