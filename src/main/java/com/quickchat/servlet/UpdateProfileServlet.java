package com.quickchat.servlet;

import java.io.File;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

@WebServlet("/immo/admin/update-profile")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2,
    maxFileSize = 1024 * 1024 * 10,
    maxRequestSize = 1024 * 1024 * 50
)
public class UpdateProfileServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        Integer adminId = (Integer) session.getAttribute("adminId");
        
        // Force l'ID 9 (ton admin)
        if (adminId == null || adminId == 1) {
            adminId = 9;
            session.setAttribute("adminId", 9);
        }
        
        String fullName = request.getParameter("fullName");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        String address = request.getParameter("address");
        
        String profilePic = null;
        
        // Traitement de l'upload de la photo
        try {
            Part filePart = request.getPart("avatar");
            if (filePart != null && filePart.getSize() > 0) {
                String fileName = System.currentTimeMillis() + "_" + filePart.getSubmittedFileName();
                String uploadPath = getServletContext().getRealPath("/avatars");
                
                // Créer le dossier s'il n'existe pas
                File uploadDir = new File(uploadPath);
                if (!uploadDir.exists()) {
                    uploadDir.mkdirs();
                }
                
                String filePath = uploadPath + File.separator + fileName;
                filePart.write(filePath);
                profilePic = fileName;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/quickchat", "root", "");
            
            String sql;
            PreparedStatement pstmt;
            
            if (profilePic != null) {
                // Mise à jour avec photo
                sql = "UPDATE users SET full_name = ?, email = ?, phone = ?, address = ?, profile_pic = ? WHERE id = ?";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, fullName);
                pstmt.setString(2, email);
                pstmt.setString(3, phone);
                pstmt.setString(4, address);
                pstmt.setString(5, profilePic);
                pstmt.setInt(6, adminId);
            } else {
                // Mise à jour sans photo
                sql = "UPDATE users SET full_name = ?, email = ?, phone = ?, address = ? WHERE id = ?";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, fullName);
                pstmt.setString(2, email);
                pstmt.setString(3, phone);
                pstmt.setString(4, address);
                pstmt.setInt(5, adminId);
            }
            
            pstmt.executeUpdate();
            pstmt.close();
            conn.close();
            
            session.setAttribute("adminUsername", fullName);
            response.sendRedirect(request.getContextPath() + "/immo/admin/setting.jsp?success=Profil mis à jour");
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/immo/admin/setting.jsp?error=" + e.getMessage());
        }
    }
}