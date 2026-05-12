package com.immobilier.servlet;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.*;

@WebServlet("/admin/login")
public class AdminLoginServlet extends HttpServlet {

    private static final String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        
        if (session != null && session.getAttribute("adminId") != null) {
            response.sendRedirect(request.getContextPath() + "/immo/admin/dashboard.jsp");
            return;
        }
        
        request.getRequestDispatcher("/immo/admin/login.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String username = request.getParameter("username");
        String password = request.getParameter("password");

        if (username == null || username.trim().isEmpty() ||
            password == null || password.trim().isEmpty()) {
            
            response.sendRedirect(request.getContextPath() + "/immo/admin/login.jsp?error=empty");
            return;
        }

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            
            try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
                
                String sql = "SELECT id, username FROM admins WHERE username = ? AND password = ?";
                
                try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                    stmt.setString(1, username);
                    stmt.setString(2, password);
                    
                    try (ResultSet rs = stmt.executeQuery()) {
                        if (rs.next()) {
                            HttpSession session = request.getSession();
                            session.setAttribute("adminId", rs.getInt("id"));
                            session.setAttribute("adminUsername", rs.getString("username"));
                            session.setMaxInactiveInterval(30 * 60);
                            
                            // Créer aussi la session user pour la messagerie (utilisateur admin ID 999)
                            com.quickchat.model.User adminUser = new com.quickchat.model.User();
                            adminUser.setId(999);
                            adminUser.setUsername("admin_user");
                            adminUser.setDisplayName("Administrateur");
                            adminUser.setEmail("admin@agence.com");
                            adminUser.setStatus("online");
                            session.setAttribute("user", adminUser);
                            
                            response.sendRedirect(request.getContextPath() + "/immo/admin/dashboard.jsp");
                        } else {
                            response.sendRedirect(request.getContextPath() + "/immo/admin/login.jsp?error=invalid");
                        }
                    }
                }
            }
            
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/immo/admin/login.jsp?error=database");
        }
    }
}