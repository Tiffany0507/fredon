package com.immobilier.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/historique-agence")
public class HistoriqueAgenceServlet extends HttpServlet {

    private static final String DB_URL  = "jdbc:mysql://localhost:3306/quickchat";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

            // ---- Infos agence ----
            String nom = "", description = "", siege = "", telephone = "", email = "", site_web = "";
            int annee_creation = 0;

            PreparedStatement ps = conn.prepareStatement(
                "SELECT nom, description, annee_creation, siege, telephone, email, site_web FROM agence LIMIT 1");
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                nom            = rs.getString("nom")            != null ? rs.getString("nom")            : "";
                description    = rs.getString("description")    != null ? rs.getString("description")    : "";
                annee_creation = rs.getInt("annee_creation");
                siege          = rs.getString("siege")          != null ? rs.getString("siege")          : "";
                telephone      = rs.getString("telephone")      != null ? rs.getString("telephone")      : "";
                email          = rs.getString("email")          != null ? rs.getString("email")          : "";
                site_web       = rs.getString("site_web")       != null ? rs.getString("site_web")       : "";
            }
            rs.close(); ps.close();

            // ---- Timeline ----
            StringBuilder timeline = new StringBuilder("[");
            PreparedStatement pt = conn.prepareStatement(
                "SELECT annee, titre, description FROM agence_timeline ORDER BY ordre ASC");
            ResultSet rt = pt.executeQuery();
            boolean firstT = true;
            while (rt.next()) {
                if (!firstT) timeline.append(",");
                timeline.append("{")
                    .append("\"annee\":").append(rt.getInt("annee")).append(",")
                    .append("\"titre\":\"").append(escape(rt.getString("titre"))).append("\",")
                    .append("\"description\":\"").append(escape(rt.getString("description"))).append("\"")
                    .append("}");
                firstT = false;
            }
            timeline.append("]");
            rt.close(); pt.close();

            // ---- Services ----
            StringBuilder services = new StringBuilder("[");
            PreparedStatement pv = conn.prepareStatement(
                "SELECT nom_service FROM agence_services ORDER BY ordre ASC");
            ResultSet rv = pv.executeQuery();
            boolean firstS = true;
            while (rv.next()) {
                if (!firstS) services.append(",");
                services.append("\"").append(escape(rv.getString("nom_service"))).append("\"");
                firstS = false;
            }
            services.append("]");
            rv.close(); pv.close();
            conn.close();

            // ---- JSON final ----
            String json = "{"
                + "\"nom\":\""            + escape(nom)                    + "\","
                + "\"description\":\""    + escape(description)            + "\","
                + "\"annee_creation\":"   + annee_creation                  + ","
                + "\"siege\":\""          + escape(siege)                  + "\","
                + "\"telephone\":\""      + escape(telephone)              + "\","
                + "\"email\":\""          + escape(email)                  + "\","
                + "\"site_web\":\""       + escape(site_web)               + "\","
                + "\"timeline\":"         + timeline.toString()             + ","
                + "\"services\":"         + services.toString()
                + "}";

            out.print(json);

        } catch (Exception e) {
            out.print("{\"error\":\"" + escape(e.getMessage()) + "\"}");
            e.printStackTrace();
        }
    }

    private String escape(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}