package com.immobilier.servlet;

import com.immobilier.dao.PropertyReactionDAO;
import com.immobilier.model.PropertyReaction;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

@WebServlet("/add-reaction")
public class AddReactionServlet extends HttpServlet {

    private static final String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String propertyIdStr = request.getParameter("propertyId");
        String reactionType = request.getParameter("reactionType");

        // Validation
        if (propertyIdStr == null || propertyIdStr.trim().isEmpty() ||
            reactionType == null || reactionType.trim().isEmpty()) {
            
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Paramètres manquants");
            return;
        }

        // Valider le type de réaction
        if (!reactionType.equals("like") && !reactionType.equals("love") && 
            !reactionType.equals("interested") && !reactionType.equals("dislike")) {
            
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Type de réaction invalide");
            return;
        }

        // Récupérer ou créer un identifiant visiteur (basé sur l'IP + User-Agent)
        String visitorIdentifier = getVisitorIdentifier(request);

        try {
            int propertyId = Integer.parseInt(propertyIdStr);
            
            Class.forName("com.mysql.cj.jdbc.Driver");
            
            try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
                PropertyReactionDAO reactionDAO = new PropertyReactionDAO(conn);
                
                PropertyReaction reaction = new PropertyReaction();
                reaction.setPropertyId(propertyId);
                reaction.setVisitorIdentifier(visitorIdentifier);
                reaction.setReactionType(reactionType);
                
                boolean success = reactionDAO.addOrUpdateReaction(reaction);
                
                if (success) {
                    // Retourner les nouveaux compteurs en JSON
                    response.setContentType("application/json");
                    response.setCharacterEncoding("UTF-8");
                    
                    int total = reactionDAO.countTotalReactionsByPropertyId(propertyId);
                    var counts = reactionDAO.countReactionsByPropertyId(propertyId);
                    
                    StringBuilder json = new StringBuilder();
                    json.append("{");
                    json.append("\"success\": true,");
                    json.append("\"total\": ").append(total).append(",");
                    json.append("\"likes\": ").append(counts.getOrDefault("like", 0)).append(",");
                    json.append("\"loves\": ").append(counts.getOrDefault("love", 0)).append(",");
                    json.append("\"interested\": ").append(counts.getOrDefault("interested", 0)).append(",");
                    json.append("\"dislikes\": ").append(counts.getOrDefault("dislike", 0)).append(",");
                    json.append("\"visitorReaction\": \"").append(reactionType).append("\"");
                    json.append("}");
                    
                    response.getWriter().write(json.toString());
                    
                } else {
                    response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Erreur lors de l'ajout de la réaction");
                }
            }
            
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "ID de propriété invalide");
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Erreur de base de données");
        }
    }

    @Override
    protected void doDelete(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String propertyIdStr = request.getParameter("propertyId");
        
        if (propertyIdStr == null || propertyIdStr.trim().isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Paramètres manquants");
            return;
        }

        String visitorIdentifier = getVisitorIdentifier(request);

        try {
            int propertyId = Integer.parseInt(propertyIdStr);
            
            Class.forName("com.mysql.cj.jdbc.Driver");
            
            try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
                PropertyReactionDAO reactionDAO = new PropertyReactionDAO(conn);
                
                boolean success = reactionDAO.deleteReaction(propertyId, visitorIdentifier);
                
                if (success) {
                    response.setContentType("application/json");
                    response.setCharacterEncoding("UTF-8");
                    
                    int total = reactionDAO.countTotalReactionsByPropertyId(propertyId);
                    var counts = reactionDAO.countReactionsByPropertyId(propertyId);
                    
                    StringBuilder json = new StringBuilder();
                    json.append("{");
                    json.append("\"success\": true,");
                    json.append("\"total\": ").append(total).append(",");
                    json.append("\"likes\": ").append(counts.getOrDefault("like", 0)).append(",");
                    json.append("\"loves\": ").append(counts.getOrDefault("love", 0)).append(",");
                    json.append("\"interested\": ").append(counts.getOrDefault("interested", 0)).append(",");
                    json.append("\"dislikes\": ").append(counts.getOrDefault("dislike", 0)).append(",");
                    json.append("\"visitorReaction\": null");
                    json.append("}");
                    
                    response.getWriter().write(json.toString());
                    
                } else {
                    response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Erreur lors de la suppression");
                }
            }
            
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "ID de propriété invalide");
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Erreur de base de données");
        }
    }

    // Générer un identifiant unique pour le visiteur
    private String getVisitorIdentifier(HttpServletRequest request) {
        String ip = request.getRemoteAddr();
        String userAgent = request.getHeader("User-Agent");
        String sessionId = request.getSession().getId();
        
        // Combiner IP et User-Agent pour créer un identifiant unique
        return Integer.toHexString((ip + userAgent + sessionId).hashCode());
    }
}