package com.quickchat.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.quickchat.model.User;
import com.quickchat.utils.PasswordUtil;

@WebServlet("/deleteAccount")
public class DeleteAccountServlet extends HttpServlet {
    
    private static final String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User currentUser = (User) session.getAttribute("user");
        
        if (currentUser == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        
        String password = request.getParameter("password");
        
        if (password == null || password.trim().isEmpty()) {
            session.setAttribute("deleteError", "Veuillez entrer votre mot de passe");
            response.sendRedirect(request.getContextPath() + "/immo/index.jsp");
            return;
        }
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            
            // Vérifier le mot de passe
            PreparedStatement checkStmt = conn.prepareStatement("SELECT password FROM users WHERE id = ?");
            checkStmt.setInt(1, currentUser.getId());
            ResultSet rs = checkStmt.executeQuery();
            
            if (rs.next()) {
                String storedHash = rs.getString("password");
                if (PasswordUtil.checkPassword(password, storedHash)) {
                    // Supprimer les favoris
                    PreparedStatement delFavs = conn.prepareStatement("DELETE FROM user_favorites WHERE user_id = ?");
                    delFavs.setInt(1, currentUser.getId());
                    delFavs.executeUpdate();
                    delFavs.close();
                    
                    // Supprimer l'utilisateur
                    PreparedStatement delUser = conn.prepareStatement("DELETE FROM users WHERE id = ?");
                    delUser.setInt(1, currentUser.getId());
                    delUser.executeUpdate();
                    delUser.close();
                    
                    conn.close();
                    
                    // Invalider la session
                    session.invalidate();
                    
                    // Rediriger vers l'accueil
                    response.sendRedirect(request.getContextPath() + "/immo/index.jsp?accountDeleted=true");
                    return;
                } else {
                    session.setAttribute("deleteError", "Mot de passe incorrect");
                }
            }
            rs.close();
            checkStmt.close();
            conn.close();
            
        } catch (Exception e) {
            e.printStackTrace();
            session.setAttribute("deleteError", "Erreur: " + e.getMessage());
        }
        
        response.sendRedirect(request.getContextPath() + "/immo/index.jsp");
    }
}