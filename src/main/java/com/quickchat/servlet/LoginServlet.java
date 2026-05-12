package com.quickchat.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.quickchat.model.User;
import com.quickchat.dao.UserDAO;
import com.quickchat.utils.UserAgentUtils;
import com.immobilier.dao.AdminDAO;
import com.immobilier.model.Admin;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private UserDAO userDAO;
    private AdminDAO adminDAO;
    
    private static final String DB_URL = "jdbc:mysql://localhost:3306/quickchat";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";
    
    public void init() {
        userDAO = new UserDAO();
        adminDAO = new AdminDAO();
    }
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        
        System.out.println("=== TENTATIVE DE CONNEXION ===");
        System.out.println("Email: " + email);
        
        if (email == null || email.trim().isEmpty() || password == null || password.trim().isEmpty()) {
        	response.sendRedirect(request.getContextPath() + "/login?error=Veuillez remplir tous les champs");

        	return;
        }
        
        // Récupérer les infos du navigateur et IP pour enregistrement
        String ip = UserAgentUtils.getClientIpAddress(request);
        String userAgent = request.getHeader("User-Agent");
        UserAgentUtils.DeviceInfo deviceInfo = UserAgentUtils.parseUserAgent(userAgent);
        String location = UserAgentUtils.getLocationFromIp(ip);
        
        // 1. Vérifier si c'est un ADMIN
        Admin admin = adminDAO.loginByEmail(email, password);
        
        if (admin != null) {
            System.out.println("✅ Connexion ADMIN réussie pour: " + admin.getEmail());
            System.out.println("ID de l'admin: " + admin.getId());
            // Enregistrer la connexion dans login_history
            enregistrerConnexion(admin.getId(), ip, userAgent, deviceInfo, location, "success");
            
            HttpSession session = request.getSession();
            session.setAttribute("adminId", admin.getId());
            session.setAttribute("adminUsername", admin.getUsername());
            session.setAttribute("adminEmail", admin.getEmail());
         // Récupérer la photo depuis la table users
            String adminProfilePic = "";
            try {
                Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
                PreparedStatement pstmt = conn.prepareStatement("SELECT profile_pic FROM users WHERE id = ?");
                pstmt.setInt(1, admin.getId());
                ResultSet rs = pstmt.executeQuery();
                if (rs.next()) {
                    adminProfilePic = rs.getString("profile_pic");
                }
                rs.close(); pstmt.close(); conn.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
            session.setAttribute("adminProfilePic", adminProfilePic);
            session.setAttribute("isAdmin", true);
            
            response.sendRedirect(request.getContextPath() + "/admin/dashboard");
            return;
        }
        
        // 2. Sinon, vérifier si c'est un CLIENT
        User user = userDAO.loginByEmail(email, password);
        
        if (user != null) {
            System.out.println("✅ Connexion CLIENT réussie pour: " + user.getEmail());
            
            // Enregistrer la connexion dans login_history
            enregistrerConnexion(user.getId(), ip, userAgent, deviceInfo, location, "success");
            
            userDAO.updateStatus(user.getId(), "online");
            userDAO.updateLastSeen(user.getId());
            
            HttpSession session = request.getSession();
            User fullUser = userDAO.getUserById(user.getId());
            session.setAttribute("user", fullUser);
            session.setAttribute("isAdmin", false);
            
            response.sendRedirect(request.getContextPath() + "/home?page=biens");
            return;
        }
        
        // 3. Si aucun des deux n'est trouvé - enregistrer la tentative échouée
        System.out.println("❌ Échec de connexion pour email: " + email);
        
        // Enregistrer la tentative échouée (user_id = 0 car pas trouvé)
        enregistrerConnexion(0, ip, userAgent, deviceInfo, location, "failed");
        
        response.sendRedirect(request.getContextPath() + "/login?error=Email ou mot de passe incorrect");

    }
    
    // Méthode pour enregistrer les connexions dans la base
    private void enregistrerConnexion(int userId, String ip, String userAgent, 
                                       UserAgentUtils.DeviceInfo deviceInfo, 
                                       String location, String status) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            
            PreparedStatement pstmt = conn.prepareStatement(
                "INSERT INTO login_history (user_id, ip_address, user_agent, browser, os, device, location, login_time, login_status) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), ?)"
            );
            pstmt.setInt(1, userId);
            pstmt.setString(2, ip);
            pstmt.setString(3, userAgent);
            pstmt.setString(4, deviceInfo != null ? deviceInfo.browser : "Inconnu");
            pstmt.setString(5, deviceInfo != null ? deviceInfo.os : "Inconnu");
            pstmt.setString(6, deviceInfo != null ? deviceInfo.device : "Inconnu");
            pstmt.setString(7, location);
            pstmt.setString(8, status);
            pstmt.executeUpdate();
            
            pstmt.close();
            conn.close();
            
            System.out.println("📝 Connexion enregistrée dans l'historique");
            
        } catch (Exception e) {
            System.err.println("⚠️ Erreur lors de l'enregistrement de la connexion: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/login.jsp").forward(request, response);
    }
}