package com.quickchat.servlet;

import com.quickchat.model.User;
import com.quickchat.model.Group;
import com.quickchat.dao.ConversationDAO;
import com.quickchat.dao.ContactNameDAO;
import com.quickchat.dao.UserDAO;
import com.quickchat.dao.GroupDAO;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import java.util.ArrayList;

@WebServlet("/getArchivedConversations")
public class GetArchivedConversationsServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        
        if (user == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("[]");
            return;
        }
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        try {
            ConversationDAO convDAO = new ConversationDAO();
            UserDAO userDAO = new UserDAO();
            ContactNameDAO contactNameDAO = new ContactNameDAO();
            GroupDAO groupDAO = new GroupDAO();
            
            // Récupérer les conversations privées archivées
            List<User> allUsers = userDAO.getAllUsersExcept(user.getId());
            List<Object> archivedItems = new ArrayList<>();
            
            for (User u : allUsers) {
                if (convDAO.isArchived(user.getId(), u.getId())) {
                    archivedItems.add(u);
                }
            }
            
            // Récupérer les groupes archivés
            List<Group> userGroups = groupDAO.getUserGroups(user.getId());
            for (Group g : userGroups) {
                if (convDAO.isGroupArchived(user.getId(), g.getId())) {
                    archivedItems.add(g);
                }
            }
            
            // Construire le JSON
            StringBuilder json = new StringBuilder();
            json.append("[");
            
            int index = 0;
            for (Object item : archivedItems) {
                if (item instanceof User) {
                    User u = (User) item;
                    String displayName = u.getDisplayName();
                    String customName = contactNameDAO.getCustomName(user.getId(), u.getId());
                    if (customName != null && !customName.isEmpty()) {
                        displayName = customName;
                    }
                    
                    json.append("{");
                    json.append("\"type\":\"user\",");
                    json.append("\"id\":").append(u.getId()).append(",");
                    json.append("\"name\":\"").append(escapeJson(displayName)).append("\",");
                    json.append("\"link\":\"chat.jsp?userId=").append(u.getId()).append("\"");
                    json.append("}");
                    
                } else if (item instanceof Group) {
                    Group g = (Group) item;
                    json.append("{");
                    json.append("\"type\":\"group\",");
                    json.append("\"id\":").append(g.getId()).append(",");
                    json.append("\"name\":\"").append(escapeJson(g.getName())).append("\",");
                    json.append("\"link\":\"group-chat.jsp?groupId=").append(g.getId()).append("\"");
                    json.append("}");
                }
                
                index++;
                if (index < archivedItems.size()) {
                    json.append(",");
                }
            }
            
            json.append("]");
            
            PrintWriter out = response.getWriter();
            out.print(json.toString());
            out.flush();
            
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write("[]");
        }
    }
    
    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}