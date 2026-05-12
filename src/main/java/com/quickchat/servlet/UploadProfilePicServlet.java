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
import com.quickchat.dao.UserDAO;
import com.quickchat.model.User;

@WebServlet("/uploadProfilePic")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,
    maxFileSize = 1024 * 1024 * 5,
    maxRequestSize = 1024 * 1024 * 10
)
public class UploadProfilePicServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private UserDAO userDAO;
    
    public void init() {
        userDAO = new UserDAO();
    }
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        
        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        Part filePart = request.getPart("profilePic");
        
        if (filePart == null || filePart.getSize() == 0) {
            response.sendRedirect("chat.jsp?error=Aucune photo sélectionnée");
            return;
        }
        
        // Générer un nom de fichier unique
        String fileName = System.currentTimeMillis() + "_" + user.getId() + ".jpg";
        
        // Chemin absolu pour sauvegarder
        String uploadPath = getServletContext().getRealPath("") + File.separator + "uploads";
        
        // Créer le dossier s'il n'existe pas
        File uploadDir = new File(uploadPath);
        if (!uploadDir.exists()) {
            uploadDir.mkdir();
        }
        
        // Sauvegarder le fichier
        String filePath = uploadPath + File.separator + fileName;
        filePart.write(filePath);
        
        // Mettre à jour la base de données
        boolean updated = userDAO.updateProfilePic(user.getId(), fileName);
        
        if (updated) {
            // 🔥 IMPORTANT : Recharger l'utilisateur depuis la base
            User updatedUser = userDAO.getUserById(user.getId());
            session.setAttribute("user", updatedUser);
            
            response.sendRedirect("chat.jsp?success=Photo de profil mise à jour");
        } else {
            response.sendRedirect("chat.jsp?error=Erreur lors de la mise à jour");
        }
    }
}