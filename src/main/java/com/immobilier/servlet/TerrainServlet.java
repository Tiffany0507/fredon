package com.immobilier.servlet;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.immobilier.dao.TerrainDAO;
import com.immobilier.model.Terrain;

@WebServlet("/admin/terrains")
public class TerrainServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("adminId") == null) {
            response.sendRedirect(request.getContextPath() + "/immo/admin/login.jsp");
            return;
        }
        
        int adminId = (int) session.getAttribute("adminId");
        String action = request.getParameter("action");
        
        if ("create".equals(action)) {
            try {
                String titre = request.getParameter("titre");
                String description = request.getParameter("description");
                double superficie = Double.parseDouble(request.getParameter("superficie"));
                double prix = Double.parseDouble(request.getParameter("prix"));
                String localisation = request.getParameter("localisation");
                String statut = request.getParameter("statut");
                
                Terrain terrain = new Terrain(titre, description, superficie, 
                                              prix, localisation, adminId);
                terrain.setStatut(statut);
                
                TerrainDAO terrainDAO = new TerrainDAO();
                int terrainId = terrainDAO.createTerrain(
                    terrain.getTitre(),
                    terrain.getDescription(),
                    terrain.getSuperficie(),
                    terrain.getPrix(),
                    terrain.getLocalisation(),
                    terrain.getStatut(),
                    terrain.getAdminId()
                );
                
                if (terrainId > 0) {
                    response.sendRedirect(request.getContextPath() + 
                        "/immo/admin/dashboard.jsp?success=terrain_added");
                } else {
                    response.sendRedirect(request.getContextPath() + 
                        "/immo/admin/dashboard.jsp?error=add_failed");
                }
                        
            } catch (Exception e) {
                e.printStackTrace();
                response.sendRedirect(request.getContextPath() + 
                    "/immo/admin/dashboard.jsp?error=database_error");
            }
        }
    }
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        
        if ("delete".equals(action)) {
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                TerrainDAO terrainDAO = new TerrainDAO();
                
                if (terrainDAO.deleteTerrain(id)) {
                    response.sendRedirect(request.getContextPath() + 
                        "/immo/admin/dashboard.jsp?success=terrain_deleted");
                } else {
                    response.sendRedirect(request.getContextPath() + 
                        "/immo/admin/dashboard.jsp?error=delete_failed");
                }
            } catch (Exception e) {
                e.printStackTrace();
                response.sendRedirect(request.getContextPath() + 
                    "/immo/admin/dashboard.jsp?error=database_error");
            }
        }
    }
}