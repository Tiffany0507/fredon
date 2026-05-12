package com.quickchat.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/addReaction")
public class AddReactionServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    private static final String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        Integer userId = (Integer) session.getAttribute("adminId");
        if (userId == null) {
            userId = 9; // ID par défaut pour l'agent
        }
        
        String messageIdStr = request.getParameter("messageId");
        String reactionType = request.getParameter("reactionType");
        String receiverIdStr = request.getParameter("userId");
        
        if (messageIdStr == null || reactionType == null || messageIdStr.isEmpty() || reactionType.isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/chat.jsp");
            return;
        }
        
        int messageId = Integer.parseInt(messageIdStr);
        int receiverId = (receiverIdStr != null && !receiverIdStr.isEmpty()) ? Integer.parseInt(receiverIdStr) : 0;
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
                // Vérifier si la réaction existe déjà
                String checkSql = "SELECT id FROM message_reactions WHERE message_id = ? AND user_id = ? AND reaction_type = ?";
                try (PreparedStatement checkStmt = conn.prepareStatement(checkSql)) {
                    checkStmt.setInt(1, messageId);
                    checkStmt.setInt(2, userId);
                    checkStmt.setString(3, reactionType);
                    ResultSet rs = checkStmt.executeQuery();
                    
                    if (rs.next()) {
                        // Supprimer la réaction si elle existe déjà (toggle)
                        String deleteSql = "DELETE FROM message_reactions WHERE message_id = ? AND user_id = ? AND reaction_type = ?";
                        try (PreparedStatement deleteStmt = conn.prepareStatement(deleteSql)) {
                            deleteStmt.setInt(1, messageId);
                            deleteStmt.setInt(2, userId);
                            deleteStmt.setString(3, reactionType);
                            deleteStmt.executeUpdate();
                        }
                    } else {
                        // Ajouter la nouvelle réaction
                        String insertSql = "INSERT INTO message_reactions (message_id, user_id, reaction_type) VALUES (?, ?, ?)";
                        try (PreparedStatement insertStmt = conn.prepareStatement(insertSql)) {
                            insertStmt.setInt(1, messageId);
                            insertStmt.setInt(2, userId);
                            insertStmt.setString(3, reactionType);
                            insertStmt.executeUpdate();
                        }
                    }
                    rs.close();
                }
            }
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
        }
        
        // Rediriger vers la conversation
        if (receiverId > 0) {
            response.sendRedirect(request.getContextPath() + "/chat.jsp?userId=" + receiverId);
        } else {
            response.sendRedirect(request.getContextPath() + "/chat.jsp");
        }
    }
}