package com.quickchat.servlet;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.google.gson.Gson;
import com.quickchat.dao.GroupMemberDAO;
import com.quickchat.dao.UserDAO;
import com.quickchat.model.User;

@WebServlet("/searchUsers")
public class SearchUsersServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private UserDAO userDAO;
    private GroupMemberDAO memberDAO;
    
    public void init() {
        userDAO = new UserDAO();
        memberDAO = new GroupMemberDAO();
    }
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User currentUser = (User) session.getAttribute("user");
        
        if (currentUser == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        
        String keyword = request.getParameter("keyword");
        int groupId = Integer.parseInt(request.getParameter("groupId"));
        
        // Récupérer tous les utilisateurs
        List<User> allUsers = userDAO.getAllUsersExcept(currentUser.getId());
        
        // Filtrer ceux qui ne sont pas déjà dans le groupe
        List<Map<String, Object>> results = new ArrayList<>();
        for (User u : allUsers) {
            if (!memberDAO.isMember(groupId, u.getId())) {
                Map<String, Object> userMap = new HashMap<>();
                userMap.put("id", u.getId());
                userMap.put("username", u.getUsername());
                userMap.put("displayName", u.getDisplayName());
                userMap.put("profilePic", u.getProfilePic());
                
                // Filtrer par mot-clé
                if (keyword == null || keyword.trim().isEmpty() || 
                    u.getUsername().toLowerCase().contains(keyword.toLowerCase()) ||
                    (u.getDisplayName() != null && u.getDisplayName().toLowerCase().contains(keyword.toLowerCase()))) {
                    results.add(userMap);
                }
            }
        }
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        Gson gson = new Gson();
        response.getWriter().write(gson.toJson(results));
    }
}