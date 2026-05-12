package com.quickchat.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/add-message-reaction")  // ← URL MODIFIÉE (était "/addReaction")
public class MessageReactionServlet extends HttpServlet {

    private static final String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String messageIdStr = request.getParameter("messageId");
        String reactionType = request.getParameter("reactionType");
        String userId = (String) request.getSession().getAttribute("userId");

        // Validation
        if (messageIdStr == null || messageIdStr.trim().isEmpty() ||
            reactionType == null || reactionType.trim().isEmpty()) {

            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Paramètres manquants");
            return;
        }

        if (userId == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Utilisateur non connecté");
            return;
        }

        // Validation du type de réaction (emoji)
        if (!reactionType.equals("👍") && !reactionType.equals("❤️") &&
            !reactionType.equals("😂") && !reactionType.equals("😮") &&
            !reactionType.equals("😢") && !reactionType.equals("😡")) {

            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Type de réaction invalide");
            return;
        }

        try {
            int messageId = Integer.parseInt(messageIdStr);
            int userIdInt = Integer.parseInt(userId);

            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
                // Ici tu appelles ton DAO pour les réactions de message
                // Exemple : MessageReactionDAO reactionDAO = new MessageReactionDAO(conn);
                // boolean success = reactionDAO.addOrUpdateReaction(messageId, userIdInt, reactionType);

                boolean success = true; // À remplacer par ton DAO

                if (success) {
                    response.setContentType("application/json");
                    response.setCharacterEncoding("UTF-8");

                    StringBuilder json = new StringBuilder();
                    json.append("{");
                    json.append("\"success\": true,");
                    json.append("\"messageId\": ").append(messageId).append(",");
                    json.append("\"reactionType\": \"").append(reactionType).append("\"");
                    json.append("}");

                    response.getWriter().write(json.toString());
                } else {
                    response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Erreur lors de l'ajout de la réaction");
                }
            }

        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "ID de message invalide");
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Erreur de base de données");
        }
    }

    @Override
    protected void doDelete(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String messageIdStr = request.getParameter("messageId");
        String userId = (String) request.getSession().getAttribute("userId");

        if (messageIdStr == null || messageIdStr.trim().isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Paramètre manquant");
            return;
        }

        if (userId == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Utilisateur non connecté");
            return;
        }

        try {
            int messageId = Integer.parseInt(messageIdStr);
            int userIdInt = Integer.parseInt(userId);

            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
                // Ici tu appelles ton DAO pour supprimer la réaction
                // boolean success = reactionDAO.deleteReaction(messageId, userIdInt);

                boolean success = true; // À remplacer par ton DAO

                if (success) {
                    response.setContentType("application/json");
                    response.setCharacterEncoding("UTF-8");

                    StringBuilder json = new StringBuilder();
                    json.append("{");
                    json.append("\"success\": true,");
                    json.append("\"messageId\": ").append(messageId).append(",");
                    json.append("\"reactionType\": null");
                    json.append("}");

                    response.getWriter().write(json.toString());
                } else {
                    response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Erreur lors de la suppression");
                }
            }

        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "ID de message invalide");
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Erreur de base de données");
        }
    }
}