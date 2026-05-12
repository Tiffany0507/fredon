package com.quickchat.filter;

import java.io.IOException;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class UrlFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {}

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;

        String uri = req.getRequestURI();
        String context = req.getContextPath();
        String path = uri.substring(context.length());
        String method = req.getMethod();

        System.out.println("=== UrlFilter: " + method + " " + path);

        // Ne pas filtrer les ressources statiques
        if (path.matches(".*\\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|ttf|eot)$") ||
            path.contains("/uploads/") || path.contains("/avatars/") ||
            path.contains("/includes/") || path.contains("/WEB-INF/")) {
            chain.doFilter(request, response);
            return;
        }

        // /login : GET → afficher la page, POST → LoginServlet
        if (path.equals("/login")) {
            if ("GET".equalsIgnoreCase(method)) {
                req.getRequestDispatcher("/login.jsp").forward(request, response);
            } else {
                chain.doFilter(request, response);
            }
            return;
        }

        // /register : GET → afficher la page, POST → RegisterServlet
        else if (path.equals("/register")) {
            if ("GET".equalsIgnoreCase(method)) {
                req.getRequestDispatcher("/register.jsp").forward(request, response);
            } else {
                chain.doFilter(request, response);
            }
            return;
        }

        else if (path.equals("/admin/dashboard")) {
            req.getRequestDispatcher("/immo/admin/dashboard.jsp").forward(request, response);
            return;
        }
        else if (path.equals("/admin/clients")) {
            req.getRequestDispatcher("/immo/admin/clients.jsp").forward(request, response);
            return;
        }
        else if (path.equals("/admin/appointments")) {
            req.getRequestDispatcher("/immo/admin/appointments.jsp").forward(request, response);
            return;
        }
        else if (path.equals("/admin/add-property")) {
            req.getRequestDispatcher("/immo/admin/add-property.jsp").forward(request, response);
            return;
        }
        else if (path.equals("/admin/edit-property")) {
            String query = req.getQueryString();
            String url = "/immo/admin/edit-property.jsp" + (query != null ? "?" + query : "");
            req.getRequestDispatcher(url).forward(request, response);
            return;
        }
        else if (path.equals("/admin/statistics")) {
            req.getRequestDispatcher("/immo/admin/statistics.jsp").forward(request, response);
            return;
        }
        else if (path.equals("/admin/setting")) {
            req.getRequestDispatcher("/immo/admin/setting.jsp").forward(request, response);
            return;
        }
        else if (path.equals("/admin/notifications")) {
            req.getRequestDispatcher("/immo/admin/notifications.jsp").forward(request, response);
            return;
        }
        else if (path.equals("/chat")) {
            req.getRequestDispatcher("/chat.jsp").forward(request, response);
            return;
        }
        else if (path.equals("/notifications")) {
            req.getRequestDispatcher("/notifications.jsp").forward(request, response);
            return;
        }
        else if (path.equals("/immo/property-detail")) {
            req.getRequestDispatcher("/immo/property-detail.jsp").forward(request, response);
            return;
        }
        else if (path.equals("/") || path.equals("/home")) {
            String query = req.getQueryString();
            String url = "/immo/index.jsp" + (query != null ? "?" + query : "");
            req.getRequestDispatcher(url).forward(request, response);
            return;
        }

        else if (path.equals("/historique-agence")) {
            chain.doFilter(request, response);
            return;
        }
        else if (path.equals("/update-historique-agence")) {
            chain.doFilter(request, response);
            return;
        }
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {}
}