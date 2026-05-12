package com.quickchat.servlet;

import java.io.File;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;
import com.quickchat.dao.MessageDAO;
import com.quickchat.model.User;

@WebServlet("/uploadFile")
@MultipartConfig(maxFileSize = 20 * 1024 * 1024) // 20 Mo max
public class UploadFileServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        try {
            User user = (User) request.getSession().getAttribute("user");
            if (user == null) {
                response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
                return;
            }
            
            int receiverId = Integer.parseInt(request.getParameter("receiverId"));
            Part filePart = request.getPart("file");
            
            if (filePart == null || filePart.getSize() == 0) {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Aucun fichier");
                return;
            }
            
            String fileName = System.currentTimeMillis() + "_" + filePart.getSubmittedFileName();
            String uploadPath = getServletContext().getRealPath("/uploads");
            File uploadDir = new File(uploadPath);
            if (!uploadDir.exists()) uploadDir.mkdirs();
            
            String filePath = "uploads/" + fileName;
            filePart.write(uploadPath + File.separator + fileName);
            
            MessageDAO messageDAO = new MessageDAO();
            int senderId = (user.getId() == 999) ? 9 : user.getId();
            messageDAO.sendMessage(senderId, receiverId, "[Fichier]", filePath, filePart.getContentType());
            
            response.setStatus(HttpServletResponse.SC_OK);
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, e.getMessage());
        }
    }
}