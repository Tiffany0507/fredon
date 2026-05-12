package com.immobilier.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/update-historique-agence")
public class UpdateHistoriqueAgenceServlet extends HttpServlet {

    private static final String DB_URL  = "jdbc:mysql://localhost:3306/quickchat";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        String action = request.getParameter("action");

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

            // ---- UPDATE INFOS PRINCIPALES ----
            if ("update_infos".equals(action)) {
                String nom           = request.getParameter("nom");
                String description   = request.getParameter("description");
                String anneeStr      = request.getParameter("annee_creation");
                String siege         = request.getParameter("siege");
                String telephone     = request.getParameter("telephone");
                String email         = request.getParameter("email");
                String site_web      = request.getParameter("site_web");
                int annee = 0;
                try { annee = Integer.parseInt(anneeStr); } catch (Exception e) {}

                PreparedStatement ps = conn.prepareStatement(
                    "UPDATE agence SET nom=?, description=?, annee_creation=?, siege=?, telephone=?, email=?, site_web=? WHERE id=1");
                ps.setString(1, nom);
                ps.setString(2, description);
                ps.setInt(3, annee);
                ps.setString(4, siege);
                ps.setString(5, telephone);
                ps.setString(6, email);
                ps.setString(7, site_web);
                ps.executeUpdate();
                ps.close();
                out.print("{\"success\":true}");
            }

            // ---- ADD TIMELINE ----
            else if ("add_timeline".equals(action)) {
                String anneeStr   = request.getParameter("annee");
                String titre      = request.getParameter("titre");
                String desc       = request.getParameter("description");
                int annee = 0;
                try { annee = Integer.parseInt(anneeStr); } catch (Exception e) {}

                // Calculer le prochain ordre
                PreparedStatement psOrdre = conn.prepareStatement(
                    "SELECT COALESCE(MAX(ordre),0)+1 FROM agence_timeline");
                java.sql.ResultSet rs = psOrdre.executeQuery();
                int ordre = 1;
                if (rs.next()) ordre = rs.getInt(1);
                rs.close(); psOrdre.close();

                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO agence_timeline (annee, titre, description, ordre) VALUES (?,?,?,?)");
                ps.setInt(1, annee);
                ps.setString(2, titre);
                ps.setString(3, desc);
                ps.setInt(4, ordre);
                ps.executeUpdate();
                ps.close();
                out.print("{\"success\":true}");
            }

            // ---- DELETE TIMELINE ----
            else if ("delete_timeline".equals(action)) {
                String anneeStr = request.getParameter("annee");
                String titre    = request.getParameter("titre");
                int annee = 0;
                try { annee = Integer.parseInt(anneeStr); } catch (Exception e) {}

                PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM agence_timeline WHERE annee=? AND titre=?");
                ps.setInt(1, annee);
                ps.setString(2, titre);
                ps.executeUpdate();
                ps.close();
                out.print("{\"success\":true}");
            }

            // ---- ADD SERVICE ----
            else if ("add_service".equals(action)) {
                String nom = request.getParameter("nom_service");

                PreparedStatement psOrdre = conn.prepareStatement(
                    "SELECT COALESCE(MAX(ordre),0)+1 FROM agence_services");
                java.sql.ResultSet rs = psOrdre.executeQuery();
                int ordre = 1;
                if (rs.next()) ordre = rs.getInt(1);
                rs.close(); psOrdre.close();

                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO agence_services (nom_service, ordre) VALUES (?,?)");
                ps.setString(1, nom);
                ps.setInt(2, ordre);
                ps.executeUpdate();
                ps.close();
                out.print("{\"success\":true}");
            }

            // ---- DELETE SERVICE ----
            else if ("delete_service".equals(action)) {
                String nom = request.getParameter("nom_service");

                PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM agence_services WHERE nom_service=?");
                ps.setString(1, nom);
                ps.executeUpdate();
                ps.close();
                out.print("{\"success\":true}");
            }

            else {
                out.print("{\"error\":\"Action inconnue\"}");
            }

            conn.close();

        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"error\":\"" + e.getMessage().replace("\"", "'") + "\"}");
        }
    }
}