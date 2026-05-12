package com.quickchat.servlet;

import com.quickchat.dao.UserDAO;
import com.quickchat.model.User;
import org.json.JSONObject;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.text.SimpleDateFormat;

@WebServlet("/getUserProfile")
public class GetUserProfileServlet extends HttpServlet {
    
    private static final long serialVersionUID = 1L;
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        HttpSession session = request.getSession();
        User currentUser = (User) session.getAttribute("user");
        
        JSONObject jsonResponse = new JSONObject();
        
        if (currentUser == null) {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Non authentifié");
            PrintWriter out = response.getWriter();
            out.print(jsonResponse.toString());
            out.flush();
            return;
        }
        
        String userIdParam = request.getParameter("userId");
        if (userIdParam == null || userIdParam.isEmpty()) {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "ID utilisateur manquant");
            PrintWriter out = response.getWriter();
            out.print(jsonResponse.toString());
            out.flush();
            return;
        }
        
        try {
            int userId = Integer.parseInt(userIdParam);
            UserDAO userDAO = new UserDAO();
            User profileUser = userDAO.getUserById(userId);
            
            if (profileUser == null) {
                jsonResponse.put("success", false);
                jsonResponse.put("message", "Utilisateur non trouvé");
            } else {
                jsonResponse.put("success", true);
                jsonResponse.put("username", profileUser.getUsername());
                jsonResponse.put("displayName", profileUser.getDisplayName());
                jsonResponse.put("profilePic", profileUser.getProfilePic() != null ? profileUser.getProfilePic() : "");
                jsonResponse.put("initial", profileUser.getInitial());
                
                // Récupérer la date brute
                String createdAt = profileUser.getCreatedAt();
                jsonResponse.put("createdAtRaw", createdAt);  // ← ENVOIE LA DATE BRUTE
                
                // Formater la date
                String memberSince = "Date inconnue";
                if (createdAt != null && !createdAt.isEmpty()) {
                    try {
                        SimpleDateFormat inputFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
                        SimpleDateFormat outputFormat = new SimpleDateFormat("dd MMMM yyyy");
                        java.util.Date date = inputFormat.parse(createdAt);
                        memberSince = outputFormat.format(date);
                    } catch (Exception e) {
                        memberSince = createdAt;
                    }
                }
                
                jsonResponse.put("memberSince", memberSince);
            }
            
        } catch (NumberFormatException e) {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "ID utilisateur invalide");
        }
        
        PrintWriter out = response.getWriter();
        out.print(jsonResponse.toString());
        out.flush();
    }
}