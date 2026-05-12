package com.quickchat.servlet;

import com.quickchat.dao.ConversationThemeDAO;
import com.quickchat.model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;

@WebServlet("/updateTheme")
public class UpdateThemeServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    // Liste complète des thèmes valides
    private static final List<String> ALLOWED_THEMES = Arrays.asList(
        "default", "ocean", "rose", "basketball", "forest", "forest-premium",
        "sunset", "sunset-premium", "midnight", "midnight-premium", 
        "aurora", "aurora-premium", "cherry", "cosmic", "beach", 
        "golden", "lavender", "monochrome"
    );

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("=== UpdateThemeServlet appelée ===");
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            System.out.println("Utilisateur non connecté");
            response.sendRedirect("login.jsp");
            return;
        }

        User user = (User) session.getAttribute("user");
        System.out.println("User ID: " + user.getId());

        String contactIdParam = request.getParameter("contactId");
        String themeName = request.getParameter("theme");

        System.out.println("Contact ID param: " + contactIdParam);
        System.out.println("Theme name: " + themeName);

        if (contactIdParam == null || themeName == null) {
            System.out.println("Paramètres manquants");
            response.sendRedirect("chat.jsp");
            return;
        }

        if (!ALLOWED_THEMES.contains(themeName)) {
            System.out.println("Thème non autorisé: " + themeName + ", utilisation de default");
            themeName = "default";
        }

        try {
            int contactId = Integer.parseInt(contactIdParam);
            ConversationThemeDAO themeDAO = new ConversationThemeDAO();
            
            boolean success = themeDAO.saveTheme(user.getId(), contactId, themeName);
            System.out.println("Sauvegarde du thème: " + success);
            
            if (success) {
                response.setStatus(HttpServletResponse.SC_OK);
                response.getWriter().write("Theme updated successfully");
            } else {
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                response.getWriter().write("Failed to update theme");
            }
            
        } catch (NumberFormatException e) {
            System.out.println("Erreur de format: " + e.getMessage());
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doPost(request, response);
    }
}