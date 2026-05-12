package com.quickchat.model;

public class GroupMessage {
    
    private int id;
    private int groupId;
    private int senderId;
    private String senderName;
    private String content;
    private String filePath;
    private String fileType;
    private String createdAt;
    private String updatedAt;
    private int replyToMessageId;
    private boolean isPinned;
    private String gifUrl;
    private boolean deletedForEveryone;
    
    // Constructeurs
    public GroupMessage() {}
    
    public GroupMessage(int groupId, int senderId, String content) {
        this.groupId = groupId;
        this.senderId = senderId;
        this.content = content;
    }
    
    // Getters et Setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    
    public int getGroupId() { return groupId; }
    public void setGroupId(int groupId) { this.groupId = groupId; }
    
    public int getSenderId() { return senderId; }
    public void setSenderId(int senderId) { this.senderId = senderId; }
    
    public String getSenderName() { return senderName; }
    public void setSenderName(String senderName) { this.senderName = senderName; }
    
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    
    public String getFilePath() { return filePath; }
    public void setFilePath(String filePath) { this.filePath = filePath; }
    
    public String getFileType() { return fileType; }
    public void setFileType(String fileType) { this.fileType = fileType; }
    
    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
    
    public String getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(String updatedAt) { this.updatedAt = updatedAt; }
    
    public int getReplyToMessageId() { return replyToMessageId; }
    public void setReplyToMessageId(int replyToMessageId) { this.replyToMessageId = replyToMessageId; }
    
    public boolean isIsPinned() { return isPinned; }
    public void setIsPinned(boolean isPinned) { this.isPinned = isPinned; }
    
    public String getGifUrl() { return gifUrl; }
    public void setGifUrl(String gifUrl) { this.gifUrl = gifUrl; }
    public boolean isDeletedForEveryone() {
        return deletedForEveryone;
    }

    public void setDeletedForEveryone(boolean deletedForEveryone) {
        this.deletedForEveryone = deletedForEveryone;
    }
}