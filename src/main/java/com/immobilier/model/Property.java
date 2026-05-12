package com.immobilier.model;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class Property {
    private int id;
    private String title;
    private String description;
    private BigDecimal price;
    private String location;
    private String type;
    private Integer surface;
    private Integer rooms;
    private Integer bedrooms;
    private Integer bathrooms;
    private Timestamp createdAt;
    private int adminId;
    private int viewsCount;
    private Double latitude;
    private Double longitude;
    private String imagePath;
    
    // ⭐⭐⭐ CHAMPS TERRAIN ⭐⭐⭐
    private String landArea;
    private String landType;
    private String landDocumentation;
    private String landAccess;
    private String landProximities;
    private String landNotes;
    
    // ⭐⭐⭐ CHAMPS POUR LA VENTE ⭐⭐⭐
    private String status;
    private Integer buyerId;      // ID du client qui a acheté
    private Timestamp soldAt;     // Date de vente

    public Property() {
    }

    public Property(int id, String title, String description, BigDecimal price, 
                    String location, String type, Integer surface, Integer rooms, 
                    Integer bedrooms, Integer bathrooms, Timestamp createdAt, int adminId, 
                    int viewsCount, Double latitude, Double longitude, String imagePath) {
        this.id = id;
        this.title = title;
        this.description = description;
        this.price = price;
        this.location = location;
        this.type = type;
        this.surface = surface;
        this.rooms = rooms;
        this.bedrooms = bedrooms;
        this.bathrooms = bathrooms;
        this.createdAt = createdAt;
        this.adminId = adminId;
        this.viewsCount = viewsCount;
        this.latitude = latitude;
        this.longitude = longitude;
        this.imagePath = imagePath;
    }

    // ========== GETTERS ET SETTERS EXISTANTS ==========
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public Integer getSurface() { return surface; }
    public void setSurface(Integer surface) { this.surface = surface; }

    public Integer getRooms() { return rooms; }
    public void setRooms(Integer rooms) { this.rooms = rooms; }

    public Integer getBedrooms() { return bedrooms; }
    public void setBedrooms(Integer bedrooms) { this.bedrooms = bedrooms; }

    public Integer getBathrooms() { return bathrooms; }
    public void setBathrooms(Integer bathrooms) { this.bathrooms = bathrooms; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public int getAdminId() { return adminId; }
    public void setAdminId(int adminId) { this.adminId = adminId; }

    public int getViewsCount() { return viewsCount; }
    public void setViewsCount(int viewsCount) { this.viewsCount = viewsCount; }

    public Double getLatitude() { return latitude; }
    public void setLatitude(Double latitude) { this.latitude = latitude; }

    public Double getLongitude() { return longitude; }
    public void setLongitude(Double longitude) { this.longitude = longitude; }

    public String getImagePath() { return imagePath; }
    public void setImagePath(String imagePath) { this.imagePath = imagePath; }

    // ========== GETTERS ET SETTERS TERRAIN ==========
    public String getLandArea() { return landArea; }
    public void setLandArea(String landArea) { this.landArea = landArea; }

    public String getLandType() { return landType; }
    public void setLandType(String landType) { this.landType = landType; }

    public String getLandDocumentation() { return landDocumentation; }
    public void setLandDocumentation(String landDocumentation) { this.landDocumentation = landDocumentation; }

    public String getLandAccess() { return landAccess; }
    public void setLandAccess(String landAccess) { this.landAccess = landAccess; }

    public String getLandProximities() { return landProximities; }
    public void setLandProximities(String landProximities) { this.landProximities = landProximities; }

    public String getLandNotes() { return landNotes; }
    public void setLandNotes(String landNotes) { this.landNotes = landNotes; }

    // ========== GETTERS ET SETTERS POUR LA VENTE ==========
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Integer getBuyerId() { return buyerId; }
    public void setBuyerId(Integer buyerId) { this.buyerId = buyerId; }

    public Timestamp getSoldAt() { return soldAt; }
    public void setSoldAt(Timestamp soldAt) { this.soldAt = soldAt; }

    @Override
    public String toString() {
        return "Property{" +
                "id=" + id +
                ", title='" + title + '\'' +
                ", price=" + price +
                ", location='" + location + '\'' +
                ", type='" + type + '\'' +
                ", status='" + status + '\'' +
                ", viewsCount=" + viewsCount +
                '}';
    }
}