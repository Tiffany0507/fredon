package com.immobilier.servlet;

import com.immobilier.dao.PropertyDAO;
import com.immobilier.model.Property;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.*;
import java.util.UUID;

@WebServlet("/contact-agent")
public class ContactAgentServlet extends HttpServlet {

    private static final String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String propertyIdStr = request.getParameter("propertyId");
        String visitorName = request.getParameter("visitorName");
        String visitorEmail = request.getParameter("visitorEmail");
        String visitorPhone = request.getParameter("visitorPhone");
        String message = request.getParameter("message");

        // Validation
        if (propertyIdStr == null || propertyIdStr.trim().isEmpty() ||
            visitorName == null || visitorName.trim().isEmpty() ||
            visitorEmail == null || visitorEmail.trim().isEmpty() ||
            message == null || message.trim().isEmpty()) {
            
            response.sendRedirect(request.getHeader("Referer") + "?error=missing_fields");
            return;
        }

        // Validation email
        if (!visitorEmail.matches("^[A-Za-z0-9+_.-]+@(.+)$")) {
            response.sendRedirect(request.getHeader("Referer") + "?error=invalid_email");
            return;
        }

        try {
            int propertyId = Integer.parseInt(propertyIdStr);
            
            Class.forName("com.mysql.cj.jdbc.Driver");
            
            try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
                PropertyDAO propertyDAO = new PropertyDAO(conn);
                Property property = propertyDAO.getPropertyById(propertyId);
                
                if (property == null) {
                    response.sendRedirect(request.getHeader("Referer") + "?error=property_not_found");
                    return;
                }

                // Créer une conversation dans le module de messagerie QuickChat
                String conversationId = createConversation(conn, visitorName, visitorEmail, visitorPhone, property);
                
                if (conversationId != null) {
                    // Ajouter le premier message
                    boolean messageSent = addMessageToConversation(conn, conversationId, visitorName, message, property);
                    
                    if (messageSent) {
                        response.sendRedirect(request.getHeader("Referer") + "?success=message_sent");
                    } else {
                        response.sendRedirect(request.getHeader("Referer") + "?error=send_failed");
                    }
                } else {
                    response.sendRedirect(request.getHeader("Referer") + "?error=conversation_failed");
                }
            }
            
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getHeader("Referer") + "?error=invalid_property");
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            response.sendRedirect(request.getHeader("Referer") + "?error=database_error");
        }
    }

    // Créer une conversation dans la table conversations de QuickChat
    private String createConversation(Connection conn, String visitorName, String visitorEmail, 
                                      String visitorPhone, Property property) throws SQLException {
        
        // Vérifier si la table conversations existe
        if (!tableExists(conn, "conversations")) {
            // Créer la table si elle n'existe pas
            createConversationsTable(conn);
        }

        String conversationId = UUID.randomUUID().toString();
        
        String subject = "Demande concernant : " + property.getTitle() + " (Réf: " + property.getId() + ")";
        
        String sql = "INSERT INTO conversations (id, visitor_name, visitor_email, visitor_phone, " +
                     "property_id, property_title, subject, status, created_at, updated_at) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, 'open', NOW(), NOW())";
        
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, conversationId);
            stmt.setString(2, visitorName);
            stmt.setString(3, visitorEmail);
            stmt.setString(4, visitorPhone);
            stmt.setInt(5, property.getId());
            stmt.setString(6, property.getTitle());
            stmt.setString(7, subject);
            
            int rows = stmt.executeUpdate();
            return rows > 0 ? conversationId : null;
        }
    }

    // Ajouter un message à une conversation
    private boolean addMessageToConversation(Connection conn, String conversationId, 
                                             String senderName, String content, Property property) throws SQLException {
        
        // Vérifier si la table messages existe
        if (!tableExists(conn, "messages")) {
            createMessagesTable(conn);
        }

        String sql = "INSERT INTO messages (conversation_id, sender_type, sender_name, " +
                     "content, property_reference, created_at) " +
                     "VALUES (?, 'visitor', ?, ?, ?, NOW())";
        
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, conversationId);
            stmt.setString(2, senderName);
            stmt.setString(3, content);
            stmt.setString(4, property.getTitle() + " (ID: " + property.getId() + ")");
            
            return stmt.executeUpdate() > 0;
        }
    }

    // Vérifier si une table existe
    private boolean tableExists(Connection conn, String tableName) throws SQLException {
        DatabaseMetaData meta = conn.getMetaData();
        try (ResultSet rs = meta.getTables(null, null, tableName, null)) {
            return rs.next();
        }
    }

    // Créer la table conversations
    private void createConversationsTable(Connection conn) throws SQLException {
        String sql = "CREATE TABLE conversations (" +
                     "id VARCHAR(36) PRIMARY KEY," +
                     "visitor_name VARCHAR(100) NOT NULL," +
                     "visitor_email VARCHAR(150) NOT NULL," +
                     "visitor_phone VARCHAR(20)," +
                     "property_id INT," +
                     "property_title VARCHAR(255)," +
                     "subject VARCHAR(255)," +
                     "status ENUM('open', 'closed', 'archived') DEFAULT 'open'," +
                     "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP," +
                     "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" +
                     ")";
        
        try (Statement stmt = conn.createStatement()) {
            stmt.execute(sql);
        }
    }

    // Créer la table messages
    private void createMessagesTable(Connection conn) throws SQLException {
        String sql = "CREATE TABLE messages (" +
                     "id INT AUTO_INCREMENT PRIMARY KEY," +
                     "conversation_id VARCHAR(36) NOT NULL," +
                     "sender_type ENUM('visitor', 'admin') NOT NULL," +
                     "sender_name VARCHAR(100) NOT NULL," +
                     "content TEXT NOT NULL," +
                     "property_reference VARCHAR(255)," +
                     "is_read BOOLEAN DEFAULT FALSE," +
                     "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP," +
                     "FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE" +
                     ")";
        
        try (Statement stmt = conn.createStatement()) {
            stmt.execute(sql);
        }
    }
}