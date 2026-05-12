package com.quickchat.servlet;

import com.quickchat.dao.GroupDAO;
import com.quickchat.dao.GroupMemberDAO;
import com.quickchat.model.Group;
import com.quickchat.model.User;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import com.quickchat.utils.DatabaseConnection;

@WebServlet("/leaveGroup")
public class LeaveGroupServlet extends HttpServlet {
    
    private static final long serialVersionUID = 1L;
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        
        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        int groupId = Integer.parseInt(request.getParameter("groupId"));
        
        GroupDAO groupDAO = new GroupDAO();
        Group group = groupDAO.getGroupById(groupId);
        
        GroupMemberDAO memberDAO = new GroupMemberDAO();
        
        // Vérifier si l'utilisateur qui quitte est le créateur
        if (group != null && group.getCreatedBy() == user.getId()) {
            // Le créateur quitte le groupe - transférer la propriété à un autre membre
            
            // 1. Trouver le membre le plus ancien (hors le créateur)
            int newCreatorId = -1;
            String sql = "SELECT user_id FROM group_members WHERE group_id = ? AND user_id != ? ORDER BY joined_at ASC LIMIT 1";
            
            try (Connection conn = DatabaseConnection.getConnection();
                 PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setInt(1, groupId);
                stmt.setInt(2, user.getId());
                ResultSet rs = stmt.executeQuery();
                if (rs.next()) {
                    newCreatorId = rs.getInt("user_id");
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
            
            if (newCreatorId != -1) {
                // 2. Transférer la propriété au nouveau créateur
                groupDAO.transferOwnership(groupId, newCreatorId);
                
                // 3. Supprimer l'ancien créateur du groupe
                memberDAO.removeMember(groupId, user.getId());
                
                // 4. Message de confirmation (optionnel)
                session.setAttribute("successMessage", "Vous avez quitté le groupe. La propriété a été transférée à un autre membre.");
            } else {
                // Aucun autre membre -> supprimer le groupe
                groupDAO.deleteGroup(groupId);
                session.setAttribute("successMessage", "Le groupe a été supprimé car vous étiez le seul membre.");
            }
        } else {
            // Membre normal qui quitte
            memberDAO.removeMember(groupId, user.getId());
            session.setAttribute("successMessage", "Vous avez quitté le groupe.");
        }
        
        response.sendRedirect("chat.jsp");
    }
}