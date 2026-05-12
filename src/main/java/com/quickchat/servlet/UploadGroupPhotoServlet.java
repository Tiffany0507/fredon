package com.quickchat.servlet;

import java.io.File;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import com.quickchat.dao.GroupMessageDAO;
import com.quickchat.model.GroupMessage;
import com.quickchat.model.User;

@WebServlet("/uploadGroupPhoto")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,
    maxFileSize = 1024 * 1024 * 10,
    maxRequestSize = 1024 * 1024 * 50
)
public class UploadGroupPhotoServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private GroupMessageDAO messageDAO;
    
    public void init() {
        messageDAO = new GroupMessageDAO();
    }
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        
        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        int groupId = Integer.parseInt(request.getParameter("groupId"));
        Part filePart = request.getPart("photo");
        String caption = request.getParameter("caption");
        
        if (filePart == null || filePart.getSize() == 0) {
            response.sendRedirect("group-chat.jsp?groupId=" + groupId + "&error=Aucune photo");
            return;
        }
        
        // Vérifier le type de fichier
        String contentType = filePart.getContentType();
        if (!contentType.startsWith("image/")) {
            response.sendRedirect("group-chat.jsp?groupId=" + groupId + "&error=Seules les images sont acceptées");
            return;
        }
        
        // Générer un nom de fichier unique
        String fileName = System.currentTimeMillis() + "_" + user.getId() + ".jpg";
        
        // Chemin de sauvegarde
        String uploadPath = getServletContext().getRealPath("") + File.separator + "uploads";
        File uploadDir = new File(uploadPath);
        if (!uploadDir.exists()) {
            uploadDir.mkdir();
        }
        
        // Sauvegarder le fichier
        String filePath = uploadPath + File.separator + fileName;
        filePart.write(filePath);
        
        // Créer le message
        GroupMessage message = new GroupMessage();
        message.setGroupId(groupId);
        message.setSenderId(user.getId());
        message.setContent(caption != null ? caption : "");
        message.setFilePath("uploads/" + fileName);
        message.setFileType(contentType);
        
        messageDAO.sendGroupMessage(message);
        
        response.sendRedirect("group-chat.jsp?groupId=" + groupId);
    }
}