package com.quickchat.model;

public class Message {

    private int id;
    private int senderId;
    private int receiverId;
    private String content;
    private boolean isRead;
    private String createdAt;
    private String updatedAt;
    private String senderName;
    private String receiverName;
    private String filePath;
    private String fileType;
    private boolean deletedForSender;
    private boolean deletedForReceiver;
    private String gifUrl;
    private int replyToMessageId;
    private boolean isDelivered;
    private boolean isPinned;

    // ── NOUVEAUX CHAMPS : publication immobilière partagée ──────────────────
    private Integer propertyId;
    private String  propertyTitle;
    private Long    propertyPrice;
    private String  propertyImage;
    private String  propertyType;
    private String  propertyLocation;
    // ────────────────────────────────────────────────────────────────────────

    public Message() {}

    public Message(int senderId, int receiverId, String content) {
        this.senderId   = senderId;
        this.receiverId = receiverId;
        this.content    = content;
        this.isRead     = false;
    }

    // ── Logique suppression ─────────────────────────────────────────────────
    public boolean isDeletedForUser(int userId) {
        if (isDeletedForEveryone()) return false;
        if (senderId   == userId && deletedForSender)   return true;
        if (receiverId == userId && deletedForReceiver) return true;
        return false;
    }

    public boolean isDeletedForEveryone() {
        return content != null && content.equals("[Message supprimé]");
    }

    // ── Getters / Setters ───────────────────────────────────────────────────
    public int     getId()            { return id; }
    public void    setId(int id)      { this.id = id; }

    public int     getSenderId()             { return senderId; }
    public void    setSenderId(int v)        { this.senderId = v; }

    public int     getReceiverId()           { return receiverId; }
    public void    setReceiverId(int v)      { this.receiverId = v; }

    public String  getContent()              { return content; }
    public void    setContent(String v)      { this.content = v; }

    public boolean isIsRead()                { return isRead; }
    public void    setIsRead(boolean v)      { this.isRead = v; }

    public String  getCreatedAt()            { return createdAt; }
    public void    setCreatedAt(String v)    { this.createdAt = v; }

    public String  getUpdatedAt()            { return updatedAt; }
    public void    setUpdatedAt(String v)    { this.updatedAt = v; }

    public String  getSenderName()           { return senderName; }
    public void    setSenderName(String v)   { this.senderName = v; }

    public String  getReceiverName()         { return receiverName; }
    public void    setReceiverName(String v) { this.receiverName = v; }

    public boolean isDeletedForSender()             { return deletedForSender; }
    public void    setDeletedForSender(boolean v)   { this.deletedForSender = v; }

    public boolean isDeletedForReceiver()           { return deletedForReceiver; }
    public void    setDeletedForReceiver(boolean v) { this.deletedForReceiver = v; }

    public String  getFilePath()             { return filePath; }
    public void    setFilePath(String v)     { this.filePath = v; }

    public String  getFileType()             { return fileType; }
    public void    setFileType(String v)     { this.fileType = v; }

    public String  getGifUrl()               { return gifUrl; }
    public void    setGifUrl(String v)       { this.gifUrl = v; }

    public boolean isIsDelivered()           { return isDelivered; }
    public void    setIsDelivered(boolean v) { this.isDelivered = v; }

    public boolean isIsPinned()              { return isPinned; }
    public void    setIsPinned(boolean v)    { this.isPinned = v; }

    public int     getReplyToMessageId()        { return replyToMessageId; }
    public void    setReplyToMessageId(int v)   { this.replyToMessageId = v; }

    // ── Getters / Setters publication ───────────────────────────────────────
    public Integer getPropertyId()               { return propertyId; }
    public void    setPropertyId(Integer v)      { this.propertyId = v; }

    public String  getPropertyTitle()            { return propertyTitle; }
    public void    setPropertyTitle(String v)    { this.propertyTitle = v; }

    public Long    getPropertyPrice()            { return propertyPrice; }
    public void    setPropertyPrice(Long v)      { this.propertyPrice = v; }

    public String  getPropertyImage()            { return propertyImage; }
    public void    setPropertyImage(String v)    { this.propertyImage = v; }

    public String  getPropertyType()             { return propertyType; }
    public void    setPropertyType(String v)     { this.propertyType = v; }

    public String  getPropertyLocation()         { return propertyLocation; }
    public void    setPropertyLocation(String v) { this.propertyLocation = v; }
}