package com.quickchat.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import com.quickchat.model.User;
import com.quickchat.dao.UserDAO;
import com.quickchat.utils.NotificationHelper;

@WebServlet("/register")
public class RegisterServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private UserDAO userDAO;

    public void init() {
        userDAO = new UserDAO();
    }

    // ✅ AJOUT : doGet pour afficher la page /register sans .jsp
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/register.jsp").forward(request, response);
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String username = request.getParameter("username");
        String email    = request.getParameter("email");
        String password = request.getParameter("password");
        String fullName = request.getParameter("fullName");

        User user = new User();
        user.setUsername(username);
        user.setEmail(email);
        user.setPassword(password);
        user.setFullName(fullName);

        if (userDAO.createUser(user)) {
            int userId = user.getId();

            // Notification de bienvenue pour le client
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection conn = DriverManager.getConnection(
                    "jdbc:mysql://localhost:3306/quickchat", "root", "");
                String sql = "INSERT INTO notifications " +
                    "(user_id, user_type, type, title, message, link) " +
                    "VALUES (?, ?, ?, ?, ?, ?)";
                PreparedStatement pstmt = conn.prepareStatement(sql);
                pstmt.setInt(1, userId);
                pstmt.setString(2, "client");
                pstmt.setString(3, "welcome");
                pstmt.setString(4, "🎉 Bienvenue sur Fredon Immobilier !");
                pstmt.setString(5, "Merci " + username +
                    " de vous être inscrit. Explorez nos biens.");
                // ✅ CORRIGÉ : /home au lieu de /immo/index.jsp
                pstmt.setString(6, request.getContextPath() + "/home");
                pstmt.executeUpdate();
                pstmt.close();
                conn.close();
            } catch (Exception e) {
                e.printStackTrace();
            }

            NotificationHelper.notifyNewClient(1, username);

            // ✅ CORRIGÉ : /login?success= au lieu de login.jsp?success=
            response.sendRedirect(request.getContextPath() +
                "/login?success=Inscription réussie ! Connectez-vous.");

        } else {
            // ✅ CORRIGÉ : /register?error= au lieu de register.jsp?error=
            response.sendRedirect(request.getContextPath() +
                "/register?error=Erreur lors de l'inscription");
        }
    }
}