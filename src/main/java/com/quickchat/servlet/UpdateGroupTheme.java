package com.quickchat.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import com.quickchat.dao.GroupDAO;

@WebServlet("/updateGroupTheme")
public class UpdateGroupTheme extends HttpServlet {
    
    private static final long serialVersionUID = 1L;
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        System.out.println("=== UpdateGroupTheme appelée ===");
        
        // Récupérer les paramètres
        String groupIdParam = request.getParameter("groupId");
        String theme = request.getParameter("theme");
        
        System.out.println("groupIdParam: " + groupIdParam);
        System.out.println("theme: " + theme);
        
        if (groupIdParam == null || theme == null) {
            System.out.println("Paramètres manquants");
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }
        
        try {
            int groupId = Integer.parseInt(groupIdParam);
            GroupDAO groupDAO = new GroupDAO();
            boolean updated = groupDAO.updateGroupTheme(groupId, theme);
            
            System.out.println("Mise à jour réussie: " + updated);
            
            if (updated) {
                response.setStatus(HttpServletResponse.SC_OK);
                response.getWriter().write("Theme updated");
            } else {
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            }
        } catch (NumberFormatException e) {
            System.out.println("Erreur format groupId: " + e.getMessage());
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        }
    }
}