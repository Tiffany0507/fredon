package com.quickchat.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import org.json.JSONObject;
import com.quickchat.model.User;
import com.quickchat.utils.DatabaseConnection;

@WebServlet("/getGroupMemberInfo")
public class GetGroupMemberInfoServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
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
        
        String groupIdParam = request.getParameter("groupId");
        String userIdParam = request.getParameter("userId");
        
        if (groupIdParam == null || userIdParam == null) {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Paramètres manquants");
            PrintWriter out = response.getWriter();
            out.print(jsonResponse.toString());
            out.flush();
            return;
        }
        
        try {
            int groupId = Integer.parseInt(groupIdParam);
            int userId = Integer.parseInt(userIdParam);
            
            String sql = "SELECT gm.*, u.username as added_by_username, u.display_name as added_by_displayname " +
                         "FROM group_members gm " +
                         "LEFT JOIN users u ON gm.added_by = u.id " +
                         "WHERE gm.group_id = ? AND gm.user_id = ?";
            
            try (Connection conn = DatabaseConnection.getConnection();
                 PreparedStatement stmt = conn.prepareStatement(sql)) {
                
                stmt.setInt(1, groupId);
                stmt.setInt(2, userId);
                ResultSet rs = stmt.executeQuery();
                
                if (rs.next()) {
                    jsonResponse.put("success", true);
                    jsonResponse.put("isCreator", rs.getInt("is_creator") == 1);
                    
                    int addedBy = rs.getInt("added_by");
                    if (addedBy > 0) {
                        String addedByName = rs.getString("added_by_displayname");
                        if (addedByName == null || addedByName.isEmpty()) {
                            addedByName = rs.getString("added_by_username");
                        }
                        jsonResponse.put("addedBy", addedByName);
                    } else {
                        jsonResponse.put("addedBy", "");
                    }
                } else {
                    jsonResponse.put("success", false);
                    jsonResponse.put("message", "Membre non trouvé");
                }
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Erreur: " + e.getMessage());
        }
        
        PrintWriter out = response.getWriter();
        out.print(jsonResponse.toString());
        out.flush();
    }
}